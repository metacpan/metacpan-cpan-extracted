#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Test::More;
use Test::CheckManifest;

# create a directory and a file
my $sub = Test::CheckManifest->can('_validate_args');
ok $sub;

my $default = {
    filter  => [],
    exclude => [ qw!/blib /_blib! ],
    bool    => 'or',
};

is_deeply [ $sub->( [], "hallo" ) ],                    [ $default, "hallo" ], 'Empty Arrayref';
is_deeply [ $sub->( { exclude => {} }, "hallo" ) ],     [ $default, "hallo" ], 'exclude => {}';
is_deeply [ $sub->( { exclude => [] }, "hallo" ) ],     [ $default, "hallo" ], 'exclude => []';
is_deeply [ $sub->( { exclude => 'test' }, "hallo" ) ], [ $default, "hallo" ], 'exclude => "test"';

is_deeply [ $sub->( { bool => {} }, "hallo" ) ],        [ $default, "hallo" ], 'bool => {}';
is_deeply [ $sub->( { bool => 'or' }, "hallo" )],       [ $default, "hallo" ], 'bool => "or"';
is_deeply [ $sub->( { bool => 'and' }, "hallo" )],      [ { %$default, bool => 'and' }, "hallo" ], 'bool => "and"';
is_deeply [ $sub->( { bool => '1' }, "hallo" )],        [ $default, "hallo" ], 'bool => "1"';

is_deeply [ $sub->( { filter => [] }, "hallo" ) ],          [ $default, "hallo" ], 'filter -> arrayref';
is_deeply [ $sub->( { filter => {} }, "hallo" ) ],          [ $default, "hallo" ], 'filter -> empty hashref';
is_deeply [ $sub->( { filter => 'test' }, "hallo" ) ],      [ $default, "hallo" ], 'filter -> string';
is_deeply [ $sub->( { filter => [ 'hallo' ] }, "hallo" ) ], [ $default, "hallo" ], 'filter -> no regex';

{
    my $error;
    eval {
        $sub->( { exclude => ['testing'] } );
        1;
    } or do {
        $error = $@;
    };

    like $error, qr/path in excluded array must be "absolute"/, 'relative paths';
}

done_testing();
