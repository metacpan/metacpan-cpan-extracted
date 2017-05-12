package POE::Component::Server::SimpleXMLRPC;

use strict;

use vars qw($VERSION);

$VERSION = '0.02';

use POE qw(Component::Server::SimpleHTTP Wheel::Run);
use Frontier::RPC2;
use Encode;
use POSIX;

sub new {
  # Get the OOP's type
  my $type = shift;
  # Sanity checking
  if ( @_ & 1 ) {
    die( 'POE::Component::Server::SimpleXMLRPC->new needs even number of options' );
  }
  # The options hash
  my %opt = @_;
  my ($sesName, $rpcMap, $alias, $func_timeout, $logger);
  if ( exists $opt{'ALIAS'} and defined $opt{'ALIAS'} and length( $opt{'ALIAS'} ) ) {
    $alias = $opt{'ALIAS'};
  } else {
  	# set default
    $alias = 'HTTPD';
    $opt{'ALIAS'} = 'HTTPD';
  }
  if ( exists $opt{'RECV_SESSION'} and defined $opt{'RECV_SESSION'} and length( $opt{'RECV_SESSION'} ) ) {
    $sesName = $opt{'RECV_SESSION'};
    delete $opt{'RECV_SESSION'};
  } else {
  	# set default
    $sesName = 'HTTP_GET';
  }
  if ( exists $opt{'FUNC_TIMEOUT'} and defined $opt{'FUNC_TIMEOUT'} and length( $opt{'FUNC_TIMEOUT'} ) ) {
    $func_timeout = $opt{'FUNC_TIMEOUT'};
    delete $opt{'FUNC_TIMEOUT'};
  } else {
        # set default
        $func_timeout = 120;
  }
  if ( exists $opt{'RPC_MAP'} and defined $opt{'RPC_MAP'} and length( $opt{'RPC_MAP'} ) ) {
    $rpcMap = $opt{'RPC_MAP'};
    delete $opt{'RPC_MAP'};
  } else {
  	die( 'RPC_MAP is required to create a new POE::Component::Server::SimpleXMLRPC instance!' );
  }
  if (exists $opt{'LOGGER'} and defined $opt{'LOGGER'} and ref $opt{'LOGGER'} eq 'HASH') {
	if (defined $opt{LOGGER}->{SESSION} and defined $opt{LOGGER}->{EVENT}) {
		$logger = delete $opt{LOGGER};
	}
	else {
		die ('Malformed LOGGER option');
	}
  }		
  # Adding and checking our options:
  # Replace HANDLERS
  $opt{HANDLERS} = [ {DIR => '^.*$',
            SESSION => $sesName,
            EVENT => 'GOT_default'}];

   # Start server
   POE::Component::Server::SimpleHTTP->new(%opt) or die 'Unable to create the HTTP Server';

   my $states;
   $states->{GOT_default} = \&GOT_default;
   $states->{_start} = sub {   $poe_kernel->alias_set( $sesName ); $poe_kernel->sig(CHLD => "sigchild");};
   $states->{SHUTDOWN} = sub {
        my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
	foreach my $wheel ( keys %{ $heap->{ wheels } } ) {
	    $kernel->call( $_[SESSION], 'wheel_check_' . $wheel );
	    $kernel->alarm_remove( $heap->{wheels}->{ $wheel }->{timer} );
	}
	delete $heap->{ 'wheels' };
	$kernel->alias_remove( $sesName );
	$kernel->call( $heap->{HTTPD}, 'SHUTDOWN' );
	$kernel->yield( '_stop' );
   };
	 $states->{remap} = sub { $_[HEAP]->{METHODS} = $_[ARG0]; };
	$states->{sigchild} = sub {
		#if ($_[HEAP]->{LOGGER}) {
		#	$_[KERNEL]->post($_[HEAP]->{LOGGER}->{SESSION}, $_[HEAP]->{LOGGER}->{EVENT}, 'Sigchild got with data: '.Dumper($_[ARG2]));
		#}
		return $poe_kernel->sig_handled(); # 1;
	};
	$states->{wheel_done} = sub {
		my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];
		my $content = eval ('my $VAR1; '.$heap->{wheels}->{$wheel_id}->{content});
		#$content = $content || 'void content';
                $content = $heap->{coder}->encode_response($content);
                $heap->{wheels}->{$wheel_id}->{response}->code(200);
                if (Encode::is_utf8($content)) {
                        $content = encode('utf8', $content);
                }
		if ($_[HEAP]->{LOGGER}) {						
			$kernel->call($heap->{LOGGER}->{SESSION}, $heap->{LOGGER}->{EVENT}, Dumper($content));
		}
                $heap->{wheels}->{$wheel_id}->{response}->content( $content );
                $kernel->post( $heap->{HTTPD}, 'DONE', $heap->{wheels}->{$wheel_id}->{response} );
		$kernel->alarm_remove( $heap->{wheels}->{$wheel_id}->{timer} );
		delete $heap->{wheels}->{$wheel_id};
	};
	$states->{wheel_out} = sub {
		my ($kernel, $heap, $content, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];
		$heap->{wheels}->{$wheel_id}->{content} .= $content; 
	};
	$states->{wheel_err} = sub {
		my ($kernel, $heap, $content, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];
                #$heap->{wheels}->{$wheel_id}->{content} .= $content;
                if ($heap->{LOGGER}) {
                	$kernel->post($heap->{LOGGER}->{SESSION}, $heap->{LOGGER}->{EVENT}, 'stderr from function '.
				$heap->{wheels}->{$wheel_id}->{procedure}.': '.$content);
		}
	};
	$states->{_default} = sub {
		my ($kernel, $heap, $event, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];
		unless ($event =~ /^wheel_check_(\d+)$/) { 
			if ($heap->{LOGGER}) {
	                        $kernel->post($heap->{LOGGER}->{SESSION}, $heap->{LOGGER}->{EVENT},'unhandled event '.$event);
			}
			return $poe_kernel->sig_handled();
		 }
		$wheel_id = $1;
		if (exists $heap->{wheels}->{$wheel_id}) {
			$heap->{wheels}->{$wheel_id}->{wheel}->kill(9);
			my $content = $heap->{coder}->encode_fault('500', "Request timed out");
			$heap->{wheels}->{$wheel_id}->{response}->code( 200 );
			if (!Encode::is_utf8($content)) {
				$content = decode('utf8', $content);
			}
			$heap->{wheels}->{$wheel_id}->{response}->content( $content );
			$_[KERNEL]->post( $heap->{HTTPD}, 'DONE', $heap->{wheels}->{$wheel_id}->{response} );
			delete $heap->{wheels}->{$wheel_id};
		}
		return $poe_kernel->sig_handled();
	};
   # Start worker session
   POE::Session->create(
                inline_states => $states,
                heap => {
                	METHODS => $rpcMap,
			FUNC_TIMEOUT => $func_timeout,
			coder => new Frontier::RPC2('encoding' => 'UTF-8'),
			wheels => {},
			LOGGER => $logger,
			HTTPD => $alias,
                },
        );
}

