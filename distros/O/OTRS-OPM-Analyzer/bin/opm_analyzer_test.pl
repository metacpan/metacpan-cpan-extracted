#!/usr/bin/perl

# PODNAME: opm_analyzer_test.pl
# ABSTRACT: a short script to test the analyzer

use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Temp;
use FindBin;

use lib $FindBin::Bin . '/../lib';
use OTRS::OPM::Analyzer;

use Data::Dumper;

my $file     = $ARGV[0];

if ( !$file || !-f $file ) {
    print "$0 <opm_file>";
    exit;
}

my $config   = $FindBin::Bin . '/../conf/base.yml';
my $analyzer = OTRS::OPM::Analyzer->new(
    configfile => $config,
    roles => {
        opm => [qw/Dependencies/],
    },
);
my $results  = $analyzer->analyze( $file );

print Dumper $results;

__END__

=pod

=encoding UTF-8

=head1 NAME

opm_analyzer_test.pl - a short script to test the analyzer

=head1 VERSION

version 0.06

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
