use strict;
use warnings;

use Test::More;

{
  package CEO;
  use Moose::Role;
  use t::Titles;
  use t::TagProvider;

  sub job_title { 'CEO' }

  add_title { "Corporate Officer" };
  add_title { "Vice President of Calendars" };
  add_tags  { qw(corner-office washroom-key) };
}

{
  package Mason;
  use Moose::Role;
  use t::Titles;
  use t::TagProvider;

  sub education { 'Yale Grad' }

  add_title { "Grand High Templar" };
  add_tags  { qw(scottish) }
}

{
  package Masonite;
  use Moose;
  use t::Titles;
  use t::TagProvider;

  with qw(CEO Mason t::OneOffTags);

  add_title { 'Grand Vizier' };
  add_tags  { qw(funny-hat) };
}

is_deeply(
  [ sort Masonite->new->tags ],
  [ sort qw(corner-office washroom-key scottish funny-hat) ],
  "tags composed",
);

is_deeply(
  [ sort Masonite->new->title ],
  [
    sort(
      'CEO',
      'Yale Grad',
      'Corporate Officer',
      'Vice President of Calendars',
      'Grand Vizier',
      'Grand High Templar',
    )
  ],
  "titles composed"
);

done_testing;
