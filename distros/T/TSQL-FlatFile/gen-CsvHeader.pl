#!/bin/perl

use Modern::Perl;
use strict;
use warnings;
use autodie qw(:all);
no indirect ':fatal';

use Carp;

use Text::CSV ;

use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;
use Text::CSV;
use File::Basename;

use version ; our $VERSION = qv('1.0.1');

our $opt_inputfile;
my $inputfile             = $opt_inputfile;

my ($filename,$path,$suffix) = fileparse($inputfile,(".csv"));
(my $schema = $1) if $path =~ m!\\([^\\]+)\\$!;
#warn $path;
#warn Dumper $schema;
my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $inputfile or die "inputfile: $!";

my $ccount=0;
my $maxccount=0;
my $minccount=99999999;
my $li = 0;
while ((my $row = $csv->getline ($fh)) && ($li++ <= 100) ) {
    $ccount = scalar(@$row);
    $maxccount = $ccount if $maxccount < $ccount;
    $minccount = $ccount if $minccount > $ccount;
    }
close $fh;

my $first=1;
my $header = "";
if (($minccount == $maxccount) ) {
    {
        foreach my $i ( 1 .. $minccount) {
            $header .= ($first ? "" : ",")."c${i}";
            $first=0;
        }
    }
say $header;
}


exit ;

# #######################################################################################


END {
}

__DATA__


=head1 NAME


gen-CsvHeader.pl - ???????????????????

=head1 VERSION

1.0.1

=head1 USAGE

gen-CsvHeader.pl -i <inputfile>



=head1 REQUIRED ARGUMENTS

=over

=item  -i[nput][file]   [=] <inputfile>

Specify format file

=for Euclid:
    inputfile.type:    readable


=back



=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2020, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

