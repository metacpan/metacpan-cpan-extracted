use utf8;
package Net::Etcd::Config;

use strict;
use warnings;

use Moo;
use namespace::clean;

=head1 NAME

Net::Etcd::Config

=cut

our $VERSION = '0.014';

=head1 ACCESSORS

=head2 etcd

=cut

has etcd => ( is => 'lazy' );

sub _build_etcd {
    my $self  = shift;
    my $found = `which etcd`;
    if ( $? == 0 ) {
        chomp($found);
        return $found;
    }
    return;
}

=head2 configuration

=cut

sub configuration {
    return Net::Etcd::Config->new;
}

=head2 configure

=cut

sub configure {
    my $class = shift;
    my $code  = shift;
    local $_ = $class->configuration;
    $code->($_);
    return;
}

1;
