#!/usr/bin/env perl
# use Test::More tests => 6;

use Test::More;
use Telegram::CamshotBot::Util qw(random_caption first_existing_file first_existing_variable fev);

my $a = [
  "Common sense is not so common",
  "Just do it",
  "We make porn here",
  "Learn by doing"
];

my $rand = random_caption $a;
my $r = grep { $_ eq $rand } @$a;
ok($r);

ok ('a' eq first_existing_variable(undef, '', 'a') );
ok ('a' eq fev(undef, '', 'a') );

done_testing();
