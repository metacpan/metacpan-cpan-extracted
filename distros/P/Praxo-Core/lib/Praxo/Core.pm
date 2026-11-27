package Praxo::Core;

use strict;
use warnings;

our $VERSION = '0.8.1';
our $SPEC_VERSION = '0.2.0';

sub version {
    return $VERSION;
}

sub spec_version {
    return $SPEC_VERSION;
}

1;

=head1 NAME

Praxo::Core - Embeddable AI agent framework for Perl

=head1 DESCRIPTION

Praxo::Core is a Perl framework for building AI agents powered by language
models. It provides an agent execution loop, tool calling, policy hooks,
human-in-the-loop approval, session memory, checkpoints, and events.

It is not an HTTP user agent, web crawler, or hosted AI agent service. HTTP is
used by optional adapters to communicate with model providers and external
services.

=head1 SEE ALSO

L<Praxo::Agent>

=cut
