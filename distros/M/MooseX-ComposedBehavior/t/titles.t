use strict;
use warnings;

use Test::More;

{
  package Regent;
  use Moose::Role;
  use t::Titles;

  requires 'gender';

  add_title {
    my ($self) = @_;
    my $which = $self->gender eq 'male' ? 'King' : 'Queen';
    return "$which of France"
  };
}

{
  package Janitor;
  use Moose::Role;
  use t::Titles;

  add_title { "Keeper of Grounds" };
  add_title { "Shearer of Shrubs" };
  add_title { "Wearer of the Key Ring" };
}

{
  package SomeGuy;
  use Moose;
  use t::Titles;

  with qw(Regent Janitor);

  sub gender { 'male' }
  sub job_title { 'Analyst/Developer' }
  sub education { 'Th.D.' }
}

my @titles = SomeGuy->new->title;
my $title  = SomeGuy->new->title;

my @want = (
  'Analyst/Developer',
  'Keeper of Grounds',
  'King of France',
  'Shearer of Shrubs',
  'Th.D.',
  'Wearer of the Key Ring',
);

is_deeply(
  [ sort @titles ],
  [ sort @want ],
  "got the right titles in list context",
);

subtest "all expected subtitles" => sub {
  plan tests => 0 + @want;

  for my $subtitle (@want) {
    like($title, qr{$subtitle}, "the title contains subtitle $subtitle");
  }
};

done_testing;
