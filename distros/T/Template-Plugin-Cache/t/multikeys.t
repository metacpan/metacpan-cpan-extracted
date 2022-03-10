#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/multikeys.t
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

# Clear cache before beginning.
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
Hello [% name %]
[% END %]
[% SET name = 'World' %]
[% PROCESS cache_me %]

[% SET name = 'To-be-cached' %]
[% cache.proc(
    'template' => 'cache_me',
    'keys'     => {
        'Adele'     => 30,
        'Pearl Jam' => 'Ten'
        'Prince'    => 1999,
        'Rush'      => 2112,
        'Van Halen' => 5150,
        'Yes'       => 90125,
    },
    'ttl'      => 15
) %]
[% SET name = 'Other stuff' %]

[%# Now we should get back the "To-be-cached" version, because all the keys match. %]
[% cache.proc(
    'template' => 'cache_me',
    'keys'     => {
        # Intentionally different than the previous call.
        Adele       => '30',
        'Pearl Jam' => 'Ten'
        Prince      => '1999',
        Rush        => '2112',
        'Van Halen' => '5150',
        Yes         => '90125',
    },
    'ttl'      => 15
) %]

-- expect --
Hello World
Hello To-be-cached
Hello To-be-cached
