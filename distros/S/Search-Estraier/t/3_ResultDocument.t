#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 12;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok('Search::Estraier') };

my $doc = {
	uri => 'file:///foo',
	attrs => {
		foo => 1,
		bar => 2,
	},
	snippet => 'none at all',
	keywords => "foo\tbar\tbaz\tboo",
};

dies_ok { new Search::Estraier::ResultDocument } "new without args";
ok(my $rdoc = new Search::Estraier::ResultDocument( %$doc ), 'new');
isa_ok($rdoc, 'Search::Estraier::ResultDocument');

cmp_ok($rdoc->uri, 'eq', $doc->{uri}, 'uri');

ok(my @attr_names = keys %{ $doc->{attrs} }, "attr_names from original");
ok(my @rdoc_attr_names = $rdoc->attr_names, "attr_names from rdoc");
ok(eq_set(\@rdoc_attr_names, \@attr_names), 'attr_names comparison');

foreach my $attr (keys %{ $doc->{attrs} }) {
	cmp_ok($rdoc->attr($attr), 'eq', $doc->{attrs}->{$attr}, "attr: $attr");
}

cmp_ok($rdoc->snippet, 'eq', $doc->{snippet}, 'snippet');
cmp_ok($rdoc->keywords, 'eq', $doc->{keywords}, 'keywords');
