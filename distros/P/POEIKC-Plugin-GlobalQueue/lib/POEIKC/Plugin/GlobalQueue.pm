package POEIKC::Plugin::GlobalQueue;

use strict;
use 5.008_001;
our $VERSION = '0.04';

use Data::Dumper;
use Class::Inspector;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Client
);

use POEIKC::Plugin::GlobalQueue::Message;
use POEIKC::Daemon::Utility;

sub spawn
{
	my $class = shift;
    my $self = {
        	tag => {},
        	count => 0,
        	globalQueueClean => 15,
        	@_
        };
    $class = ref $class if ref $class;
    bless  $self,$class ;
	my $session = POE::Session->create(
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ]
	);
	return $self;
}


sub conf {
	my $poe = sweet_args;
	my $object  = $poe->object ;
	my @args = @{$poe->args};
	my $key = shift @args || return;
	$object->{$key} = shift @args if @_;
	return $object->{$key};
}

sub _start {
	my $poe     = sweet_args ;
	my $kernel  = $poe->kernel ;
	my $session = $poe->session ;
	my $object  = $poe->object ;
	my $alias = 'GlobalQueue';
	$kernel->alias_set($alias);

	$kernel->sig( HUP  => '_stop' );
	$kernel->sig( INT  => '_stop' );
	$kernel->sig( TERM => '_stop' );
	$kernel->sig( KILL => '_stop' );

	$kernel->call(
		IKC =>
			publish => $alias, [qw/
				enqueue_respond enqueue
				dequeue_respond dequeue
				dump_respond dump
				length_respond respond
				/],
	);

	$kernel->delay('globalQueueClean' => 3);
}

sub _stop {
	my $poe = sweet_args;
}

sub globalQueueClean {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object  = $poe->object ;
	my @tags = keys %{$object->{tag}};
	POEIKC::Daemon::Utility::_DEBUG_log(\@tags);
	for my $tag(@tags) {
		my @tmparray;
		while (my $message = shift @{$object->{tag}->{$tag}}) {
			push @tmparray, $message->expire;
		}
		POEIKC::Daemon::Utility::_DEBUG_log(\@tmparray);
		@{$object->{tag}->{$tag}} = @tmparray;
	}

	$kernel->delay('globalQueueClean' => $object->{globalQueueClean});
}

sub enqueue_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	POEIKC::Daemon::Utility::_DEBUG_log($request);
	my ($param, $rsvp) = @{$request};
	my $session = $poe->session ;
	$kernel->post( IKC => post => $rsvp, $kernel->call($session => 'enqueue' => $param) );
}

sub enqueue {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object  = $poe->object ;
	my ($message) = @{$poe->args};
	$object->{count}++;
	#my $substance = delete $message->{substance};
	POEIKC::Daemon::Utility::_DEBUG_log($message);
	eval {
	$message = POEIKC::Plugin::GlobalQueue::Message->new(
		undef ,%{$message}, gqId=>$object->{count});
	};if($@){
		return $@;
	}
	my $tag = $message->tag;
	push @{$object->{tag}->{$tag}}, $message;
	scalar @{$object->{tag}->{$tag}};
}

sub length {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object = $poe->object ;
	my @args   = @{$poe->args} ;
	POEIKC::Daemon::Utility::_DEBUG_log(\@args);
	@args = @{$args[0]} if ref $args[0] eq 'ARRAY';
	my %args = %{$args[0]} if ref $args[0] eq 'HASH';
	my $tag = %args ? $args{tag} : shift @args ;
	if ($tag) {
		return scalar(@{$object->{tag}->{$tag}}) if exists $object->{tag}->{$tag};
	}else{
		my %tags;
		for my $tag(keys %{$object->{tag}}) {
			$tags{$tag} = scalar(@{$object->{tag}->{$tag}});
		}
		return \%tags;
	}
	return;
}

sub length_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $session = $poe->session;
	my ($request) = @{$poe->args};
	my ($param, $rsvp) = @{$request};
	$kernel->post( IKC => post => $rsvp, $kernel->call($session => 'length', $param) );
}

sub dequeue {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object = $poe->object ;
	my @args   = @{$poe->args} ;
	@args = @{$args[0]} if ref $args[0] eq 'ARRAY';
	my %args = %{$args[0]} if ref $args[0] eq 'HASH';
	POEIKC::Daemon::Utility::_DEBUG_log(@args);
	my ($tag, $length);
	if (%args) {
		$tag    = $args{tag} ;
		$length = $args{length};
	}else{
		$length = shift @args if $args[0] =~ /^\d+$/;
		$tag = shift @args if not $length;
		$length ||= shift @args if @args;
	}
	$tag ||= 'non-tag';
	return unless exists $object->{tag}->{$tag};
	$length ||= scalar(@{$object->{tag}->{$tag}});
	my @list = splice @{$object->{tag}->{$tag}}, 0, $length;
	POEIKC::Daemon::Utility::_DEBUG_log(@list);
	return \@list;
}

sub dequeue_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $session = $poe->session;
	my $object  = $poe->object ;
	my ($request) = @{$poe->args};
	my ($param, $rsvp) = @{$request};
	my @list = $kernel->call($session => 'dequeue', $param);
	$kernel->post( IKC => post => $rsvp, \@list );
}

sub dump {
	my $poe = sweet_args;
	return $poe->object->{tag};
}

sub dump_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	my (undef, $rsvp) = @{$request};
	$kernel->post( IKC => post => $rsvp, $poe->object->{tag} );
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

POEIKC::Plugin::GlobalQueue - POE and IKC based queue server.

=head1 SYNOPSIS

  poeikcd start -M=POEIKC::Plugin::GlobalQueue -n=GlobalQueue -a=QueueServer -p=47301 -s


=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<poeikcd>
L<POEIKC::Plugin::GlobalQueue::Message>
L<POEIKC::Plugin::GlobalQueue::ClientLite>

=cut
