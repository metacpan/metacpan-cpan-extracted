package Demo::P2P;
use strict;
use warnings;
use Data::Dumper;
use Class::Inspector;
use POE qw(Sugar::Args Loop::IO_Poll);
use base qw(POEIKC::Daemon::P2P);
use POEIKC::Daemon::Utility;
$|=1;

sub new {
    my $class = shift ;
    my $self = {};
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}

sub spawn
{
	my $class = shift;
	my $self  = $class->new();
	my $session = POE::Session->create(
	    object_states => [ $self => Class::Inspector->methods(__PACKAGE__) ]
	);
	print('LINE:',__LINE__,"\t", 'spawn', "\n");
	return $session->ID;
}




sub _start {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $object  = $poe->object ;
	my $alias   = $POEIKC::Daemon::opt{name}.'_alias';
	$kernel->alias_set($alias);

	$kernel->call(
		IKC =>
			publish => $alias, Class::Inspector->methods(__PACKAGE__),
	);
	print('LINE:'.__LINE__."\t" , '_start', "\t",$alias,"\n");
}


sub server_connect {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session;
	my $object = $poe->object;
	my ( $server, $port  ) = @{$poe->args} ;

	$server or die;
	$port or die;

	my $hash_param =	{
		ip   => '127.0.0.1',
		port => $port ,
		on_connect => sub {
			print('LINE:'.__LINE__."\t" , 'on_connect!!!!!!!!!!!!!!!!!!!!!!!', "\n");
		},
		on_error =>sub {
			print('LINE:'.__LINE__."\t" , 'on_error!!!!!!!!!!!!!!!!!!!!!!!!!', "\n");
		},
	};

	print('LINE:'.__LINE__."\t", Dumper($hash_param),"\n");

	warn $kernel->call($session => connect=> $server, $hash_param) unless $object->connected($server);

}

sub go {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session;
	my $object = $poe->object;
	my ( $server, $port  ) = @{$poe->args} ;

	my $call = sprintf "poe://%s/%s/catch", $server, $server.'_alias';
	my $back = "poe:callback";
	my $ONE_arg= { 'PID'=>$$, 'LINE'=>__LINE__ };
	print('LINE:'.__LINE__."  " ,"go\t", Dumper [$call, $back, $ONE_arg], "\n");

	$kernel->post('IKC', 'call', $call, $ONE_arg , $back);
}

sub catch {
	my $poe     = sweet_args ;
	my $object = $poe->object;
	my ( @data ) = @{$poe->args} ;
	POEIKC::Daemon::Utility::_DEBUG_log(@data);
	print('LINE:'.__LINE__."  " ,"catch\t", Dumper(\@data), "\n");
	$object->{data} = {this_pid=>$$, catch=>shift @data};
	return [$$, \@data];
}

sub get {
	my $poe     = sweet_args ;
	my $object = $poe->object;
	return $object->{data};
}

sub callback {
	my $poe 	= sweet_args;
	my ( @data ) = @{$poe->args} ;
	print('LINE:'.__LINE__."  ","callback\t",  Dumper(\@data), "\n");
}


1;
