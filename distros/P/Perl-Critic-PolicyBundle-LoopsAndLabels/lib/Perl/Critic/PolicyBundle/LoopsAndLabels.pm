#!/bin/false
# ABSTRACT: Bundle of policies for loop control flow and labels
# PODNAME: Perl::Critic::PolicyBundle::LoopsAndLabels

use strict;
use warnings;

package Perl::Critic::PolicyBundle::LoopsAndLabels;
$Perl::Critic::PolicyBundle::LoopsAndLabels::VERSION = '0.07';
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Critic::PolicyBundle::LoopsAndLabels - Bundle of policies for loop control flow and labels

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This is a bundle of Perl::Critic policies related to loop control flow
and labeling.  Install this bundle to get all three policies at once.

The policies in this bundle complement each other:

=over

=item L<Perl::Critic::Policy::ControlStructures::LoopsRequireLabels>

Requires that loops containing C<next>, C<last>, or C<redo> carry
explicit labels, and that those break keywords reference a label.
Configurable via C<mode> (C<always>, C<nested>, C<max_lines>).

=item L<Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls>

Flags C<next>, C<last>, and C<redo> inside non-loop blocks: bare
C<{}> blocks, C<do {}>, C<eval {}>, anonymous subroutines, and
C<map>/C<grep>.  Configurable per-keyword (C<forbid>,
C<require_label>, C<allow>) and per-block-type (C<do_block>,
C<bare_block>).

=item L<Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct>

Flags C<goto LABEL> when the target label is inside a loop or block
construct.  This pattern is deprecated in Perl and will become a fatal
error in Perl 5.44 (see L<perldeprecation>).

=back

=head1 NAME

Perl::Critic::PolicyBundle::LoopsAndLabels - Bundle of policies for loop control flow and labels

=head1 INCLUDED POLICIES

=over

=item L<Perl::Critic::Policy::ControlStructures::LoopsRequireLabels|Perl::Critic::Policy::ControlStructures::LoopsRequireLabels>

Default severity: 3 (high).  Default theme: C<control>.

=item L<Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls|Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls>

Default severity: 1 (highest).  Default themes: C<bugs>, C<control>.

=item L<Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct|Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct>

Default severity: 3 (high).  Default theme: C<control>.

=back

=head1 AFFILIATION

This bundle is the distribution root for all three included policies.

=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the C<control> theme.  See the
L<Perl::Critic|Perl::Critic> documentation for how to configure each
policy individually.

Example F<perlcriticrc>:

    # Enable all policies from this bundle
    [ControlStructures::LoopsRequireLabels]
    mode = nested

    [ControlStructures::ProhibitBareBlockLoopControls]
    next        = forbid
    last        = require_label
    redo        = forbid

    [ControlStructures::ProhibitGotoIntoConstruct]

=head1 SEE ALSO

L<Perl::Critic>, L<perlfunc/next>, L<perlfunc/last>, L<perlfunc/redo>,
L<perlfunc/goto>, L<perldeprecation>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT

Copyright (c) 2026 Dean Hamstad.  All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
