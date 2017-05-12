#============================================================= -*-perl-*-
#
# t/autoform.t
#
# Template script testing the autoformat TT plugin.
#
# Written by Andy Wardley <abw@wardley.org>
#
# Copyright (C) 1996-2008 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use lib qw( ../lib );
use Template qw( :status );
use Template::Test;
use POSIX qw( localeconv );

$Template::Test::DEBUG    = 1;
$Template::Test::PRESERVE = 1;

# for testing known bug with locales that don't use '.' as a decimal
# separator - see TODO file.
# POSIX::setlocale( &POSIX::LC_ALL, 'sv_SE' );
POSIX::setlocale( &POSIX::LC_ALL, 'C' );

my $loc = localeconv;
my $dec = $loc->{decimal_point};

warn "decimal==$dec";

# sprintf rounding is somewhat unpredictable per-machine,
# so make our expectations align predictably.
my $rounded = sprintf('%0.2f', '123.545');

my $vars = { decimal => $dec, rounded => $rounded };

test_expect( \*DATA, { POST_CHOMP => 1 }, $vars );

#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
-- test --
[% global.text = BLOCK %]
This is some text which
I would like to have formatted
and I should ensure that it continues
for a reasonable length
[% END %]
[% USE Autoformat(left => 3, right => 20) %]
[% Autoformat(global.text) %]
-- expect --
  This is some text
  which I would like
  to have formatted
  and I should
  ensure that it
  continues for a
  reasonable length

-- test --
[% USE Autoformat(left=5) %]
[% Autoformat(global.text, right=30) %]
-- expect --
    This is some text which I
    would like to have
    formatted and I should
    ensure that it continues
    for a reasonable length

-- test --
[% USE Autoformat %]
[% Autoformat(global.text, 'more text', right=50) %]
-- expect --
This is some text which I would like to have
formatted and I should ensure that it continues
for a reasonable length more text

-- test --
[% USE Autoformat(left=10) %]
[% global.text | Autoformat %]
-- expect --
         This is some text which I would like to have formatted and I
         should ensure that it continues for a reasonable length

-- test --
[% USE Autoformat(left=5) %]
[% global.text | Autoformat(right=30) %]
-- expect --
    This is some text which I
    would like to have
    formatted and I should
    ensure that it continues
    for a reasonable length

-- test --
[% USE Autoformat %]
[% FILTER Autoformat(right=>30, case => 'upper') -%]
This is some more text.  OK!  There's no need to shout!
> quoted stuff goes here
> more quoted stuff
> blah blah blah
[% END %]
-- expect --
THIS IS SOME MORE TEXT. OK!
THERE'S NO NEED TO SHOUT!
> quoted stuff goes here
> more quoted stuff
> blah blah blah

-- test --
[% USE Autoformat %]
[% Autoformat(global.text, ' of time.') %]
-- expect --
This is some text which I would like to have formatted and I should
ensure that it continues for a reasonable length of time.

-- test --
[% USE Autoformat %]
[% Autoformat(global.text, ' of time.', right=>30) %]
-- expect --
This is some text which I
would like to have formatted
and I should ensure that it
continues for a reasonable
length of time.

-- test --
[% USE Autoformat %]
[% FILTER poetry = Autoformat(left => 20, right => 40) %]
   Be not afeard.  The isle is full of noises, sounds and sweet 
   airs that give delight but hurt not.
[% END %]
[% FILTER poetry %]
   I cried to dream again.
[% END %]

-- expect --
                   Be not afeard. The
                   isle is full of
                   noises, sounds and
                   sweet airs that give
                   delight but hurt not.

                   I cried to dream
                   again.

-- test --
Item      Description          Cost
===================================
[% form = BLOCK %]
<<<<<<    [[[[[[[[[[[[[[[   >>>>[% decimal %]<<
[% END -%]
[% USE Autoformat(form => form) %]
[% Autoformat('foo', 'The Foo Item', 123.545) %]
[% Autoformat('bar', 'The Bar Item', 456.789) %]
-- expect --
-- process --
Item      Description          Cost
===================================
foo       The Foo Item       [% rounded %]

bar       The Bar Item       456[% decimal %]79

-- test --
[% USE Autoformat(form => '>>>.<<', numeric => 'AllPlaces') %]
[% Autoformat(n) 
    FOREACH n = [ 123, 34.54, 99 ] +%]
[% Autoformat(987, 654.32) %]
-- expect --
-- process --
123[% decimal %]00
 34[% decimal %]54
 99[% decimal %]00

987[% decimal %]00
654[% decimal %]32
