# Test with twitter-text-conformance hashtag test data (munged for groups)

use strict;
use Test::More;
use Test::Deep;
use YAML qw(LoadFile Dump);
use Encode qw(encode decode);
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Regexp::Common qw(microsyntax);

my @extra_tests = (
  {
    text        => 'post with !multiple !grouptags in middle',
    expected    => [ qw(multiple grouptags) ],
    description => 'Multiple grouptags in middle',
  },
  {
    text        => 'post ending with !multiple !grouptags',
    expected    => [ qw(multiple grouptags) ],
    description => 'Multiple grouptags at end',
  },
);

my $count = shift @ARGV;

# Mark Test::More's output fh's as utf8
# http://www.effectiveperlprogramming.com/blog/1226
binmode Test::More->builder->$_(), ':encoding(UTF-8)' for qw(output failure_output);

my ($data, $tests, $hashtag_tests);

ok($data = LoadFile("$Bin/twitter-text-conformance/extract.yml"),
  'extract.yml loaded ok');
ok($tests = $data->{tests},
  'tests found');

# Hashtag tests
ok($hashtag_tests = $tests->{hashtags},
  'hashtag tests found');
ok(ref $hashtag_tests eq 'ARRAY' && @$hashtag_tests > 0,
  'number of hashtag tests > 0: ' . scalar @$hashtag_tests);

push @$hashtag_tests, @extra_tests;

#print encode('UTF-8', $RE{microsyntax}{hashtag}) . "\n";
my $c = 4;
for my $t (@$hashtag_tests) {
  my (@got, @got2);

  # Quick and dirty - munge hashes to ! to reuse hashtag tests
  $t->{text} =~ s/[#＃]/!/g;
  $t->{description} =~ s/hash/group/g;

  # Test elements
  while ($t->{text} =~ m/$RE{microsyntax}{grouptag}{-keep => 1}/go) {
#   push @got, substr($1, 1);
    push @got, substr("$1", 1); # TODO: why does this fail if $1 is unquoted?!
    push @got2, $3;
    is($2, '!', '$2 is an exclamation');
  }
  cmp_deeply(\@got,  $t->{expected}, "$t->{description} via \$1");
  cmp_deeply(\@got2, $t->{expected}, "$t->{description} via \$3");

  # Test one-shot (no keep)
  @got = $t->{text} =~ m/$RE{microsyntax}{grouptag}/og;
  cmp_deeply(\@got,  [ map { "!$_" } @{$t->{expected}} ],
    "$t->{description} (no keep)");

  last if $count and ++$c >= $count;
}

done_testing;

