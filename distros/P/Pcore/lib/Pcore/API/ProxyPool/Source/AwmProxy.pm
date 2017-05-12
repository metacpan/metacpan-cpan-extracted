package Pcore::API::ProxyPool::Source::AwmProxy;

use Pcore -class;
use Pcore::Util::Text qw[decode_eol];

with qw[Pcore::API::ProxyPool::Source];

has api_key      => ( is => 'ro', isa => Str,         required  => 1 );
has username     => ( is => 'ro', isa => Str,         predicate => 1 );
has password     => ( is => 'ro', isa => Str,         predicate => 1 );
has http_timeout => ( is => 'ro', isa => PositiveInt, default   => 10 );

has '+max_threads_source' => ( isa => Enum [ 0, 350 ], default => 350 );

sub BUILD ( $self, $args ) {
    $self->bind_ip if $args->{bind_ip};

    return;
}

sub load ( $self, $cb ) {
    P->http->get(
        'http://awmproxy.com/allproxy.php?full=1',
        timeout   => $self->http_timeout,
        on_finish => sub ($res) {
            my $proxies;

            if ( $res->status == 200 && $res->has_body ) {
                decode_eol $res->body->$*;

                for my $addr ( split /\n/sm, $res->body->$* ) {
                    my ( $addr, $real_ip, $country, $speed, $time ) = split /;/sm, $addr;

                    push $proxies->@*, $addr;
                }
            }

            $cb->($proxies);

            return;
        },
    );

    return;
}

# TODO not a safe call, password send va http
sub bind_ip ($self) {
    die if !$self->has_username || !$self->has_password;

    my $res = P->http->get( 'http://awmproxy.com/setmyip.php?Login=' . $self->username . '&Password=' . $self->password );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Source::AwmProxy

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
