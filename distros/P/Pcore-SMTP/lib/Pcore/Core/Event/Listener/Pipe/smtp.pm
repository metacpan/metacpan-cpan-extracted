package Pcore::Core::Event::Listener::Pipe::smtp;

use Pcore -class, -ansi;
use Pcore::SMTP;
use Pcore::AE::Handle qw[:TLS_CTX];
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[is_ref];

with qw[Pcore::Core::Event::Listener::Pipe];

has tmpl => ( is => 'ro', isa => Str, default => '[<: $date.strftime("%Y-%m-%d %H:%M:%S.%4N") :>][<: $channel :>][<: $level :>] <: $title | raw :>' );

has from => ( is => 'ro', isa => Str, required => 1 );
has to   => ( is => 'ro', isa => Str, required => 1 );
has reply_to => ( is => 'ro', isa => Str );
has cc       => ( is => 'ro', isa => Str );
has bcc      => ( is => 'ro', isa => Str );

has host     => ( is => 'ro', isa => Str,         required => 1 );
has port     => ( is => 'ro', isa => PositiveInt, required => 1 );
has username => ( is => 'ro', isa => Str,         required => 1 );
has password => ( is => 'ro', isa => Str,         required => 1 );
has tls      => ( is => 'ro', isa => Bool,        default  => 1 );
has tls_ctx => ( is => 'ro', isa => Maybe [ HashRef | Enum [ $TLS_CTX_HIGH, $TLS_CTX_LOW ] ], default => $TLS_CTX_HIGH );

has _tmpl => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Template'], init_arg => undef );
has _smtp => ( is => 'ro', isa => InstanceOf ['Pcore::SMTP'],           init_arg => undef );

has _init => ( is => 'ro', isa => Bool, init_arg => undef );

sub sendlog ( $self, $ev ) {

    # init
    if ( !$self->{_init} ) {
        $self->{_init} = 1;

        # init template
        $self->{_tmpl} = P->tmpl;

        $self->{_tmpl}->cache_string_tmpl( subject => \$self->{tmpl} );

        $self->{_smtp} = Pcore::SMTP->new( {
            host     => $self->{host},
            port     => $self->{port},
            username => $self->{username},
            password => $self->{password},
            tls      => $self->{tls},
            tls_ctx  => $self->{tls_ctx}
        } );
    }

    # sendlog
    {
        # prepare date object
        local $ev->{date} = P->date->from_epoch( $ev->{timestamp} );

        # prepare data
        my $body;

        if ( defined $ev->{data} ) {

            # serialize reference
            $body = $LF . ( is_ref $ev->{data} ? to_json( $ev->{data}, readable => 1 )->$* : $ev->{data} );

            # remove all trailing "\n"
            local $/ = '';

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
            sub ($res) {return}
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
## |    2 | 55                   | Variables::ProhibitLocalVars - Variable declared as "local"                                                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 66                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 11                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Event::Listener::Pipe::smtp

=head1 SYNOPSIS

    P->listen_events(
        'LOG.TEST.*',
        [   'smtp:',
            host     => 'smtp.gmail.com',
            port     => 465,
            username => '',
            password => '',
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
