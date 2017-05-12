#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/cache.t
#
# Template script testing the Template side of the page plugin.
#
# Written by Perrin Harkins <perrin@elem.com>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use lib qw( ./lib ../blib );
use Template qw( :status );
use Template::Test;
use Cache::FileCache;
$^W = 1;

$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;

# clear cache before beginning
my $cache = Cache::FileCache->new();
$cache->Clear();

test_expect(\*DATA, {
  INTERPOLATE => 1,
  POST_CHOMP => 1,
  PLUGIN_BASE => 'Template::Plugin',
});


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% USE cache = Cache %]
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% cache.proc(
             'template' => 'cache_me',
             'ttl' => 15
             ) %]
[% change_me %]
-- expect --
Hello
after
-- test --
[% USE cache = Cache %]
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% cache.inc(
             'template' => 'cache_me',
             'ttl' => 15
             ) %]
[% change_me %]
-- expect --
Hello
before
-- test --
[% USE cache = Cache %]
[% BLOCK cache_me %]
 Hello [% name %]
[% END %]
[% SET name = 'Suzanne' %]
[% cache.proc(
             'template' => 'cache_me',
             'keys' => {'name' => name},
             'ttl' => 15
             ) %]
[% SET name = 'World' %]

[% cache.proc(
             'template' => 'cache_me',
             'keys' => {'name' => name},
             'ttl' => 15
             ) %]

-- expect --
 Hello Suzanne
 Hello World
