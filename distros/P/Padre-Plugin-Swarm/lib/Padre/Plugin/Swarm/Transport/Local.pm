package Padre::Plugin::Swarm::Transport::Local;
use strict;
use warnings;
use Carp 'confess';
use Padre::Logger;
use Data::Dumper;
use base qw( Object::Event );
use AnyEvent::Handle;
use IO::Socket::Multicast;
use Padre::Swarm::Message;
use JSON;
our $VERSION = '0.2';

=pod

=head1 NAME

Padre::Plugin::Swarm::Transport::Local - Multicast swarm message bus

=head1 DESCRIPTION

=head1 SYNOPSIS

    my $t = Padre::Plugin::Swarm::Transport::Local->new();
    $t->reg_cb('connect' , sub { printf "Transport %s connected", shift } );
    $t->reg_cb('recv', \&incoming_message );
    $t->reg_cb('disconnect', sub { warn "Disconnected" } );
    
    $t->enable;

=cut 

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{token} = $$.rand();
    return $self;
}

sub enable {
    my  $self = shift;
    
    my $m = IO::Socket::Multicast->new(
                LocalPort => 12000,
                ReuseAddr => 1,
    ) or die $!;
    
    $m->mcast_add('239.255.255.1'); #should have the interface
    $m->mcast_loopback( 1 );
    
    $self->{m} = $m;
    $self->{io} = AnyEvent->io(
        fh => $m,
        poll => 'r',
        cb => sub {
             $self->event('readable') 
        }
    );
    $self->reg_cb( 'readable' , \&readable );
    $self->reg_cb('disconnect', \&disconnect );
    $self->event('connect',$self->{token} );
    
    return;
}

sub send {
    my $self = shift;
    my $message = shift;
    
    if ( threads::shared::is_shared( $message ) ) {
        TRACE( "SEND A SHARED REFERENCE ?!?!?! - " . Dumper $message );
        confess "$message , is a shared value";    
    }    

    $message->{token} = $self->{token};
    my $data = eval { $self->_marshal->encode($message) };
    if ($data) {
        $self->{m}->mcast_send(
            $data, '239.255.255.1:12000'
        );
    }
}

sub readable {
    my $self = shift;
    my $data;
    unless ( $self->{m} ) {
        TRACE( 'Multicast handle has gone away!' );
        return;
    }
    $self->{m}->recv($data,65535);
    my $message = eval{ $self->_marshal->decode($data) };
    if ( $message ) {
        $self->event('recv', $message);
    }
    
}


sub disconnect {
    my $self = shift;
    if ( $self->{io} ) {
        delete $self->{io};
        my $m = delete $self->{m};
        $m->mcast_drop('239.255.255.1');
    }
    $self->unreg_me;
}

sub _marshal {
    JSON->new
        ->allow_blessed
        ->convert_blessed
        ->utf8
        ->filter_json_object(\&synthetic_class );
}


sub synthetic_class {
    my $var = shift ;
    if ( exists $var->{__origin_class} ) {
        my $stub = $var->{__origin_class};
        my $msg_class = 'Padre::Swarm::Message::' . $stub;
        my $instance = bless $var , $msg_class;
        return $instance;
    } else {
        return bless $var , 'Padre::Swarm::Message';
    }
};


1;
