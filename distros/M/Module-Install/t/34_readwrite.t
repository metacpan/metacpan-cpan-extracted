use strict;
use warnings;
use Test::More;
use Module::Install::Admin;
use File::Temp qw/ tempdir /;
use autodie;

my $dir = tempdir;
chdir $dir;

open my $test, ">", "a";
binmode $test;
print $test "\n\r\n\r\r";
close $test;

my $c = Module::Install::_read( "a" );
is length $c, 5, "Module::Install::_read reads in binary mode";
Module::Install::_write( "b", $c );
is -s "b", 5, "Module::Install::Admin::_write writes in binary mode";
done_testing;