sub GOT_default {
	my( $kernel, $heap, $request, $response, $dirmatch ) = @_[ KERNEL, HEAP, ARG0 .. ARG2 ];
        my $params = _getParamsFromRequest($request, $heap->{coder});
        my ($code, $content);
        $code = 200;
        if (ref $params->{__postdata} eq 'HASH' && $params->{__postdata}->{method_name}) {
                # Try to find appropriate function to handle method
                my $found = 0;
                foreach my $handler ( keys %{ $_[HEAP]->{'METHODS'} } ) {
                        if ( $params->{__postdata}->{method_name} eq $handler ) {
                                $found = 1;
                                my $func = $_[HEAP]->{'METHODS'}->{$handler};
				# fork wheel::run
				my $wheel = POE::Wheel::Run->new(
					Program => sub { use Data::Dumper;
							$Data::Dumper::Purity = 1;
				                        $Data::Dumper::Terse = 1;
							print Dumper(&$func($params->{__postdata}->{value}))."\n"; return 1;},
					StdoutEvent => 'wheel_out',
					StderrEvent => 'wheel_err',
					CloseEvent => 'wheel_done',
					CloseOnCall => 1,
					StderrFilter => POE::Filter::Stream->new(),
				);
				$heap->{wheels}->{$wheel->ID}->{wheel} = $wheel;
				$heap->{wheels}->{$wheel->ID}->{response} = $response;
				$heap->{wheels}->{$wheel->ID}->{content} = '';	
				$heap->{wheels}->{$wheel->ID}->{procedure} = $handler;			
				# set timeout
				$heap->{wheels}->{$wheel->ID}->{timer} = 
				    $kernel->delay_set('wheel_check_'.$wheel->ID => $heap->{FUNC_TIMEOUT}, $wheel->ID);
				# and return
				return 1;
			 }
                }
                if ($found == 0) {
                        $content = $heap->{coder}->encode_fault('404', 'No such method');

                }
        }
        else {
                $code = 500;
                $content = 'Malformed request: no method found';
        }
    $response->code( $code );
    if (!Encode::is_utf8($content)) {
        $content = decode('utf8', $content);
    }
    $response->content( $content );
    $_[KERNEL]->post( $heap->{HTTPD}, 'DONE', $response );

}

