#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use File::Basename ();

use Prancer::Core qw(config);
use Prancer::Plugin::Database qw(database);

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # this just returns a prancer object so we can get access to configuration
    # options and other awesome things like plugins.
    my $app = Prancer::Core->new("${root}/foobar.yml");

    # initialize the database
    Prancer::Plugin::Database->load();

    print "hello, goodbye. database = " . database . "\n";
    my $dbh = database;
    my $dbh2 = database('connection-name');

    return;
}

main(@ARGV) unless caller;

1;
