#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
use Test::DataDriven tests => 1;

package MyPlugin;

sub begin {
    my( $class, $block, $section, @v ) = @_;

    Test::DataDriven::stop_run;
}

Test::DataDriven->register
  ( plugin   => __PACKAGE__,
    tag      => 'stop' );

package main;

Test::DataDriven->run;

__DATA__

=== Run some actions
--- directory chomp
t/dummy
--- touch lines chomp
t/dummy/file1
t/dummy/file2
--- touch1
moo
--- touch2
too
--- mkpath lines chomp
t/dummy/dir
--- created lines chomp
dir/
file1
file2

=== Stop
--- stop

=== Never get there...
--- directory chomp
t/dummy
--- touch lines chomp
t/dummy/file7
t/dummy/file8
--- created lines chomp
file7
file8

