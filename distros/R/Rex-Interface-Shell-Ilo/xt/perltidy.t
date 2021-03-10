#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

our $VERSION = '9999';

use File::Find;
use Test::More;
use Test::PerlTidy;

if ( !$ENV{AUTHOR_TESTING} ) {
    plan skip_all => 'these tests are for testing by the author';
}

my @files_to_exclude = qw(Makefile.PL .build blib);
my $xt_author_dir    = File::Spec->join( 'xt', 'author' );

find(
    sub {
        return if $_ eq q(.);
        return if $_ eq 'perltidy.t';

        my $filename = File::Spec->join( $xt_author_dir, $_ );

        push @files_to_exclude, qr{\Q$filename\E}msx;
    },
    $xt_author_dir,
);

run_tests( exclude => \@files_to_exclude );
