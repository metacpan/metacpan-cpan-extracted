package Pcore::API::ProxyPool::Source::File;

use Pcore -class;
use Pcore::Util::Text qw[trim];

with qw[Pcore::API::ProxyPool::Source];

has path => ( is => 'ro', isa => Str, required => 1 );

sub load ( $self, $cb ) {
    my $proxies;

    if ( -f $self->path ) {
        for my $uri ( P->file->read_lines( $self->path )->@* ) {
            trim $uri;

            push $proxies->@*, $uri if $uri;
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

Pcore::API::ProxyPool::Source::File

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
