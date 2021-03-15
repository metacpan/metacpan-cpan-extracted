#!/usr/bin/perl

use v5.10;

use strict;
use warnings;

use OPM::Validate;
use File::Basename;
use File::Glob qw(bsd_glob);
use Test::More;

my %opms = (
    good => [
        _get_files('good')
    ],
    bad  => [
        _get_files('bad')
    ]
);

for my $type ( sort keys %opms ) {
    for my $file ( @{ $opms{$type} || [] } ) {
        my $content = do { local ( @ARGV, $/ ) = $file; <> };
        my $success = eval {
            OPM::Validate->validate( $content );
            1;
        };

        is $@, '', 'no errors for ' . $file if $type eq 'good';
        ok( ($type eq 'good' ? $success : !$success), $file );
    }
}

done_testing();

sub _get_files {
    my ($subdir) = @_;

    my $dir   = dirname __FILE__;
    my @files = bsd_glob( $dir.'/'.$subdir.'/*.opm' );

    return @files;
}
