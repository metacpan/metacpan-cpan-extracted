package Pcore::Core::Event::Listener::smtp;

use Pcore -class, -ansi;
use Pcore::API::SMTP;
use Pcore::Handle qw[:TLS_CTX];
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_ref];
use Time::HiRes qw[];

with qw[Pcore::Core::Event::Listener];

has tmpl => '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>][<: $channel :>][<: $level :>] <: $title | raw :>';

has from => ( required => 1 );
has to   => ( required => 1 );
has reply_to => ();
has cc       => ();
has bcc      => ();

has host     => ( required => 1 );
has port     => ( required => 1 );
has username => ( required => 1 );
has password => ( required => 1 );
has tls      => 1;
has tls_ctx  => $TLS_CTX_HIGH;

has _tmpl => ( init_arg => undef );
has _smtp => ( init_arg => undef );
has _init => ( init_arg => undef );

sub _build_id ($self) { return "smtp://$self->{host}:$self->{port}?username=$self->{username}&to=$self->{to}" }

sub forward_event ( $self, $ev ) {

    # init
    $self->{_init} //= do {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->add_tmpl( subject => $self->{tmpl} );

        $self->{_smtp} = Pcore::API::SMTP->new( {
            host     => $self->{host},
            port     => $self->{port},
            username => $self->{username},
            password => $self->{password},
            tls      => $self->{tls},
            tls_ctx  => $self->{tls_ctx}
        } );

        1;
    };

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} // Time::HiRes::time() );

        # prepare data
        my $body;

        if ( defined $ev->{data} ) {

            # serialize reference
            $body = "\n" . ( is_ref $ev->{data} ? to_json $ev->{data}, readable => 1 : $ev->{data} );

            # remove all trailing "\n"
            local $/ = $EMPTY;

            chomp $body;
        }

        $self->{_smtp}->sendmail(
            from     => $self->{from},
            reply_to => $self->{reply_to} || $self->{from},
            to       => $self->{to},
            cc       => $self->{cc},
            bcc      => $self->{bcc},
            subject  => $self->{_tmpl}->render( 'subject', $ev )->$*,
            body     => $body,
        );
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
## |    2 | 59                   | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 12                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::smtp

=head1 SYNOPSIS

    P->on(
        'log.test.*',
        [   'smtp:',
            host     => 'smtp.gmail.com',
            port     => 465,
            username => $EMPTY,
            password => $EMPTY,
            tls      => 1,
            tls_ctx  => undef,

            from   => 'user@domain.com',
            to     => 'user@domain.com',
            tmpl   => '<: $timestamp :>',
        ]
    );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
