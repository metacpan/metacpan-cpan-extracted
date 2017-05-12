package Pod::Abstract::Filter::add_podcmds;
use strict;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::add_podcmds - paf command to insert explict =pod
commands before each Pod block in a document.

=head1 METHODS

=head2 filter

Add a =pod command after each block of cut nodes. This will cause
explicit pod declarations wherever they are currently implicit.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;

    my @cut_finals = $pa->select(
        "//#cut[!>>#cut][!>>pod]"
        );

    # If the document ends with a cut, we don't want a new Pod section
    # - but if it ends with a pod, we do.
    my $last_cut = pop @cut_finals;
    my $ignore_last = 1;
    my $p = $last_cut;
    $ignore_last = 0 if $p->next;
    while($p && ($p = $p->parent) && $ignore_last) {
        $ignore_last = 0 if $p->next;
    }
    push @cut_finals, $last_cut unless $ignore_last;

    foreach my $n (@cut_finals) {
        node->pod->insert_after($n);
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

