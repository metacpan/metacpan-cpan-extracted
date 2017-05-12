package MyP2P;

use strict;
use warnings;
use Data::Dumper;
use Class::Inspector;
use POE qw(Sugar::Args Loop::IO_Poll);
use base qw(POEIKC::Daemon::P2P);
use POEIKC::Daemon::Utility;

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
	print('LINE:'.__LINE__."\t" , '_start', "\n");
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
		ip   => 'localhost',
		port => $port ,
		on_connect => sub {
			print('LINE:'.__LINE__."\t" , 'on_connect', "\n");
		},
		on_error =>sub {
			print('LINE:'.__LINE__."\t" , 'on_error', "\n");
		},
	};

	$kernel->yield(connect=> $server, $hash_param) unless $object->connected($server);

}

sub go {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session;
	my $object = $poe->object;
	my ( $server, $port  ) = @{$poe->args} ;

#	$server or die;
#	$port or die;
#
#	my $hash_param =	{
#		ip   => 'localhost',
#		port => $port ,
#		on_connect => sub {
#			$kernel->post($session, 'go', $server, $port );
#			POEIKC::Daemon::Utility::_DEBUG_log('on_connect');
#		},
#		on_error =>sub {
#			POEIKC::Daemon::Utility::_DEBUG_log('on_error');
#		},
#	};
#
#	if ( not $object->connected($server) ) {
#		$kernel->yield(connect=> $server, $hash_param, 0.1);
#		return;
#	}

	my $call = sprintf "poe://%s/%s/catch", $server, $server.'_alias';
	my $back = "poe:callback";
	my $ONE_arg= [ 'PID:'.$$, 'LINE:'.__LINE__ ];
	print('LINE:'.__LINE__."  " ,"go\t", Dumper([$call, $back, $ONE_arg]), "\n");

	$kernel->post('IKC', 'call', $call, $ONE_arg , $back);
}

sub catch {
	my $poe     = sweet_args ;
	my ( @data ) = @{$poe->args} ;
	print('LINE:'.__LINE__."  " ,"catch\t", Dumper(\@data), "\n");
	return [$$, \@data];
}

sub callback {
	my $poe 	= sweet_args;
	my ( @data ) = @{$poe->args} ;
	print('LINE:'.__LINE__."  ","callback\t",  Dumper(\@data), "\n");
}

1;
__END__

  poeikcd start -f -n=ServerA -p=1111 -I=eg/lib:lib -M=MyP2P
  poeikcd start -f -n=ServerB -p=2222 -I=eg/lib:lib -M=MyP2P

  poikc -p=1111 -D "MyP2P->spawn"
  poikc -p=2222 -D "MyP2P->spawn"

  poikc -p=1111 -D ServerA_alias server_connect ServerB 2222
        or  poikc -p=2222 -D ServerB_alias server_connect ServerA 1111

  poikc -p=1111 -D ServerA_alias go ServerB
  poikc -p=2222 -D ServerB_alias go ServerA
