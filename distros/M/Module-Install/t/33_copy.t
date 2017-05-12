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

Module::Install::Admin->copy( "a", "b" );

is -s "b", 13, "Module::Install::Admin::copy copies in binary mode";
done_testing;
