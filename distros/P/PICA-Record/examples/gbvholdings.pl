#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

gbvholdings.pl - get holdings in GBV union catalog

=cut

use PICA::Source;
use Getopt::Long;
use Pod::Usage;

my $VERSION = '0.2';
my $gvk = PICA::Source->new( SRU => "http://gso.gbv.de/sru/DB=2.1" );

my ($ppn, $iln);
my ($man, $help, $verbose, $quiet);

GetOptions(
    "quiet" => \$quiet,            # suppress status messages
    "help|?" => \$help,            # show help message
    "man" => \$man,                # full documentation
    "verbose" => \$verbose,
    "ppn=s" => \$ppn,
    "iln=s" => \$iln,
) or pod2usage(2);
pod2usage(1) if $help or not ($ppn or @ARGV);
pod2usage(-verbose => 2) if $man;

$ppn = shift unless $ppn;
my @ppns = grep { $_ } map { /^\s*(gvk:ppn:)?([0-9]+[0-9X])\s*/i ? $2 : '' }
           split(",", $ppn||"" );

foreach my $ppn (@ppns) {
    my $record = $gvk->getPPN( $ppn );
    if ( ! $record ) {
        print STDERR "PPN $ppn not found!\n";
        next;
    }
    my $title = $record->sf('021A$a');
    foreach my $item ( $record->holdings( $iln  ) ) {
        my $count = $item->sf('209A(/..)?$e');
        $count = 1 unless $count > 1;
        my $callnum = $item->sf('209A/01$a');
        
        print "EPN: " . $item->epn . "\n";
        print "title: " . $title . "\n";
        print "count: " . $count . "\n";
        print "callnum: $callnum\n";
        # ...
        print "\n";
    }
}

=head1 SYNOPSIS

gbvholdings.pl [options] [PPNs]

=head1 OPTIONS

 -help          brief help message
 -man           full documentation with examples
 -ppn PPN       PPN(s) of the PICA record to get (comma-seperated)
 -iln ILN       ILN of a library to get holdings from

=head1 DESCRIPTION

This script gets items with known PPN from GBV union catalog and selects the
holdings of one or all libraries. For each ...

=head1 EXAMPLES

=over 4

=item gbvholdings.pl -iln 69 340791195

Get holdings of record 340791195 by library 69 

=item gbvholdings.pl 340791195

Get all holdings of record 340791195

=back

=head1 TODO

Support multiple ILNs.

=head1 AUTHOR

Jakob Voss C<< jakob.voss@gbv.de >>
