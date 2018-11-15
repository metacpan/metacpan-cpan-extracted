package Pcore::Core::Event::Listener::xmpp;

use Pcore -class, -ansi, -const;
use Pcore::XMPP;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Util::Data qw[to_json];
use Time::HiRes qw[];

with qw[Pcore::Core::Event::Listener];

has tmpl => '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>][<: $channel :>][<: $level :>] <: $title | raw :><: $text | raw :>';

has username => ( required => 1 );    # Str
has password => ( required => 1 );    # Str
has host     => ( required => 1 );    # Str
has port => 5222;                     # PositiveInt
has to => ( required => 1 );          # Str

has _tmpl => ( init_arg => undef );   # InstanceOf ['Pcore::Util::Tmpl']
has _init => ( init_arg => undef );   # Bool

const our $INDENT => q[ ] x 4;

sub _build_id ($self) { return "xmpp://$self->{host}:$self->{port}?username=$self->{username}&to=$self->{to}" }

sub forward_event ( $self, $ev ) {

    # init
    if ( !$self->{_init} ) {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->add_tmpl( message => $self->{tmpl} );

        Pcore::XMPP->add_account(
            username => $self->{username},
            password => $self->{password},
            host     => $self->{host},
            port     => $self->{port},
        );
    }

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} // Time::HiRes::time() );

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

        Pcore::XMPP->sendmsg( $self->{username}, $self->{to}, $message->$* );
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
## |    3 | 51                   | Variables::RequireInitializationForLocalVars - "local" variable not initialized                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 48, 51               | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 62                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 11                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::xmpp

=head1 SYNOPSIS

    P->bind_events(
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
