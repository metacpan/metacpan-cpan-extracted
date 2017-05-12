#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);

use Spreadsheet::DataToExcel;

die "Usage: perl $0 file_for_the_dump.xls\n"
    unless @ARGV;

my $dump = Spreadsheet::DataToExcel->new;

$dump->file( shift );
$dump->data([]);

print "Enter column names separated by spaces:\n";
push @{ $dump->data }, [ split ' ', <STDIN> ];

{
    print "Enter a row of data separated by spaces or hit CTRL+D to dump:\n";
    $_ = <STDIN>;
    defined or last;
    push @{ $dump->data }, [ split ' ' ];
    redo;
}

$dump->dump( undef, undef, { text_wrap => 0 } )
    or die "Error: " . $dump->error;

print "Done! See " . $dump->file . " file\n";