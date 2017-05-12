package PITA::POE::SupportServer;

use 5.006;
use strict;
use Params::Util qw( _ARRAY _HASH0 );

use POE qw(Filter::Line Wheel::Run );
use POE::Component::Server::SimpleContent;
use POE::Component::Server::SimpleHTTP;
use URI;
use MIME::Types qw(by_suffix);
use base 'Process';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.41';
}

sub new {
	my $class = shift;

	# TODO error checking here?

	bless { params => { @_ } }, $class;
}

sub prepare {
	my $self = shift;
	my %opt  =  %{ delete $self->{params} };

	$opt{lc $_} = delete $opt{$_} for keys %opt;

	unless ( _ARRAY($opt{execute}) ) {
		$self->{errstr} = 'execute must be an array ref';
		return undef;
	}
	$self->{execute}               = delete $opt{execute};

	unless ( _HASH0($opt{http_mirrors}) ) {
		$self->{errstr} = 'http_mirrors must be a hash ref of image paths to local paths';
		return;
	}
	$self->{http_mirrors}          = delete $opt{http_mirrors};
	$self->{http_local_addr}       = delete $opt{http_local_addr} || '127.0.0.1';
	$self->{http_local_port}       = delete $opt{http_local_port};
	$self->{http_local_port}       = 80 unless defined $self->{http_local_port};
	$self->{http_result}           = delete $opt{http_result} || [ '/result.xml' ];
	unless ( _ARRAY( $self->{http_result} ) ) {
		$self->{http_result} = [ $self->{http_result} ];
	}
	$self->{http_startup_timeout}  = delete $opt{http_startup_timeout}  || 30;
	$self->{http_activity_timeout} = delete $opt{http_activity_timeout} || 3600;
	$self->{http_shutdown_timeout} = delete $opt{http_shutdown_timeout} || 10;

	if ( keys %opt ) {
		$self->{errstr} = 'unknown parameters: '.join( ',', keys %opt );
		return;
	}

	$self->{_prepared} = 1;
	$self->{_has_run}  = 0;
	$self->{_log}      = [];
	$self->{_stdout}   = [];
	$self->{_stderr}   = [];

	return 1;
}

sub run {
	my $self = shift;

	# TODO setup timers

	unless( $self->{_prepared} ) {
		$self->{errstr} = "You must prepare() before run()";
		return;
	}

	$self->{_has_run}++;

	$self->{_session_id} = POE::Session->create(
		object_states => [
			$self => [qw(
				_start
				_signals
				_sig_child
				_http_success
				_http_result
				execute
				shutdown

				_error
				_closed
				_stdin
				_stderr
				_stdout

				_startup_timeout
				_activity_timeout
				_shutdown_timeout
				)],
			],
		)->ID;

	$poe_kernel->run;

	$self->{errstr} ? undef : 1;
}

sub http_result {
	my $self = shift;
	my $result = shift || return;
	return $self->{_http_result}->{ $result };
}

sub get_log {
	return @{$_[0]->{_log}};
}

sub get_stdout {
	return @{$_[0]->{_stdout}};
}

sub get_stderr {
	return @{$_[0]->{_stderr}};
}

sub has_run {
	$_[0]->{_has_run} || 0;
}

# Private methods and events

sub _start {
	my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];
	$self->{_session_id}     = $session->ID;
	$self->{content_servers} = [ ];

	my $handlers = [ ];

	while ( my ($alias_path,$root_dir) = each %{ $self->{http_mirrors} } ) {
		my $content = POE::Component::Server::SimpleContent->spawn( 
			root_dir   => $root_dir,
			alias_path => $alias_path,
			);
		next unless $content;
		push @{ $self->{content_servers} }, $content;
		push @{ $handlers }, {
			DIR     => "^$alias_path",
			SESSION => $content->session_id,
			EVENT   => 'request',
			};
	}

	foreach my $result ( @{ $self->{http_result} } ) {
		push @{ $handlers }, {
			DIR     => "^$result\$",
			SESSION => $self->{_session_id},
			EVENT   => '_http_result',
			};
	}

	push @{ $handlers }, {
		DIR     => '^/$', 
		SESSION => $self->{_session_id},
		EVENT   => '_http_success',
		};

	$self->{_http_server} = __PACKAGE__ . $$;
	POE::Component::Server::SimpleHTTP->new(
		ALIAS      => $self->{_http_server},
		ADDRESS    => $self->{http_local_addr},
		PORT       => $self->{http_local_port},
		HANDLERS   => $handlers,
		LOGHANDLER => {
			SESSION => $self->{_session_id},
			EVENT   => '_http_activity',
			},
		);

	$kernel->yield('execute');

	return;
}

