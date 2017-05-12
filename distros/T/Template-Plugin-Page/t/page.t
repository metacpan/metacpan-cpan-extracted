#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/page.t
#
# Template script testing the Template side of the page plugin.
#
# Written by Leon Brocard <acme@astray.com>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ./lib ../blib );
use Template qw( :status );
use Template::Test;
$^W = 1;

$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;

test_expect(\*DATA, {
  INTERPOLATE => 1,
  POST_CHOMP => 1,
  PLUGIN_BASE => 'Template::Plugin',
});


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% USE page = Page(15, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
1 to 10

-- test --
[% USE page = Page(15, 10, 0) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
1 to 10

-- test --
[% USE page = Page(15, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
11 to 15

-- test --
[% USE page = Page(15, 10, 3) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
11 to 15

-- test --
[% USE page = Page(15, 10) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
1 to 10

-- test --
[% USE page = Page(8, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 8

-- test --
[% USE page = Page(9, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 9

-- test --
[% USE page = Page(10, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 10

-- test --
[% USE page = Page(11, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
1 to 10

-- test --
[% USE page = Page(12, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
1 to 10

-- test --
[% USE page = Page(9, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 9

-- test --
[% USE page = Page(10, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 10

-- test --
[% USE page = Page(11, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
11 to 11

-- test --
[% USE page = Page(19, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
11 to 19

-- test --
[% USE page = Page(20, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
11 to 20

-- test --
[% USE page = Page(21, 10, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..3,
11 to 20

-- test --
[% USE page = Page(1, 10, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 1

-- test --
[% USE page = Page(1, 1, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..1,
1 to 1

-- test --
[% USE page = Page(2, 1, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..2,
1 to 1

-- test --
[% USE page = Page(3, 1, 1) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..3,
1 to 1

-- test --
[% USE page = Page(3, 1, 2) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..3,
2 to 2

-- test --
[% USE page = Page(3, 1, 3) %]
[% page.first_page %]..[% page.last_page %],
[% page.first %] to [% page.last %]

-- expect --
1..3,
3 to 3

-- test --
[% USE page = Page(134, 10, 13) %]
Matches <b>[% page.first %] - [% page.last %]</b> of
        <b>[% page.total_entries %]</b> records.<BR>

Page <b>[% page.current_page %]</b> of
     <b>[% page.last_page %]</b><BR>

[% IF page.previous_page %]
  <a href="index.cgi?page=[% page.previous_page %]">Previous</a>
[% END %]&nbsp;&nbsp;&nbsp;

[% IF page.next_page %]
  <a href="index.cgi?page=[% page.next_page %]">Next</a>
[% END %]
-- expect --
Matches <b>121 - 130</b> of
        <b>134</b> records.<BR>

Page <b>13</b> of
     <b>14</b><BR>

  <a href="index.cgi?page=12">Previous</a>
&nbsp;&nbsp;&nbsp;

  <a href="index.cgi?page=14">Next</a>
-- test --
[% USE page = Page(15, 5, 2) %]
[% holidays = [ 1 .. 25 ] %]
[% visible_holidays = page.splice(holidays) %]
[% FOREACH holiday = visible_holidays %]
[% holiday -%]: Paris
[% END %]
-- expect --
6: Paris
7: Paris
8: Paris
9: Paris
10: Paris
