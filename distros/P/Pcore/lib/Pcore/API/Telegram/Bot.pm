package Pcore::API::Telegram::Bot;

use Pcore -class;

has key     => ( required => 1 );
has timeout => 1;

has _offset => ( init_arg => undef );

# https://core.telegram.org/bots/api

sub poll_updates ($self) {
    while () {
        my $data = $self->get_updates;

        for my $entry ( $data->{result}->@* ) {
            if ( $entry->{message}->{text} eq '/' ) {
                $self->send_message( $entry->{message}->{chat}->{id}, 'вывывывыэ' );
            }
        }

        Coro::AnyEvent::sleep $self->{timeout};
    }

    return;
}

sub get_updates ($self) {
    my $res = P->http->get(
        "https://api.telegram.org/bot$self->{key}/getUpdates",
        headers => [ 'Content-Type' => 'application/json', ],
        data    => P->data->to_json( {
            offset => $self->{_offset},
            limit  => 100,
        } )
    );

    my $data = P->data->from_json( $res->{data} );

    if ( $data->{result}->@* ) {
        my $update_id = $data->{result}->[-1]->{update_id};

        $self->{_offset} = ++$update_id if defined $update_id;
    }

    return $data;
}

sub send_message ( $self, $chat_id, $text ) {
    my $res = P->http->get(
        "https://api.telegram.org/bot$self->{key}/sendMessage",
        headers => [ 'Content-Type' => 'application/json', ],
        data    => P->data->to_json( {
            chat_id => $chat_id,
            text    => $text,
        } )
    );

    my $data = P->data->from_json( $res->{data} );

    return $data;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Telegram::Bot

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