sub _sig_child {
	my ($kernel,$self,$thing,$pid,$status) = @_[KERNEL,OBJECT,ARG0..ARG2];
	$self->{_wheel_closed}++;
	# warn "$thing $pid $status\n";
	$self->{exitcode} = $status;
	$kernel->alarm_remove_all;
	$kernel->yield('shutdown');
	$kernel->sig_handled;
}

sub _signals {
	my $sig = $_[ ARG0 ];

	if ( $sig eq 'DIE' ) {
		my ( $kernel, $self, $event, $file, $line, $from_state, $error )
    			= @_[ KERNEL, OBJECT, ARG2 .. ARG6 ];

		$self->{errstr} = "POE Exception at line $line in file $file "
    			. " (state '$from_state' called '$event') Error: $error";

		$kernel->sig_handled();

		$kernel->call( $_[ SESSION ] => 'shutdown' );
	}
}

sub _http_success {
	my ($kernel, $self, $sender, $request, $response) = @_[KERNEL, OBJECT, SENDER, ARG0, ARG1];
	push @{$self->{_log}}, $request->method . ' ' . $request->uri->path;
	$kernel->alarm_remove( delete $self->{_http_startup_timer} );
	$response->code( 200 );
	$response->content( 'OK' );
	$response->content_type( 'text/html' );
	$kernel->call( $sender, 'DONE', $response );
	$self->{_http_activity_timer} = $kernel->delay_set( _activity_timeout => $self->{http_activity_timeout} );
	return;
}

sub _http_activity {
	my ($kernel, $self, $request) = @_[KERNEL, OBJECT, ARG0];
	push @{$self->{_log}}, $request->method . ' ' . $request->uri->path;
	return unless $self->{_http_activity_timer};
	$kernel->delay_adjust( $self->{_http_activity_timer}, $self->{http_activity_timeout} );
	return;
}

sub _http_result {
	my ($kernel,$self,$sender,$request,$response) = @_[KERNEL,OBJECT,SENDER,ARG0,ARG1];
	push @{$self->{_log}}, $request->method . ' ' . $request->uri->path;
	my $uri  = URI->new( $request->uri );
	my $path = $uri->path;
	if ( $request->method() eq 'PUT' ) {
		if ( grep { $_ eq $path } @{ $self->{http_result} } ) {
			$self->{_http_result}->{ $path } = $request->content();
			$response->code( 201 );
			$response->content_type( 'text/html' );
			$response->content('OK');
			if ( scalar @{ $self->{http_result} } == scalar keys %{ $self->{_http_result} } ) {
				$kernel->alarm_remove( delete $self->{_http_activity_timer} );
			}
		} else {
			$response->code( 405 );
			$response->content_type( 'text/html' );
			$response->content('NOK');
			$response->header( 'allow', 'GET,HEAD,POST,OPTIONS,TRACE' );
		}

	} else {
		if ( defined $self->{_http_result}->{ $path } ) {
			my ($mediatype, $encoding) = by_suffix( $path );
			$response->code( 200 );
			$response->content_type( $mediatype || 'text/html' );
			$response->content( $self->{_http_result}->{ $path } );
		} else {
			$response = generate_404( $response );
		}
	}
	$kernel->call( $sender, 'DONE', $response );
	return;
}

