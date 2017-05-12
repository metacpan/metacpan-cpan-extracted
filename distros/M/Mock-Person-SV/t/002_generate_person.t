#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

BEGIN { use_ok 'Mock::Person' }

like(Mock::Person::name(
    country => 'sv',
    sex     => 'male',
  ),
  qr/\w+\s+\w+\s+\w+/, 'looks like a valid name',
);

like(Mock::Person::name(
    country => 'sv',
    sex     => 'female',
  ),
  qr/\w+\s+\w+\s+\w+/, 'looks like a valid name',
);
