package Pcore::API::ProxyPool::Source::ProxyRack;

use Pcore -class;

with qw[Pcore::API::ProxyPool::Source];

has uri => ( is => 'ro', isa => Str, predicate => 1 );
has type => ( is => 'ro', isa => Enum [qw[ANY FASTEST TOP10]], default => 'FASTEST' );    # TOP10 - top 10% of all proxies

has '+load_timeout' => ( default => 0, init_arg => undef );
has '+max_threads_source' => ( isa => Enum [ 50, 100, 200 ], default => 50 );
has '+is_multiproxy' => ( default => 1, init_arg => undef );

sub load ( $self, $cb ) {
    my $proxies;

    if ( $self->uri ) {
        push $proxies->@*, $self->uri;
    }
    else {
        if ( $self->type eq 'ANY' ) {
            push $proxies->@*, '//37.58.52.41:2020';
        }
        elsif ( $self->type eq 'FASTEST' ) {
            push $proxies->@*, '//37.58.52.41:3030';
        }
        elsif ( $self->type eq 'TOP10' ) {
            push $proxies->@*, '//37.58.52.41:4040';
        }
    }

    $cb->($proxies);

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Source::ProxyRack

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
