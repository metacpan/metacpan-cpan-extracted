package Net::Curl::Promiser::AnyEvent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::AnyEvent - support for L<AnyEvent>

=head1 SYNOPSIS

    my $promiser = Net::Curl::Promiser::AnyEvent->new();

    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );

    my $cv = AnyEvent->condvar();

    $promiser->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    )->finally($cv);

    $cv->recv();

=head1 DESCRIPTION

This module provides an L<AnyEvent>-compatible subclass of
L<Net::Curl::Promiser>.

See F</examples> in the distribution, as well as the tests,
for fleshed-out demonstrations.

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser::LoopBase';

use Net::Curl::Promiser::Backend::AnyEvent ();

#----------------------------------------------------------------------

sub _INIT {
    my ($self, $args_ar) = @_;

    return Net::Curl::Promiser::Backend::AnyEvent->new();
}

1;
