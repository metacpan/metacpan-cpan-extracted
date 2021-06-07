#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( eval 'use Test::Script::Run; 1' ) {
        plan skip_all => "please install Test::Script::Run to run these tests"
    }
}

plan tests => 18;

#######

use constant {
    APP => 'bin/sql-split',
    OSS => "\n--\n",
    OFS => "\n-- >>>*<<< --\n"
};

my @files = qw{
    t/data/create_table.sql
    t/data/create_table_and_trigger.sql
};

my $statements;
my $stderr;

my ($oss, $ofs);

#######

run_ok( APP, \@files, 'script invokation' );

#######

($stderr, $statements) = test_script( \@files );

ok( length($stderr) == 0, 'no warnings' );

cmp_ok (
    scalar(@$statements), '==', 2,
    'number of files found in output'
);

cmp_ok (
    scalar( @{ $statements->[0] } ), '==', 2,
    'number of statements in the first file'
);

cmp_ok (
    scalar( @{ $statements->[1] } ), '==', 6,
    'number of statements in the second file'
);

#######

$oss = "\n--*\n"; $ofs = "\n--***\n";

$statements = test_script(
    [ '--oss', $oss, '--ofs', $ofs, @files ],
    $oss, $ofs
);

cmp_ok (
    scalar(@$statements), '==', 2,
    'number of files found in output - custom sep'
);

cmp_ok (
    scalar( @{ $statements->[0] } ), '==', 2,
    'number of statements in the first file - custom sep'
);

cmp_ok (
    scalar( @{ $statements->[1] } ), '==', 6,
    'number of statements in the second file - custom sep'
);

#######

$oss = "\n--#\n"; $ofs = "\n--###\n";

($stderr, $statements) = test_script(
    [ '-s', $oss, '-f', $ofs, '-m', @files ],
    $oss, $ofs
);

cmp_ok (
    scalar(@$statements), '==', 2,
    'number of files found in output - empty statements'
);

cmp_ok (
    scalar( @{ $statements->[0] } ), '==', 3,
    'number of statements in the first file - empty statements'
);

cmp_ok (
    scalar( @{ $statements->[1] } ), '==', 7,
    'number of statements in the second file - empty statements'
);
#######

($stderr, $statements) = test_script(
    [ @files, 'non-existent.sql' ]
);

ok( length($stderr) > 0, 'file error warnings' );

cmp_ok (
    scalar(@$statements), '==', 2,
    'number of files found in output - file error'
);

cmp_ok (
    scalar( @{ $statements->[0] } ), '==', 2,
    'number of statements in the first file - file error'
);

cmp_ok (
    scalar( @{ $statements->[1] } ), '==', 6,
    'number of statements in the second file - file error'
);

#######

run_not_ok(
    APP,
    [ '--on-error=stop', @files, 'non-existent.sql' ],
    'script dies on file error'
);

#######

run_not_ok(
    APP,
    [ '-e', 'CONTINU', @files ],
    'script dies on wrong --on-error value'
);

#######

run_ok(
    APP,
    [ '--error', 'sToP', @files ],
    'script accepts case-insensitive --on-error value'
);

#######

sub test_script {
    my ($args, $oss, $ofs) = @_;
    
    $oss ||= OSS;
    $ofs ||= OFS;
    
    my $stdout;
    my $stderr;
    my @statements;
    
    run_script( APP, $args, \$stdout, \$stderr );
    
    push @statements, [ split /\Q$oss/, $_, -1 ]
        foreach split /\Q$ofs/, $stdout;
    
    return ( $stderr, \@statements )
}

#######
