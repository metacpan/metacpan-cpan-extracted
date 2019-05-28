package Pcore::API::Telegram::Bot;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[weaken];

has key          => ( required => 1 );
has poll_timeout => 1;
has on_message   => ();                  # CodeRef

has _offset => ( init_arg => undef );

# https://core.telegram.org/bots/api

sub _req ( $self, $path, $data, $cb = undef ) {
    $data = P->data->to_json($data) if $data;

    return P->http->get(
        "https://api.telegram.org/bot$self->{key}/$path",
        headers => [ 'Content-Type' => 'application/json', ],
        data    => $data,
        sub ($res) {
            my $data = P->data->from_json( $res->{data} );

            my $api_res = res 200, $data;

            return $cb ? $cb->($api_res) : $api_res;
        }
    );
}

# TODO
sub set_webhook ( $self, $url, %args ) {
    return;
}

sub poll_updates ( $self, $timeout = $self->{poll_timeout} ) {
    weaken $self;

    my $coro = Coro::async_pool {
        while () {
            last if !defined $self;

            my $res = $self->get_updates;

            for my $msg ( $res->{data}->{result}->@* ) {
                Coro::async_pool {
                    return if !defined $self;

                    $self->_on_message($msg);

                    return;
                };
            }

            last if !defined $self;

            Coro::AnyEvent::sleep $timeout;
        }

        return;
    };

    $coro->cede_to;

    return;
}

sub get_updates ($self) {
    return $self->_req(
        'getUpdates',
        {   offset => $self->{_offset},
            limit  => 100,
        },
        sub ($res) {
            if ( $res->{data}->{result}->@* ) {
                my $update_id = $res->{data}->{result}->[-1]->{update_id};

                $self->{_offset} = ++$update_id if defined $update_id;
            }

            return $res;
        }
    );
}

sub send_message ( $self, $chat_id, $text ) {
    return $self->_req(
        'sendMessage',
        {   chat_id => $chat_id,
            text    => $text,
        }
    );
}

sub _on_message ( $self, $msg ) {
    if ( my $cb = $self->{on_message} ) {
        $cb->( $self, $msg );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Telegram::Bot

=head1 SYNOPSIS

    use Pcore::API::Telegram::Bot;

    my $bot = Pcore::API::Telegram::Bot->new( key => $key );

    $bot->{on_message} = sub ( $bot, $msg ) {
        if ( $msg->{message}->{text} eq '/' ) {
            $bot->send_message( $msg->{message}->{chat}->{id}, 'вывывывыэ' );
        }

        return;
    };

    $bot->poll_updates;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
