# Test with twitter-text-conformance user test data

use strict;
use Test::More;
use Test::Deep;
use YAML qw(LoadFile Dump);
use Encode qw(encode decode);
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Regexp::Common qw(microsyntax);

my $count = shift @ARGV;

# Mark Test::More's output fh's as utf8
# http://www.effectiveperlprogramming.com/blog/1226
binmode Test::More->builder->$_(), ':encoding(UTF-8)' for qw(output failure_output);

my ($data, $tests, $user_tests);

ok($data = LoadFile("$Bin/twitter-text-conformance/extract.yml"),
  'extract.yml loaded ok');
ok($tests = $data->{tests},
  'tests found');

# User tests
ok($user_tests = $tests->{mentions},
  'user tests found');
ok(ref $user_tests eq 'ARRAY' && @$user_tests > 0,
  'number of user tests > 0: ' . scalar @$user_tests);

#print encode('UTF-8', $RE{microsyntax}{user}) . "\n";
my $c = 4;
for my $t (@$user_tests) {
  my (@got, @got2);

  # Test elements
  while ($t->{text} =~ m/$RE{microsyntax}{user}{-keep => 1}/go) {
    push @got, substr($1, 1);
    push @got2, $3;
    like($2, qr/^[@＠]$/, '$2 is an at sign');
  }
  cmp_deeply(\@got,  $t->{expected}, "$t->{description} via \$1");
  cmp_deeply(\@got2, $t->{expected}, "$t->{description} via \$3");

  # Test one-shot (no keep)
  @got = $t->{text} =~ m/$RE{microsyntax}{user}/og;
  cmp_deeply(\@got,  [ map { "\@$_" } @{$t->{expected}} ],
    "$t->{description} (no keep)");

  last if $count and ++$c >= $count;
}

done_testing;

