#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny qw(capture_stderr);

use File::Basename;
use File::Spec;

use_ok 'MySQL::Workbench::Parser';

my $mwb = File::Spec->catfile(
    dirname( __FILE__ ),
    'lint.mwb',
);

my $parser = MySQL::Workbench::Parser->new( file => $mwb );

my $stderr = capture_stderr {
    $parser->tables
};

for my $re (
    qr/duplicate indexes/,
    qr/duplicate table names/,
    qr/duplicate column names in a table/,
) {
    like $stderr, $re, "$re";
}

done_testing();
