#!/usr/bin/perl -w

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
[% SET data = [1 .. 10]; %]
[% USE page = Pagination(data, 1, 3) %]
[% page.first_page %]

-- expect --
1

-- test --
[% SET data = [1 .. 10]; %]
[% USE page = Pagination(data, 1, 3) %]
[% page.first_page %]..[% page.last_page +%]
[% page.first %] to [% page.last +%]
[% page.page_data.join(",") %] 

-- expect --
1..4
1 to 3
1,2,3

-- test --
[% SET data = [1 .. 10]; %]
[% USE page = Pagination(data, 2, 3) %]
[% page.page_data.join(",") %] 

-- expect --
4,5,6

-- test --
[% SET data = [1 .. 30]; %]
[% USE page = Pagination(data, 2) %]
[% page.page_data.join(",") %] 

-- expect --
11,12,13,14,15,16,17,18,19,20

-- test --
[% SET data = [1 .. 30]; %]
[% USE page = Pagination(data) %]
[% page.page_data.join(",") %] 

-- expect --
1,2,3,4,5,6,7,8,9,10

