use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/inc";

package Testing;
use Module::Pluggable::Dependency;
use Module::Pluggable::Dependency
    sub_name    => 'jobs',
    search_path => 'Plugin',
    instantiate => 'new',
    except      => 'Plugin::Ignore'
;

package main;
use Test::More tests => 2;

{
    my @plugins = Testing->plugins;
    is_deeply(
        \@plugins, 
        [ map { "Testing::Plugin::$_" } qw( A B C D E G Ignore F ) ],
        'simple use',
    );
}

{
    my @jobs = Testing->jobs;
    is_deeply(
        [ map { ref $_ } @jobs ], 
        [ map { "Plugin::$_" } qw( A B C D E G F ) ],
        'with various options',
    );
}
