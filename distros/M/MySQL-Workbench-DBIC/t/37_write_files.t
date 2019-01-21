#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture_stderr);
use FindBin ();
use File::Basename;
use Test::More;
use Test::LongString;

use lib dirname(__FILE__) . '/../';

use MySQL::Workbench::DBIC;
use t::MySQL::Workbench::DBIC::Table;

my $bin  = $FindBin::Bin;
my $file = $bin . '/test.mwb';

my $foo = MySQL::Workbench::DBIC->new(
    file                => $file,
    schema_name         => 'Schema',
    output_path         => 'HelloTest',
);

my $sub = $foo->can('_write_files');

{
    no warnings 'redefine';
    sub MySQL::Workbench::DBIC::make_path {
        my $dir = shift;
        return 0;
    };

    my $error;
    eval {
        my $got = $foo->$sub( MyTest => '' );
        like_string $got, qr/package Schema;/;
    } or $error = $@;

    like $error, qr/Cannot create directory HelloTest/;
}

{
    no warnings 'redefine';
    local *MySQL::Workbench::DBIC::make_path = sub {
        my $dir = shift;
        return 1;
    };

    my $error;
    eval {
        my $got = $foo->$sub( MyTest => '' );
        like_string $got, qr/package Schema;/;
    } or $error = $@;

    like $error, qr/Couldn't create/;
}

done_testing;
