package Pcore::HTTP::Request;

use Pcore -class, -const;
use Pcore::AE::Handle qw[:PERSISTENT];
use Pcore::HTTP;
use Pcore::HTTP::CookieJar;

extends qw[Pcore::HTTP::Message];

has method => ( is => 'ro', isa => Enum             [ keys $Pcore::HTTP::HTTP_METHODS->%* ] );
has url    => ( is => 'ro', isa => Str | InstanceOf ['Pcore::Util::URI'] );

has useragent => ( is => 'ro', isa => Str, default => $Pcore::HTTP::DEFAULT->{useragent} );
has recurse => ( is => 'ro', isa => PositiveOrZeroInt, default => $Pcore::HTTP::DEFAULT->{recurse} );
has keepalive_timeout => ( is => 'ro', isa => Maybe [PositiveOrZeroInt], default => $Pcore::HTTP::DEFAULT->{keepalive_timeout} );
has timeout           => ( is => 'ro', isa => PositiveOrZeroInt, default => $Pcore::HTTP::DEFAULT->{timeout} );
has accept_compressed => ( is => 'ro', isa => Bool,              default => $Pcore::HTTP::DEFAULT->{accept_compressed} );
has decompress        => ( is => 'ro', isa => Bool,              default => $Pcore::HTTP::DEFAULT->{decompress} );
has persistent => ( is => 'ro', isa => Enum [ $PERSISTENT_IDENT, $PERSISTENT_ANY, $PERSISTENT_NO_PROXY ], default => $Pcore::HTTP::DEFAULT->{persistent} );
has session    => ( is => 'ro', isa => Maybe [Str],    default => $Pcore::HTTP::DEFAULT->{session} );
has cookie_jar => ( is => 'ro', isa => Maybe [Object], default => $Pcore::HTTP::DEFAULT->{cookie_jar} );

has tls_ctx => ( is => 'ro', isa => Maybe [ Enum [ $Pcore::HTTP::TLS_CTX_LOW, $Pcore::HTTP::TLS_CTX_HIGH ] | HashRef ], default => $Pcore::HTTP::DEFAULT->{tls_ctx} );
has bind_ip => ( is => 'ro', isa => Maybe [Str], default => $Pcore::HTTP::DEFAULT->{bind_ip} );
has proxy => ( is => 'ro', writer => 'set_proxy', predicate => 1, clearer => 1 );
has handle_params => ( is => 'ro', isa => Maybe [HashRef], default => $Pcore::HTTP::DEFAULT->{handle_params} );

has on_progress => ( is => 'ro', isa => Maybe [ Bool | CodeRef ], default => $Pcore::HTTP::DEFAULT->{on_progress} );
has on_header     => ( is => 'ro', isa => Maybe [CodeRef], default => $Pcore::HTTP::DEFAULT->{on_header} );
has on_body       => ( is => 'ro', isa => Maybe [CodeRef], default => $Pcore::HTTP::DEFAULT->{on_body} );
has before_finish => ( is => 'ro', isa => Maybe [CodeRef], default => $Pcore::HTTP::DEFAULT->{before_finish} );
has on_finish     => ( is => 'ro', isa => Maybe [CodeRef], default => $Pcore::HTTP::DEFAULT->{on_finish} );

sub BUILDARGS ( $self, @ ) {
    my $args = ref $_[1] ? $_[1] : { splice @_, 1 };

    $args->{cookie_jar} = Pcore::HTTP::CookieJar->new if $args->{cookie_jar} && !ref $args->{cookie_jar};

    $args->{url} = P->uri( $args->{url}, base => 'http://', authority => 1 ) if $args->{url} && !ref $args->{url};

    return $args;
}

sub run ( $self, @ ) {
    return P->http->_request(@_);
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 45                   | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Request

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
