package Padre::Plugin::Swarm::Transport::Global;
use strict;
use warnings;
use Carp 'confess';
use Padre::Logger;
use Data::Dumper;
use base qw( Object::Event );
use Padre::Swarm::Message;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Scalar::Util 'blessed';
use JSON;

our $VERSION = '0.2';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->reg_cb( 'start_session' => \&start_session );
    return $self;
}

sub enable {
    my  $self = shift;
    my $g = tcp_connect $self->{host} , $self->{port},
        sub { $self->event( 'start_session', shift) };
    $self->{g} = $g;
}

sub start_session {
    my ($self,$fh) = @_;
    unless ($fh) {
        $self->event('disconnect','Connection failed ' . $!);
        return;   
    }
    my $h = AnyEvent::Handle->new(
        fh => $fh,
        json => $self->_marshal,
        on_eof => sub { $self->event('disconnect', shift ) },
    );
    
    
    # now we register our own disconnect handler for teardown;
    $self->reg_cb('disconnect', \&disconnect );
    
    $self->{h} = $h;
    $h->push_write( json => { trustme=>$$.rand() } );
    $h->push_read( json => sub { $self->event( 'see_auth' , @_ ) } );
    $self->reg_cb( 'see_auth' , \&see_auth );
    
}


sub disconnect {
    my $self = shift;

    if ($self->{h}) {
        $self->{h}->destroy;
        delete $self->{h};
    }
    delete $self->{chirp};
    
    $self->unreg_me;
    
}


sub see_auth {
    my $self = shift;
    my $handle = shift;
    my $message = shift;
    $self->unreg_cb('start_session');
    $self->{h} = $handle;
    $self->{token} = $message->{token};
    if ( $message->{session} eq 'authorized' ) {
        $self->{h}->on_read( sub {
                shift->push_read( json => sub { $self->event('recv',$_[1]) } );
            }
        );
        $self->event('connect'=>$self->{token} );
        # this is hideous but works for me
        # timer pushes some data to the socket every so often to convince
        # firewalls "I really DO want this connection - OK!"
        my $chirp = AnyEvent->timer(
            after => 60,
            interval => 300,
            cb => sub { $self->send( {type=>'noop'}) }
        );
        $self->{chirp} = $chirp;
    }
    else {
        $self->{h}->destroy;
        delete $self->{h};      
        $self->event('disconnect','Authorization failed');
        
    }
}

sub send {
    my $self = shift;
    my $message = shift;
    if ( threads::shared::is_shared( $message ) ) {
        TRACE( "SEND A SHARED REFERENCE ?!?!?! - " . Dumper $message );
        confess "$message , is a shared value";
    }
    $message->{token} = $self->{token};
    $self->{h}->push_write( json => $message );
    # implement our own loopback ?
    # nasty but fake what the deserializing marshal _would_ do.
    unless ( blessed $message ) {
        bless $message, 'Padre::Swarm::Message';
    }
    $self->event('recv', $message );
    
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
