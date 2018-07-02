package Pcore::Core::Event::Listener::Pipe::xmpp;

use Pcore -class, -ansi, -const;
use Pcore::XMPP;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Util::Data qw[to_json];

with qw[Pcore::Core::Event::Listener::Pipe];

has tmpl => ( is => 'ro', isa => Str, default => '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>][<: $channel :>][<: $level :>] <: $title | raw :><: $text | raw :>' );

has username => ();      # is => 'ro', isa => Str, required => 1
has password => ();      # isa => Str,         required => 1
has host     => ();      # isa => Str,         required => 1
has port     => 5222;    # isa => PositiveInt
has to       => ();      # isa => Str,         required => 1

has _tmpl  => ();        # InstanceOf ['Pcore::Util::Tmpl'], init_arg => undef
has _h     => ();        # InstanceOf ['Pcore::Handle::xmpp'],   init_arg => undef
has _queue => ();        # isa => ArrayRef, init_arg => undef
has _init  => ();        #  isa => Bool, init_arg => undef

const our $INDENT => q[ ] x 4;

sub sendlog ( $self, $ev ) {

    # init
    if ( !$self->{_init} ) {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->cache_string_tmpl( message => \$self->{tmpl} );

        $self->{_h} = AnyEvent::XMPP::Client->new;

        $self->{_h}->add_account( $self->{username}, $self->{password}, $self->{host}, $self->{port}, undef );

        weaken $self;

        $self->{_h}->reg_cb(
            session_ready => sub ( $h, $acc ) {
                if ( defined $self ) {
                    $self->_on_connect( $h, $acc );
                }

                return;
            }
        );

        $self->{_h}->start;
    }

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} );

        # prepare text
        local $ev->{text};

        if ( defined $ev->{data} ) {

            # serialize reference
            $ev->{text} = $LF . ( ref $ev->{data} ? to_json( $ev->{data}, readable => 1 )->$* : $ev->{data} );

            # indent
            $ev->{text} =~ s/^/$INDENT/smg;

            # remove all trailing "\n"
            local $/ = '';

            chomp $ev->{text};
        }

        my $message = $self->{_tmpl}->render( 'message', $ev );

        if ( !$self->{_h}->get_connected_accounts ) {
            push $self->{_queue}->@*, $message;
        }
        else {
            $self->{_h}->send_message( $message->$*, $self->{to}, $self->{username}, 'chat' );
        }
    }

    return;
}

sub _on_connect ( $self, $xmpp, $acc ) {
    while ( my $msg = shift $self->{_queue}->@* ) {
        $xmpp->send_message( $msg->$*, $self->{to}, $self->{username}, 'chat' );
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 61                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 58, 61               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 72                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 10                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::Pipe::xmpp

=head1 SYNOPSIS

    P->listen_events(
        'LOG.#',
        [   'xmpp:',
            username => 'user@gmail.com',
            password => '',
            host     => 'talk.google.com',
            port     => 5222,
            to       => 'target@domain.net',
        ]
    );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
