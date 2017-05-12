package Pod::Abstract::Filter::clear_podcmds;
use strict;

use base qw(Pod::Abstract::Filter);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::clear_podcmds - paf command to remove =pod commands
from the begining of Pod blocks.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;

    my ($first_node) = $pa->select("/(0)");
    my @pod_cmds = $pa->select(
        "//pod[!<<#cut]"
        );
    foreach my $pod_cmd (@pod_cmds) {
        # The start of the document is in cut mode, even if there is
        # no text there, so if the lead node is an =pod node don't
        # strip it.
        $pod_cmd->detach
            unless $pod_cmd->serial == $first_node->serial;
    }
    
    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
