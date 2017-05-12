# slashtag tests

use strict;
use Test::More;
use Test::Deep;
use Encode qw(encode decode);
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Regexp::Common qw(microsyntax);

my @tests = (
  {
    description => 'Single slashtag, at end',
    text        => 'Slashtag post /via @person1',
    expected    => [ '/via @person1' ],
  },
  {
    description => 'Single slashtag, not at end',
    text        => 'Slashtag post /via @person1 #foobar',
    expected    => [ '/via @person1' ],
  },
  {
    description => 'Multiple slashtags at end',
    text        => 'Slashtag post /via @person1 by @person2 cc @person3',
    expected    => [ '/via @person1', 'by @person2', 'cc @person3' ],
  },
  {
    description => 'Multiple slashtags, multiple user slashtag',
    text        => 'Slashtag post /via @person1 by @person2 cc @person3 @person4',
    expected    => [ '/via @person1', 'by @person2', 'cc @person3 @person4' ],
  },
  {
    description => 'Multiple slashtags at end (all slashed)',
    text        => 'A (strictly incorrect) slashtag post. /via @person1 /by @person2 /cc @person3',
    expected    => [ '/via @person1', '/by @person2', '/cc @person3' ],
  },
  {
    description => 'Multiple slashtags at end, without the initial slash',
    text        => 'Slashtag post without the initial slash via @person1 by @person2 cc @person3',
    expected    => [ 'via @person1', 'by @person2', 'cc @person3' ],
  },
);

my $count = shift @ARGV;

# Mark Test::More's output fh's as utf8
# http://www.effectiveperlprogramming.com/blog/1226
binmode Test::More->builder->$_(), ':encoding(UTF-8)' for qw(output failure_output);

#print encode('UTF-8', $RE{microsyntax}{slashtag}) . "\n";
my $c = 0;
for my $t (@tests) {
  my (@got, @slashtags, @users);

  # Test elements
  while ($t->{text} =~ m/$RE{microsyntax}{slashtag}{-keep => 1}/go) {
    push @got, $1;
    push @slashtags, $2;
    push @users, $3;
  }
  cmp_deeply(\@got,       $t->{expected}, "$t->{description} via \$1");

  my (@expected_slashtags, @expected_users);
  for (@{$t->{expected}}) {
    my ($s, $u) = split / /, $_, 2;
    push @expected_slashtags, $s;
    push @expected_users, $u;
  }
  cmp_deeply(\@slashtags, \@expected_slashtags, "$t->{description} slashtags");
  cmp_deeply(\@users,     \@expected_users, "$t->{description} users");

  # Test one-shot (no keep)
  @got = $t->{text} =~ m/$RE{microsyntax}{slashtag}/og;
  cmp_deeply(\@got, $t->{expected}, "$t->{description} (no keep)");

  last if $count and ++$c >= $count;
}

done_testing;

