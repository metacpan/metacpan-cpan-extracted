#!/usr/bin/perl -w
use strict;
use Test::More tests=>13;
use Test::Deep;
use Test::NoWarnings;
use Module::ExtractUse;

# test testfile
{
    my $p=Module::ExtractUse->new;
    my @used=$p->extract_use($0)->array;
    cmp_deeply(\@used,
	       bag(qw(strict Test::More Test::Deep Test::NoWarnings Module::ExtractUse)),
	       'modules used in this test script'
	      );
    @used=$p->extract_use($0)->array_in_eval;
    cmp_deeply(\@used,
	       [],
	       'optional modules used in this test script'
	      );
    @used=$p->extract_use($0)->array_out_of_eval;
    cmp_deeply(\@used,
	       bag(qw(strict Test::More Test::Deep Test::NoWarnings Module::ExtractUse)),
	       'mandatory modules used in this test script'
	      );
}

# test Module::ExtractUse
{
    my $p=Module::ExtractUse->new;
    $p->extract_use('lib/Module/ExtractUse.pm');
    cmp_deeply($p->arrayref,
	       bag(qw(strict warnings Pod::Strip Parse::RecDescent Module::ExtractUse::Grammar Carp 5.008)),
	       'modules used in this Module::ExtractUsed');
    cmp_deeply([$p->arrayref_in_eval],
	       [],
	       'optional modules used in this Module::ExtractUsed');
    cmp_deeply($p->arrayref_out_of_eval,
	       bag(qw(strict warnings Pod::Strip Parse::RecDescent Module::ExtractUse::Grammar Carp 5.008)),
	       'mandatory modules used in this Module::ExtractUsed');

    my $used=$p->used;
    is($used->{'strict'},1,'strict via hash lookup');

    is($p->used('strict'),1,'strict via used method');

    my $used_in_eval=$p->used_in_eval;
    is(!$used_in_eval->{'strict'},1,'strict via in-eval hash lookup');

    is(!$p->used_in_eval('strict'),1,'strict via used_in_eval method');

    my $used_out_of_eval=$p->used_out_of_eval;
    is($used_out_of_eval->{'strict'},1,'strict via out-of-eval hash lookup');

    is($p->used_out_of_eval('strict'),1,'strict via used_out_of_eval method');

}