sub _getParamsFromRequest {
  my ($req, $coder) = @_;
  my ($params);
  $params->{__postdata} = $req->decoded_content(charset => 'UTF-8');
  $params->{__postdata} ||= decode('utf8', $req->content());
	if ($params->{__postdata} =~ /^<\?xml/) {
	  $params->{__postdata} = $coder->decode($params->{__postdata});
	}
  return $params;
}

1;

__END__

=pod

=head1 NAME

POE::Component::Server::SimpleXMLRPC

=head1 DESCRIPTION

XML-RPC server based on SimpleHTTP and Frontier::RPC2.

Dispatches incoming requests to CODEREF handlers, using B<RPC_MAP>.

Each request is processed in separate Wheel::Run process, so it

is fork-on-demand model.

=head1 SYNOPSIS

 use POE qw(Component::Server::SimpleXMLRPC Component::Logger);
 
 POE::Component::Logger->spawn( ConfigFile => 'external_config_file' );
 
 POE::Component::Server::SimpleXMLRPC->new(
    PORT => 5555,
    ADDRESS => '127.0.0.1',
    RPC_MAP => { test => sub { return { res => 'test ok:' } },
    ALIAS => 'HTTPD',
    RECV_SESSION => 'HTTP_GET',
    LOGGER => { SESSION => 'logger', EVENT => 'log' }
 );
 
 $poe_kernel->run();

Look at the example folder for simple example of client and server scripts.

=head1 METHODS

=over

=item new

Takes usual options hash, as Po::Co::Server::SimpleHTTP does,

but with few additions.

=over

=item ALIAS

B<Optional.> Server session alias. Defaulted to 'HTTPD'.

=item RECV_SESSION

B<Optional.> Controller session alias. Defaulted to 'HTTP_GET'.

=item FUNC_TIMEOUT

B<Optional.> Max time for request processing, in seconds. Defaulted to 120.

=item RPC_MAP

B<Required.> HashRef of procedures names and their CodeRefs.

=item LOGGER

B<Optional.> HashRef with B<SESSION> and B<EVENT> names of logger session.

No default logger will be created.

=back

All other options are passed to SimpleHTTP constructor.

=item _getParamsFromRequest

B<Internal> Simple parser of incoming xml.

=back

=head1 EVENTS

Server session is a SimpleHTTP server, so refer to it's documentation.

Controller session events:

=over

=item GOT_default

B<Internal> Main controller session. Parses request, starts wheel::run,

tries to handle errors.

=item remap

B<Public> Changes RPC_MAP. The only argument must be the same as B<RPC_MAP> -

HashRef of procedures and their CodeRef.

=back 

=head1 BUGS

Should be. Use rt to report.

Tests do not cover all abilities and possible points of failures.

It tests only basic functionality.

=head1 AUTHOR

Denis Pokataev aka Catone. 2008.

=head1 COPYRIGHTS

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

