#!/usr/bin/perl -w

use NCBIx::eUtils::GeneAliases;

my $ga = NCBIx::eUtils::GeneAliases->new();

my @aliases = $ga->get_aliases("CYP46A1");

foreach my $alias ( @aliases ) {
	print " ALIAS: $alias \n";
}

exit;

