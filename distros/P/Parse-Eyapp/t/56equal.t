#!/usr/bin/perl -w
use strict;
use Test::More tests=>3;
use_ok qw(Parse::Eyapp::Node) or exit;

my $string1 = 'ASSIGN(VAR(TERMINAL))';
my $string2 = 'ASSIGN(VAR(TERMINAL))';
my $t1 = Parse::Eyapp::Node->new($string1, sub { my $i = 0; $_->{n} = $i++ for @_ });
my $t2 = Parse::Eyapp::Node->new($string2);

# Without attributes
ok($t1->equal($t2), 'Not considering attributes: Equal');

# With attributes
ok(!$t1->equal($t2, n => sub { return $_[0] == $_[1] }), "Considering attributes: Not Equal");
