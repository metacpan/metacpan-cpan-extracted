package POEIKC::Daemon;

use strict;

use 5.008_001;

use warnings;
use Data::Dumper;
use Sys::Hostname ();
use Class::Inspector;
use UNIVERSAL::require;
use Proc::Killall;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Server
	Component::IKC::Client
);

use base qw/Class::Accessor::Fast/;

use POEIKC;
our $VERSION = $POEIKC::VERSION;
use POEIKC::Daemon::Utility;

our @inc = @INC;
our %inc = %INC;
our $DEBUG;
our %opt;
our %connected;

__PACKAGE__->mk_accessors(qw/pidu argv alias ikc_self_port ikc_self_name server_port server_name/);



####

sub ikc_server_param {
	my $self = shift;
	$self->{ikc_server_param}->{$_[0]} = $_[1] if (@_ and $_[1]);
	return %{$self->{ikc_server_param}};
}

sub init {
	my $class = shift || __PACKAGE__ ;
	my $self = $class->new;
	$DEBUG = $opt{debug};
	$self->argv($opt{argv}) if $opt{argv};
	$self->alias($opt{alias} || 'POEIKCd');

	if ( exists $opt{"0PROGRAM_NAME"} ) {
		my $pn = $opt{"0PROGRAM_NAME"} || $opt{"name"} || 'poeikcd' ;
		$0 = sprintf "%s --alias=%s --port=%s",
				$pn, $self->alias, $opt{port} ;
	}else{
		if ($opt{"name"}){
			$0 = sprintf "poeikcd --name=%s --alias=%s --port=%s",
				$opt{"name"}, $self->alias, $opt{port} ;
		}else{
			$0 = sprintf "poeikcd --alias=%s --port=%s",
				$self->alias, $opt{port} ;
		}
	}


	$opt{name} ||= join('_'=>__PACKAGE__ =~ m/(\w+)/g);
	$self->server_name($opt{name});

	$opt{port} ||= $ARGV[0] || 47225 ;
	$self->server_port($opt{port});

	$self->ikc_server_param(name		=>$opt{name});
	$self->ikc_server_param(port		=>$opt{port});
	$self->ikc_server_param(verbose		=>$opt{Verbose});
	$self->ikc_server_param(processes	=>$opt{Processes});
	$self->ikc_server_param(babysit		=>$opt{babysit});
	$self->ikc_server_param(connections	=>$opt{connections});

	$self->pidu(POEIKC::Daemon::Utility->_new);
	$self->pidu->_init();
	$self->pidu->DEBUG($DEBUG) if $DEBUG;
	$self->pidu->inc->{org_inc}= \%inc;
	#$self->pidu->stay(module=>'POEIKC::Daemon::Utility');

	push @{$opt{Module}}, __PACKAGE__, 'POEIKC::Daemon::Utility';
	$self->pidu->inc->{load}->{ $_ } = [$INC{Class::Inspector->filename($_)},scalar localtime] for @{$opt{Module}};


	if ($DEBUG) {
		no warnings 'redefine';
		*POE::Component::IKC::Responder::DEBUG = sub { 1 };
		*POE::Component::IKC::Responder::Object::DEBUG = sub { 1 };
		POEIKC::Daemon::Utility::_DEBUG_log(VERSION	=>$VERSION);
		POEIKC::Daemon::Utility::_DEBUG_log(load_module=>$self->pidu->inc->{load});
		POEIKC::Daemon::Utility::_DEBUG_log(GetOptions=>\%opt);
		POEIKC::Daemon::Utility::_DEBUG_log('@INC'	=>\@INC);
		POEIKC::Daemon::Utility::_DEBUG_log({$self->ikc_server_param});
	}
	return $self;
}

sub daemon {
	my $class = shift || __PACKAGE__ ;
	%opt = @_;
	my @startup = @{$opt{Module}} if exists $opt{Module};
	my $self = $class->init(%opt);
	$self->spawn();
	if (@startup and exists $opt{startup}) {
		$self->startup($_, $opt{startup}) for ( @startup );
	}
	$self->poe_run();
}

