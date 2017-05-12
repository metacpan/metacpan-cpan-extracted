#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-selector.t
# Copyright 2012 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test Pod::Elemental::MakeSelector
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Test::More 0.88;            # done_testing
use Pod::Elemental::Element::Generic::Blank;
use Pod::Elemental::Element::Generic::Command;
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Pod5::Region;

use Pod::Elemental::MakeSelector;

plan tests => 21;

#---------------------------------------------------------------------
my %node = (
  blank => Pod::Elemental::Element::Generic::Blank->new(
    content => "\n",
  ),
  gh1AUTHOR => Pod::Elemental::Element::Generic::Command->new(
    command => 'head1',
    content => 'AUTHOR',
  ),
  h1AUTHOR => Pod::Elemental::Element::Pod5::Command->new(
    command => 'head1',
    content => 'AUTHOR',
  ),
  h1AUTHORS => Pod::Elemental::Element::Pod5::Command->new(
    command => 'head1',
    content => 'AUTHORS',
  ),
  h1AUTHORSCREDITS => Pod::Elemental::Element::Pod5::Command->new(
    command => 'head1',
    content => 'AUTHORS AND CREDITS',
  ),
  h1DESC => Pod::Elemental::Element::Pod5::Command->new(
    command => 'head1',
    content => 'DESCRIPTION',
  ),
  h2Notes => Pod::Elemental::Element::Pod5::Command->new(
    command => 'head2',
    content => 'Notes',
  ),
  h3About => Pod::Elemental::Element::Pod5::Command->new(
    command => 'head3',
    content => 'About',
  ),
  pHello => Pod::Elemental::Element::Pod5::Ordinary->new(
    content => 'Hello world!',
  ),
  pGoodbye => Pod::Elemental::Element::Pod5::Ordinary->new(
    content => 'Goodbye, all!',
  ),
  rCoverage => Pod::Elemental::Element::Pod5::Region->new(
    format_name => 'Pod::Coverage',
    is_pod      => 0,
    content     => '',
  ),
  rList => Pod::Elemental::Element::Pod5::Region->new(
    format_name => 'list',
    is_pod      => 1,
    content     => '',
  ),
);

my @nodes = sort keys %node;

#---------------------------------------------------------------------
sub test
{
  my $name     = shift;
  my $expected = shift;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $selector = make_selector(@_);

  my $got = join(' ', grep { $selector->($node{$_}) } @nodes);
  $expected =~ s/\s+/ /g; # Normalize spacing

  is($got, $expected, $name);
} # end test

#=====================================================================
test(author => 'gh1AUTHOR h1AUTHOR',
  -command => 'head1',
  -content => 'AUTHOR',
);

test(authorRE => 'gh1AUTHOR h1AUTHOR h1AUTHORS h1AUTHORSCREDITS',
  -command => 'head1',
  -content => qr/^AUTHOR/,
);

test(authorsOnly => 'h1AUTHORS',
  -command => 'head1',
  -content => 'AUTHORS',
);

test(authorOrAuthors => 'gh1AUTHOR h1AUTHOR h1AUTHORS',
  -command => 'head1',
  -or => [
    -content => 'AUTHOR',
    -content => 'AUTHORS',
  ],
);

test(contradiction => '',
  -command => 'head1',
  -content => 'AUTHOR',
  -content => 'AUTHORS',
);

test(multiOr => 'blank gh1AUTHOR h1AUTHOR h1AUTHORS',
  -or => [
    -and => [
      -command => 'head1',
      -or => [
        -content => 'AUTHOR',
        -content => 'AUTHORS',
      ],
    ],
    -blank,
  ],
);

test(allCommands => 'gh1AUTHOR h1AUTHOR h1AUTHORS h1AUTHORSCREDITS
                     h1DESC h2Notes h3About rCoverage rList',
  -command
);

test(head23 => 'h2Notes h3About',
  -command => [qw(head2 head3)],
);

test(head23re => 'h2Notes h3About',
  -command => qr/^head[23]/,
);

test(headNmixedArray => 'gh1AUTHOR h1AUTHOR h1AUTHORS h1AUTHORSCREDITS
                         h1DESC h2Notes h3About',
  -command => [ 'head1', qr/^head[23]/ ],
);

test(AmixedArray => 'gh1AUTHOR h1AUTHOR h1AUTHORS h1AUTHORSCREDITS h3About',
  -command => [ qr/^head[12]/, 'head3' ],
  -content => qr/^A/,
);

test(flat => 'blank pGoodbye pHello',
  -flat
);

test(blank => 'blank',
  -blank
);

test(hello => 'pHello',
  -flat,
  -content => qr/Hello/,
);

test(helloGoodbye => 'pGoodbye pHello',
  -flat,
  -content => [qr/Hello/, qr/Goodbye/ ],
);

test(allRegions => 'rCoverage rList',
  -region
);

test(listRegions => 'rList',
  -region => 'list',
);

test(podRegions => 'rList',
  -podregion,
);

test(podListRegions => 'rList',
  -podregion => 'list',
);

test(nonPodRegions => 'rCoverage',
  -nonpodregion,
);

test(nullArray => '',
  -command => [],
);

done_testing;

# Local Variables:
# compile-command: "prove --nocolor 10-selector.t"
# End:
