# Substitution tests

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
    description => 'Mark up a single user',
    text        => 'RT @gavincarr Testing Regexp::Common::microsyntax',
    expected    => 'RT <span class="user">@gavincarr</span> Testing Regexp::Common::microsyntax',
    types       => [ qw(user) ],
  },
  {
    description => 'Mark up multiple users in slashtags',
    text        => 'Slashtag post /via @person1 by @person2 cc @person3',
    expected    => 'Slashtag post /via <span class="user">@person1</span> by <span class="user">@person2</span> cc <span class="user">@person3</span>',
    types       => [ qw(user) ],
  },
  {
    description => 'Mark up hashtags',
    text        => 'Hashtag post #athingofbeauty #fb',
    expected    => 'Hashtag post <span class="hashtag">#athingofbeauty</span> <span class="hashtag">#fb</span>',
    types       => [ qw(hashtag) ],
  },
  {
    description => 'Mark up grouptags',
    text        => 'Attention !freedom lovers !fsf ',
    expected    => 'Attention <span class="grouptag">!freedom</span> lovers <span class="grouptag">!fsf</span> ',
    types       => [ qw(grouptag) ],
  },
  {
    description => 'Mark up slashtags',
    text        => 'Slashtag post /via @person1',
    expected    => 'Slashtag post <span class="slashtag">/via @person1</span>',
    types       => [ qw(slashtag) ],
  },
  {
    description => 'Mark up *everything*',
    text        => '#testing Regexp::Common::microsyntax !perl /cc @cpantesters',
    expected    => '<span class="hashtag">#testing</span> Regexp::Common::microsyntax <span class="grouptag">!perl</span> <span class="slashtag">/cc <span class="user">@cpantesters</span></span>',
    # Note that user has to follow slashtag here or slashtag RE won't match
    types       => [ qw(hashtag grouptag slashtag user) ],
  },
);

my $count = shift @ARGV;

# Mark Test::More's output fh's as utf8
# http://www.effectiveperlprogramming.com/blog/1226
binmode Test::More->builder->$_(), ':encoding(UTF-8)' for qw(output failure_output);

#print encode('UTF-8', $RE{microsyntax}{slashtag}) . "\n";
my $c = 0;
for my $t (@tests) {
  my $got = $t->{text};
  for my $type (@{$t->{types}}) {
    # Would be nice if the following worked, but the $1 interpolation fails
#   my $got = $RE{microsyntax}{$type}->subs($t->{text}, '<span class="$type">$1</span>');
    $got =~ s|$RE{microsyntax}{$type}|<span class="$type">$1</span>|g;
  }
  is($got, $t->{expected}, $t->{description});

  last if $count and ++$c >= $count;
}

done_testing;