sub execute {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
	my @args = @{$self->{execute}};
   
	$self->{_http_startup_timer} = $kernel->delay_set( _startup_timeout => $self->{http_startup_timeout} );

	$self->{_wheel} = POE::Wheel::Run->new(
		Program      => shift @args,
		ProgramArgs  => \@args,
		StderrFilter => POE::Filter::Line->new(),
		StdioFilter  => POE::Filter::Line->new(),
		ErrorEvent   => '_error',
		CloseEvent   => '_closed',
		StdinEvent   => '_stdin',
		StdoutEvent  => '_stdout',
		StderrEvent  => '_stderr',
	);

	$kernel->sig_child( $self->{_wheel}->PID(), '_sig_child' );
	return;
}

sub shutdown {
	my ($self,$kernel) = @_[OBJECT,KERNEL];
    
	unless ( $self->{_wheel_closed} ) {
		$self->{_wheel}->kill() if $self->{_wheel};
		$self->{_shutdown_timer} = $kernel->delay_set( _shutdown_timeout => $self->{http_shutdown_timeout} );
		return;
	}
	$kernel->alarm_remove_all(); # Just in case
	$_->shutdown() for @{ $self->{content_servers} };
	$kernel->post( $self->{_http_server}, 'SHUTDOWN' );
	return;
}

sub _error {
	my ( $kernel, $self, $ret, $errno, $error, $wheel_id, $handle ) = @_[ KERNEL, OBJECT, ARG0 .. ARG5 ];
	if ( $errno ) {
		$self->{errstr} = "Error no $errno on $handle : $error ( Return value: $ret )";
	}
	delete $self->{_wheel};
	return;
}

sub _closed {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL];
	delete $self->{_wheel};
	return;
}

sub _stdin {
	warn $_[ARG0];
}

sub _stdout {
	my ($self, $message) = @_[ OBJECT, ARG0];
	push @{$self->{_stdout}}, $message;
	# warn $_[ARG0];
}

sub _stderr {
	my ($self, $message) = @_[ OBJECT, ARG0];
	push @{$self->{_stdout}}, $message;
	# warn $_[ARG0];
}

sub _startup_timeout {
	# warn "startup_timeout";
	$poe_kernel->yield( 'shutdown' );
	return;
}

sub _activity_timeout {
	# warn "activity_timeout";
	$poe_kernel->yield( 'shutdown' );
	return;
}

sub _shutdown_timeout {
	# warn "shutdown_timeout";
	$_[OBJECT]->{_wheel}->kill(9) if $_[OBJECT]->{_wheel};
	return;
}

1;

__END__

=pod

=head1 NAME

PITA::POE::SupportServer - Support server for PITA virtual machines

=head1 SYNOPSIS

  use PITA::POE::SupportServer;

  my $server = PITA::POE::SupportServer->new(
          execute => [
                  '/usr/bin/qemu',
                  '-snapshot',
                  '-hda',
                  '/var/pita/image/ba312bb13f.img',
                  ],
          http_local_addr       => '127.0.0.1',
          http_local_port       => 80,
          http_startup_timeout  => 30,
          http_activity_timeout => 3600,
          http_shutdown_timeout => 10,
          http_result           => '/result.xml',
          http_mirrors          => {
                  '/cpan' => '/var/cache/minicpan',
                  },
          ) or die "Failed to create support server";
  
  $server->prepare
          or die "Failed to prepare support server";
  
  $server->run
          or die "Failed to run support server";
  
  my $result_file = $server->http_result('/result.xml')
          or die "Guest Image execution failed";

=head1 DESCRIPTION

TO BE COMPLETED

=head1 SUPPORT 
Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-POE-SupportServer>

For other issues, contact the author.

=head1 AUTHORS

David Davis E<lt>xantus@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Chris Williams E<lt>bingos@cpan.orgE<gt>

=head1 SEE ALSO

L<PITA>, L<POE>, L<Process>, L<http://ali.as/>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 - 2008 David Davis.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
