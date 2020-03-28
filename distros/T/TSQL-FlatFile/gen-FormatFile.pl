#!/bin/perl

use Modern::Perl;
use strict;
use warnings;
use autodie qw(:all);
no indirect ':fatal';

use Carp;

use Ascii;
use Text::CSV ;
use Readonly ;
use List::MoreUtils qw(any) ;

use File::Basename;
use Smart::Comments;
use Try::Tiny;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use Data::Dumper;
use Regexp::Exhaustive qw/ exhaustive /;

use version ; our $VERSION = qv('1.0.0');
our $opt_asciifile;
our $opt_csvfile;
our $opt_linenumber;
our $opt_nodebug;

use Text::CSV;

my $csvfile = $opt_csvfile;
my $asciifile = $opt_asciifile;
my $linenumber = $opt_linenumber;
my $debug = !$opt_nodebug;

my $li=0;

my %csv_row;
my $ascii_row;

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $csvfile or die "csvfile: $!";
$csv->header($fh);
while ((my $row = $csv->getline_hr  ($fh)) && ($li++ < $linenumber)) {
#    warn Dumper $row;
    %csv_row = %$row;
    }
#warn Dumper %csv_row;
#warn Dumper keys %csv_row;
my @vals = sort { length($csv_row{$b}) <=> length($csv_row{$a}) } keys %csv_row;
 
close $fh;


$li=0;
open(my $afile, "<", $asciifile)  or die "Could not open file $!";
#skip header
my $row = <$afile>;
while (defined(my $row = <$afile> ) && ($li++ < $linenumber)) {
    chomp $row;
    $ascii_row = $row;
}
#warn Dumper $ascii_row;    
#print "done\n";

#find where vals in csv match ascii

#say $ascii_row;
my %positions ;
foreach my $v (@vals){
    my $val = $csv_row{$v}." *";
#    warn Dumper $val;
    
    $ascii_row  =~ m/(?>$val)/;
    $positions{$v} = [@-,@+];
#warn Dumper @-, @+;

    $ascii_row = $`. "^"x length($&) . $';
 #say $ascii_row;          
 #   warn Dumper $$_[0][0],$$_[1][0],$$_[2][0],$$_[3],$$_[4] for exhaustive($ascii_row => qr/(?>$val)/, qw[ @- $^R @+ $` $']); 
}

my @sortedkeys = sort { $positions{$a}[0] <=> $positions{$b}[0]} keys %positions;
{
  my $i=1;
  foreach my $k (@sortedkeys) {
    if ($debug) { say $k,"\t"x((55-length($k))/8), $positions{$k}[0],"\t", $positions{$k}[1]};
    $i++;
  }
}
if (!$debug) {say "12.0"};
if (!$debug) {say scalar(@sortedkeys)};
{
  my $i=1;
  foreach my $k (@sortedkeys) {
    if (!$debug) {say $i,"\t","SQLCHAR","\t","0","\t",$positions{$k}[1]-$positions{$k}[0],"\t",($i == scalar(@sortedkeys)) ? '"\r\n"':'""',"\t", $i,"\t", $k,"\t"x((55-length($k))/8),"SQL_Latin1_general_CP1_CI_AS"};
    $i++;
  }
}

#warn Dumper %positions ;
#foreach my $v (@val;
               
#my $topval = $csv_row{$vals[1]}." *";
#warn $topval;
 
#warn Dumper $$_[0][0],$$_[1][0],$$_[2][0],$$_[3],$$_[4], $$_[5] for exhaustive($ascii_row => qr/(?>$topval)/, qw[ @- $^R @+ $` $& $']); 
 
#warn Dumper $_ for exhaustive($ascii_row => qr/(?>$topval)/, qw[ @- $^R @+ $` $' $&]); 
 
## and write as CSV
#open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
#$csv->say ($fh, $_) for @rows;
#close $fh or die "new.csv: $!";


exit ;

# #######################################################################################


END {
}

__DATA__


=head1 NAME


gen-Ascii.pl - ???????????????????

=head1 VERSION

1.0.0

=head1 USAGE

gen-Ascii.pl -c <csvfile> 


=head1 REQUIRED ARGUMENTS

=over

=item  -c[sv][file]   [=] <csvfile>

Specify csv file

=for Euclid:
    csvfile.type:    readable


=back


=over

=item  -a[scii][file]   [=] <asciifile>

Specify ascii file

=for Euclid:
    asciifile.type:    readable


=back

=over

=item  -l[ine][number]   [=] <linenumber>

Specify linenumber

=for Euclid:
    linenumber.type:    int


=back



=head1 OPTIONS

=over

=item  --[no]debug

[Don't] generate detailed debug info

=for Euclid:
    false: --debug


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