sub poe_run {
	POE::Kernel->run();
}


sub spawn
{
	my $self = shift;
	my %param = (
		aliases  => [ $self->server_name .'_'. Sys::Hostname::hostname],
		$self->ikc_server_param
	);

	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%param);

	POE::Component::IKC::Server->spawn(%param);

	POE::Session->create(
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ]
	);

#	if ($self->argv){
#		my ( $session_alias, $event, $args ) = @{$self->argv};
#		my ( $session_alias, $event, $args ) = @{$self->argv};
#	}

	return 1;
}

sub startup {
	my $self = shift;
	my $module = shift;
	my $startup = shift || 'spawn';
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log("$module->$startup()");
	$module->$startup();
}

sub _start {
	my $poe     = sweet_args ;
	my $object = $poe->object;

	printf "%s PID:%s ... Started!! (%s)\n", $0, $$, scalar(localtime);

	my $kernel = $poe->kernel;

	$object->{start_time} = localtime;
	$kernel->alias_set($object->alias);

	# 終了処理 を登録
	$kernel->sig( HUP  => 'sig_stop' );
	$kernel->sig( INT  => 'sig_stop' );
	$kernel->sig( TERM => 'sig_stop' );
	$kernel->sig( KILL => 'sig_stop' );

	$kernel->call(
		IKC =>
			#publish => $object->alias, Class::Inspector->methods(__PACKAGE__),
			publish => $object->alias, [qw/
				_stop
				event_respond
				execute_respond
				function_respond
				method_respond
				something_respond
			/],
	);

	if ($DEBUG) {
		$kernel->post(IKC=>'monitor', '*'=>{
			register	=>'debug_monitor_callback_register',
			unregister	=>'debug_monitor_callback_unregister',
			subscribe	=>'debug_monitor_callback_subscribe',
			unsubscribe	=>'debug_monitor_callback_unsubscribe',
			shutdown	=>'debug_monitor_callback_shutdown',
			data		=>'(foo)',
		});
	}else{
		$kernel->post(IKC=>'monitor', '*'=>{
			register	=>'monitor_register',
			unregister	=>'monitor_unregister',
		});
	}
}


sub monitor_register
{
	my $poe = sweet_args ;
	my $object = $poe->object;
	my $client = (@{$poe->args})[1];
	$connected{$client}++;
}

sub monitor_unregister
{
	my $poe = sweet_args ;
	my $object = $poe->object;
	my $client = (@{$poe->args})[1];
	delete $connected{$client} if $connected{$client};
}




sub debug_monitor_callback_register
{
	my $poe = sweet_args ;
	my $object = $poe->object;
	my $client = (@{$poe->args})[1];
	$connected{$client}++;
	POEIKC::Daemon::Utility::_DEBUG_log(join " / ", map {$_ ? $_ : ''} @{$poe->args});
}

sub debug_monitor_callback_unregister
{
	my $poe = sweet_args ;
	my $object = $poe->object;
	my $client = (@{$poe->args})[1];
	delete $connected{$client} if $connected{$client};
	POEIKC::Daemon::Utility::_DEBUG_log(join " / ", map {$_ ? $_ : ''} @{$poe->args});
}

sub debug_monitor_callback_subscribe
{
	my $poe = sweet_args ;
	POEIKC::Daemon::Utility::_DEBUG_log(join " / ", map {$_ ? $_ : ''} @{$poe->args});
}

sub debug_monitor_callback_unsubscribe
{
	my $poe = sweet_args ;
	POEIKC::Daemon::Utility::_DEBUG_log(join " / ", map {$_ ? $_ : ''} @{$poe->args});
}

sub debug_monitor_callback_shutdown
{
	my $poe = sweet_args ;
	POEIKC::Daemon::Utility::_DEBUG_log(join " / ", map {$_ ? $_ : ''} @{$poe->args});
}




sub sig_stop {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%connected);
	$kernel->yield('_stop');
}

