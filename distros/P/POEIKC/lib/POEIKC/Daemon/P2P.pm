package POEIKC::Daemon::P2P;

use strict;
use 5.008_001;

use warnings;
use Data::Dumper;
use UNIVERSAL::require;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Client
);

use POEIKC;
our $VERSION = $POEIKC::VERSION;
use POEIKC::Daemon;
use POEIKC::Daemon::Utility;

####


sub connect {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $object = $poe->object;
	my $session = $poe->session;
	my ( $server, $hash , $delay) = @{$poe->args} ;

	return $POEIKC::Daemon::connected{$server}
			if $server and $POEIKC::Daemon::connected{$server};

	$POEIKC::Daemon::DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($server, $delay, $hash);

	my $ret = $object->create_client( $hash, $server );
	$delay and $kernel->delay(connect => $delay, $server, $hash, $delay);
	return $ret;
}


sub connected {
	my $self = shift;
	my $server = shift;
	return $POEIKC::Daemon::connected{$server};
}


sub create_client {
	my $self = shift;
	my $hash = shift;
	my $server = shift;

	return $POEIKC::Daemon::connected{$server}
			if $server and $POEIKC::Daemon::connected{$server};

	if ( $hash->{aliases} ) {
		if (ref $hash->{aliases} eq 'ARRAY'){
			my $flag;
			for ( @{$hash->{aliases}} ) {
				$flag = 1 if $POEIKC::Daemon::opt{name} eq $_;
			}
			push @{$hash->{aliases}}, $POEIKC::Daemon::opt{name} if not $flag;
		}else{
			my $aliases = $hash->{aliases};
			$hash->{aliases} = [];
			push @{$hash->{aliases}}, ($aliases, $POEIKC::Daemon::opt{name});
		}
	}else{
		push @{$hash->{aliases}}, ($POEIKC::Daemon::opt{name});
	}

	$hash->{name} ||= $POEIKC::Daemon::opt{name} . join('_'=>__PACKAGE__ =~ m/(\w+)/g);

	$POEIKC::Daemon::DEBUG and POEIKC::Daemon::Utility::_DEBUG_log($hash);

	POE::Component::IKC::Client->spawn(%{$hash});
}


1;
__END__

=head1 NAME

POEIKC::Daemon::P2P - The thing which does Peer-to-Peer in poeikcd

=head1 SYNOPSIS

	package MyP2P;

	use strict;
	use warnings;
	use Data::Dumper;
	use Class::Inspector;
	use POE qw(Sugar::Args Loop::IO_Poll);
	use POEIKC::Daemon::Utility;

	# use base ...
	use base qw(POEIKC::Daemon::P2P);

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

		# A parameter of HASH is a parameter of create_ikc_client.
		# See POE::Component::IKC::Clien
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

		# Is it already connected? can confirm it
		if (not $object->connected($server)) {
			# Then connected.
			$kernel->yield(connect=> $server, $hash_param) ;
		}

	}

	sub go {
		my $poe     = sweet_args ;
		my $kernel  = $poe->kernel ;
		my $session = $poe->session;
		my $object = $poe->object;
		my ( $server, $port  ) = @{$poe->args} ;

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

and then ...

At one terminal. 

  poeikcd start -f -n=ServerA -p=1111 -I=eg/lib:lib -M=MyP2P

And at another terminal.

  poeikcd start -f -n=ServerB -p=2222 -I=eg/lib:lib -M=MyP2P

At another terminal.

  poikc -p=1111 -D "MyP2P->spawn"
  poikc -p=2222 -D "MyP2P->spawn"

  poikc -p=1111 -D ServerA_alias server_connect ServerB 2222
        or  poikc -p=2222 -D ServerB_alias server_connect ServerA 1111

  poikc -p=1111 -D ServerA_alias go ServerB
  poikc -p=2222 -D ServerB_alias go ServerA


=head1 DESCRIPTION

use it to communicate between poeikcd. (peer-to-peer)

=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Component::IKC>
L<POE::Component::IKC::Client>

=cut
