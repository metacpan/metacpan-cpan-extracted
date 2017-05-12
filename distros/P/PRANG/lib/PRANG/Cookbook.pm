
package PRANG::Cookbook;
$PRANG::Cookbook::VERSION = '0.18';
use Moose::Role;
use PRANG::Graph;

sub xmlns { }

with 'PRANG::Graph', 'PRANG::Cookbook::Node';

1;

=pod

=head1 NAME

PRANG::Cookbook - Examples of recipes which you can use with PRANG.

=head1 DESCRIPTION

The PRANG::Cookbook is a series of recipes showing various PRANG features. Most
recipes are small and self-explanatory but the general layout of each series
shows firstly a simple example with explanations followed by further
enhancements.

Each component of PRANG has a man page describing it, and collectively
these form the PRANG manual.  However, the cookbook is designed to
give quick examples to get up to speed with what you need to know to
effectively use PRANG.

The manual pages for the cookbook do not contain the content; see the
actual source for the examples.

=head1 RECIPES

=head2 Basic PRANG

This recipe series gives you a good overview of PRANG's capabilites starting
with simple XML elements and attributes.

=over 4

=item L<PRANG::Cookbook::Note>

Shows a simple example of a note which requires some elements and adds
some optional elements later on. Also shows how to use attributes with
some basic validation.

=back

=head2 Intermediate PRANG

This recipe series (ie, L<PRANG::Cookbook>) gives you a good overview
of some of advanced of PRANG's capabilites. Showing how to do lists of
nodes and then lists of any of a number of different nodes.

=over 4

=item L<PRANG::Cookbook::Library>

shows a simple library which has one book in it, then any number of
books. Adds to this the fact that the library holds CDs too, so this
is made generic such that it holds items, where each item can be a
book or a CD.

=back

=head2 Advanced PRANG

The CPAN releases L<XML::SRS> and L<XML::EPP> are implementations of
real-world XML standards using PRANG.  The first versions of these
will be released shortly after the inaugral PRANG release.

=head1 AUTHOR

Andrew Chilton, E<lt>andy@catalyst dot net dot nzE<gt>

Edited by Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by New Zealand Registry
Services, http://www.nzrs.net.nz/

The work is being carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2009, NZ Registry Services.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

This license applies to all Cookbook files shipped with PRANG.

=cut
