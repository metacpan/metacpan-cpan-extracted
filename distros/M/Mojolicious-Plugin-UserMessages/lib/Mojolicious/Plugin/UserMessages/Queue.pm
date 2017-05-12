package Mojolicious::Plugin::UserMessages::Queue;
{
  $Mojolicious::Plugin::UserMessages::Queue::VERSION = '0.511';
}

use Carp;
use strict;

use Mojolicious::Plugin::UserMessages::Message;

our $AUTOLOAD;

sub new {
    my ( $class, $app ) = @_;
    return bless({'app'=>$app}, $class);
}

sub AUTOLOAD {
    my $s = shift;

    my $method = $AUTOLOAD;
    $method =~ s/.*://;    # strip fully-qualified portion

    return if $method eq 'DESTROY';

    if ( $method =~ /^get_(.+)$/i ) {
        my $type = lc( $1 );
        return $s->get( $type );
    }
    if ( $method =~ /^has_(.+)_messages$/i ) {
        my $type = lc( $1 );
        return $s->has_messages_in_queue( $type );
    }

    croak "Unkown method $method\n";
}


sub add {
    my $self    = shift;
    my $type    = shift;
    my $message = shift;
    my %args    = @_;

    my $c    = $self->{'app'};

    if ( !$c->session->{'__ui_message_queue'} ) {
        $c->session->{'__ui_message_queue'} = [];
    }

    return 0 if !$message;
    return 0 if !$type;

    my $msg = { 
                'type'    => $type,
                'args'    => \%args,
                'message' => $message,
              };

    push @{ $c->session->{'__ui_message_queue'} }, $msg;

    return 1;
}

sub get {
    my $self             = shift;
    my $type             = shift;

    my $c = $self->{'app'};

    if ( !$c->session->{'__ui_message_queue'} ) {
        return [];
    }

    my @to_return = ();
    my @to_keep   = ();

    for my $m ( @{ $c->session->{'__ui_message_queue'} } ) {
        if ( !$type || $type eq $m->type ) {
            push @to_return,
                 Mojolicious::Plugin::UserMessages::Message->new(%$m);
            next;
        }
        push @to_keep, $m;
    }

    $c->session->{'__ui_message_queue'} = \@to_keep;

    return wantarray ? @to_return : \@to_return;
}

sub has_messages {
    my $self = shift;

    return $self->has_messages_in_queue();
}

sub has_messages_in_queue {
    my $self = shift;
    my $type = shift;

    my $c = $self->{'app'};
    if ( !$c->session->{'__ui_message_queue'} ) {
        return 0;
    }

    my @messages = @{ $c->session->{'__ui_message_queue'} };
    if ( !$type ) {
        return scalar( @messages ) ? 1 : 0;
    }

    for my $m ( @messages ) {
        return 1 if ( $type eq $m->{'type'} );
    }

    return 0;
}

1;
