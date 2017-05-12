package PagSeguro::API::Notification;
use Moo;

extends 'PagSeguro::API::Base';

use Carp;
use PagSeguro::API::Transaction;

# attributes
has code => (is => 'rw');
has transaction => (is => 'rw');

sub by_code {
    my $self = shift;

    my $code = shift;
    croak "error: code cannot be null!" unless $code;

    my $transaction = PagSeguro::API::Transaction
        ->new( 
            email => $self->email, 
            token => $self->token,
            debug => $self->debug,
            environment => $self->environment
        );

    return $transaction->by_notification_code($code);
}

1;
__END__

=encoding utf8

=head1 NAME

PagSeguro::API::Notification - Classe que implementation features de 
notificações

=head1 SYNOPSIS

    use PagSeguro::API;

    # new instance
    my $p = PagSeguro::API->new;
    
    #configure
    $p->email('foo@bar.com');
    $p->token('95112EE828D94278BD394E91C4388F20');

    # new notification
    my $notification = $p->notification;
    my $response = $notification->by_code('NOTIFICATION_CODE');

    # error
    die "Error: ". $response->error if $response->error;
    
    say $response->data;

=head1 DESCRIPTION

Esta classe implementa a parte da API responsável pelas notificações.


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>



