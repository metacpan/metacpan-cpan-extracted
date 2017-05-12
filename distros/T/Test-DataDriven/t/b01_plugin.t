#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use DummyT;
use Test::DataDriven tests => 1;

package MyPlugin;

sub run {
    my( $class, $block, $section, @v ) = @_;

    chomp $v[0];
    Dummy::touch( 't/dummy/' . $v[0] );
}

Test::DataDriven->register
  ( plugin   => __PACKAGE__,
    tag_re   => qr/^touch\d/ );

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
moo
too
