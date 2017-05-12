#!perl
use strict;
use warnings;

# PURPOSE:
# test that we eliminate =cut elements in favor of Pod5::Nonpod

use Test::More;
use Test::Deep;
use Test::Differences;

use Pod::Eventual::Simple;
use Pod::Elemental::Objectifier;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Document;
use Pod::Elemental::Selectors '-all';

my $str = do { local $/; <DATA> };

my $events   = Pod::Eventual::Simple->read_string($str);
my $elements = Pod::Elemental::Objectifier->objectify_events($events);

my $document = Pod::Elemental::Document->new({
  children => $elements
});

Pod::Elemental::Transformer::Pod5->transform_node($document);

is(scalar(grep { s_command('cut', $_) } @{ $document->children }), 0, 'no =cut cmds');

# XXX: HORRIBLE grep predicate -- rjbs, 2009-10-20
my @top_nonpod = grep { ref =~ /Nonpod$/ } @{ $document->children };

is(@top_nonpod, 1, "we have one top-level nonpod element");
ok($top_nonpod[0] == $document->children->[5], "...it's the 6th element");
like($top_nonpod[0]->content, qr{\QNonpod 2.0}, "...and the one we expect");

my $region = $document->children->[2];
isa_ok($region, 'Pod::Elemental::Element::Pod5::Region', '3rd element');
{
# XXX: HORRIBLE grep predicate -- rjbs, 2009-10-20
  my @reg_nonpod = grep { ref =~ /Nonpod$/ } @{ $region->children };

  is(@reg_nonpod, 1, "we have one 2nd-level nonpod element");
  ok($reg_nonpod[0] == $region->children->[1], "...it's the 2nd element");
  like(
    $reg_nonpod[0]->content,
    qr{Nonpod 1.0\n.+Continued}sm,
    "...and the one we expect",
  );
}

done_testing;

__DATA__
=pod

=head1 DESCRIPTION

Ordinary 1.1

=begin nonpod

Data 2.1

=cut
Nonpod 1.0
Nonpod 1.0 Continued
=head1 Nonpod Header

Data 2.2

=end nonpod

=head1 Outer Header

Ordinary 1.2

=cut
Nonpod 2.0

=pod

Ordinary 1.3

=head2 Subheader

Complete.

=cut
