#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::DelimitedWriter;

sub testFS {
    my ($fs, $expected, $name) = @_;
    
    my $file = "t/data/76-delimited-writer.dat";
    my $writer = Net::Amazon::MechanicalTurk::DelimitedWriter->new(
        file => $file,
        fieldSeparator => $fs
    );

    $writer->write(qw{ Name Age Description });
    $writer->write([ 'Bob', 300, 'Bob needs a comma (,)' ]);
    $writer->write([ 'Bob2', 15, "Bob needs a newline (\n)", 9 ]);
    $writer->write();
    $writer->write("Bob wants a tab here ->\t<-", "and a comma here ->,<-");
    $writer->write("How about a quote? [\"]");
    $writer->write(1,2,3);
    $writer->close;

    my $in = IO::File->new($file, "r");
    my $text = '';
    while (my $line = <$in>) {
        $text .= $line;
    }
    $in->close;
    unlink($file);
    
    is($text, $expected, $name);
}


my $expectedCSV = <<END_TXT;
Name,Age,Description
Bob,300,"Bob needs a comma (,)"
Bob2,15,"Bob needs a newline (
)",9

Bob wants a tab here ->\t<-,"and a comma here ->,<-"
"How about a quote? [""]"
1,2,3
END_TXT
chomp($expectedCSV);

my $expectedTab = <<END_TXT;
Name\tAge\tDescription
Bob\t300\tBob needs a comma (,)
Bob2\t15\t"Bob needs a newline (
)"\t9

"Bob wants a tab here ->\t<-"\tand a comma here ->,<-
"How about a quote? [""]"
1\t2\t3
END_TXT
chomp($expectedTab);

testFS(",", $expectedCSV, "CSV Delimited Write");
testFS("\t", $expectedTab, "Tab Delimited Write");