sub _stop {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	$kernel->call( IKC => 'shutdown');
	$kernel->stop();
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%connected);
	printf "%s PID:%s ... stopped!! (%s)\n", $0, $$, scalar(localtime);
}

sub shutdown {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object = $poe->object;
	$object->{shutdown_time} ||= time;
	$object->{shutdown_cut} ||= 0;
	if ( $object->{shutdown_cut} < 10 and keys %connected ) {
		$object->{shutdown_cut}++;
		$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($object->{shutdown_time});
		$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%connected);
		$kernel->delay(shutdown => 0.05);
#		$kernel->delay(shutdown => 0.0001);
		return;
	}
	$kernel->call( IKC => 'shutdown');
	$kernel->stop();
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($object->{shutdown_time});
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(\%connected);
	killall('KILL', $0); # SIGKILL
	printf "%s PID:%s ... stopped!! (%s)\n", $0, $$, scalar(localtime);
}


sub something_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $session = $poe->session;
	my $object = $poe->object;
	my ($request) = @{$poe->args};
	my ($args, $rsvp) = @{$request};

	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($request);

	my @something = $object->pidu->_distinguish( poe=>$poe, args => $args );
	@something ?
		$kernel->call($session, execute_respond => @something, $rsvp):

	$kernel->post( IKC => post => $rsvp, {poeikcd_error=>
		'It is not discriminable. '.
		q{"ModuleName::functionName" or  "ClassName->methodName" or "AliasName eventName"}
	});
}

sub event_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	$kernel->yield(execute_respond => 'event', @{$request});
}

sub method_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	$kernel->yield(execute_respond => 'method', @{$request});
}

sub function_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	$kernel->yield(execute_respond => 'function', @{$request});
}

sub execute_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object = $poe->object;
	my ( $from, $args, $rsvp , ) = @{$poe->args};


	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($from, $args, $rsvp);

	ref $args ne 'ARRAY' and
		return $kernel->call( IKC => post => $rsvp,
		{poeikcd_error=>"A parameter is not an Array reference. It is ".ref $args} );

	my $module = shift @{$args};
	my $method = shift @{$args};

	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(module => $module);
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(method => $method);
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(args => $args);

	if($from !~ /^event/ and not $object->pidu->use(module=>$module)) {

			return $kernel->call( IKC => post => $rsvp, {poeikcd_error=>$@} );
	}

	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log(from => $from);

	if ($module eq 'POEIKC::Daemon::Utility'){
		#$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($rsvp);
		my @re = eval {
			$method ?
			$object->pidu->$method(
				poe=>$poe, rsvp=>$rsvp, from=>$from, args=>$args
			) : grep {not /^\_/ and not /^[A-Z]+$/} @{Class::Inspector->methods($module)};
		};
		my $re = @re == 1 ? shift @re : @re ? \@re : ();
		if (not $rsvp->{responded}) {
			$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
				$kernel->post( IKC => post => $rsvp, $re );
			$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($re, $rsvp);
		}else{
			$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($re, $rsvp);
		}
		return;
	}

	my @re = $object->pidu->execute(poe=>$poe, from=>$from, module=>$module, method=>$method, args=>$args);
	my $e = $@ if $@;

	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log('error=>'=>$e);
	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log('@re=>'=>@re);
	my $re = @re == 1 ? shift @re : @re ? \@re : ();

	$DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($module, $method, $re);

	if ($rsvp) {
		return $e ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$e} ) :
			    $kernel->post( IKC => post => $rsvp, $re );

		return  $kernel->post( IKC => post => $rsvp, $re ) if $re;
	}else{
		return @re ? @re : $re || ();
	}

}



1;
__END__

=head1 NAME

POEIKC::Daemon - POE IKC daemon

=head1 SYNOPSIS

L<poeikcd>

	poeikcd start -p=47225
	poeikcd stop  -p=47225
	poeikcd --help

And then
L<poikc> (POK IKC Client)

	poikc -H hostname [options] args...
	poikc --help


=head1 DESCRIPTION

POEIKC::Daemon is daemon of POE::Component::IKC

=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Component::IKC::ClientLite>

=cut
