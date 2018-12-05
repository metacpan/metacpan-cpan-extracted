#!/usr/bin/env perl

use v5.20;

use strict;
use warnings;

use Test::More;
use OData::QueryParams::DBIC::FilterUtils qw(parser);

is_deeply OData::QueryParams::DBIC::FilterUtils::predicate(undef), { operator => 'eq', subject => undef, value => undef };
is_deeply OData::QueryParams::DBIC::FilterUtils::predicate(0), { operator => 'eq', subject => undef, value => undef };

my $parser = parser;
is $parser->(undef), undef;
is $parser->(''), undef;
is $parser->(' '), undef;

done_testing();
