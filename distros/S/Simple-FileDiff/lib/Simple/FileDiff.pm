package Simple::FileDiff;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(union diff Intrsection);

our $VERSION = '1.09';

sub union
{
#------------------------------------------------------------
# Function: to Find the union of lines among two files
#------------------------------------------------------------
    my $Uni=shift   || help();
    my $file1=shift || help();
    my $file2=shift || help();
    open (IN1,"$file1") || die "cannot open $file1:$!\n";
    open (IN2,"$file2") || die "cannot open $file2:$!\n";
    if ($Uni eq 'or') {
    	my %out;
    	while(<IN1>) {chomp;$out{$_}=1;}
    	while(<IN2>) {chomp;$out{$_}=1;}
    	foreach (keys %out) {print "$_\n";}
    }
    else
    {
	help();
    }
close IN1;
close IN2;
}

sub diff
{
#------------------------------------------------------------
# Function: to Find the difference of lines among two files
#------------------------------------------------------------
    my $Diff=shift  || help();
    my $file1=shift || help();
    my $file2=shift || help();
    open (IN1,"$file1") || die "cannot open $file1:$!\n";
    open (IN2,"$file2") || die "cannot open $file2:$!\n";
    if ($Diff eq 'diff') {
    	my %in2;my %out;
    	while(<IN2>) {chomp;$in2{$_}=1;}
    	while(<IN1>) {chomp;$out{$_}=1 if(not exists $in2{$_});}
    	foreach (keys %out) {print "$_\n";}
    }
    else
    {
	help();
    }
close IN1;
close IN2;
}

sub Intrsection
{
#------------------------------------------------------------
# Function: to Find the intersection of lines among two files
#------------------------------------------------------------
    my $Intr=shift  || help();
    my $file1=shift || help();
    my $file2=shift || help();
    open (IN1,"$file1") || die "cannot open $file1:$!\n";
    open (IN2,"$file2") || die "cannot open $file2:$!\n";
    if ($Intr eq 'and') {
    	my %in1;my %out;
    	while(<IN1>) {chomp;$in1{$_}=1;}
    	while(<IN2>) {chomp;$out{$_}=1 if(exists $in1{$_});}
      	foreach (keys %out) {print "$_\n";}
    }
    else
    {
	help();
    }
close IN1;
close IN2;
}

sub help
{
	print "mydiff : compare two Files with \'[or/diff/and]\' options... \nUsage:\tmydiff [-h] :for help,info\n\tunion('or','file1.txt','file2.txt') : union of two sets\n\tdiff('diff','file1.txt','file2.txt');: elements in A but not in B\n\tIntrsection('and','file1.txt','file2.txt'); : intersection of two sets\n";
	exit 1;   
}

1;

__END__

=head1 NAME

Simple::FileDiff - Perl extension for finding [uniq/intersection/difference] of lines among two files

=head1 SYNOPSIS

    use Simple::FileDiff;
    my @file = union('or','file1.txt','file2.txt');

    use Simple::FileDiff;
    my @file = diff('diff','file1.txt','file2.txt');

    use Simple::FileDiff;
    my @file = Intrsection('and','file1.txt','file2.txt');

=head1 DESCRIPTION

Simple::FileDiff utility or module is very usefull for finding the lines of uniq/difference/intersection of two files,
and using this approach, able to find the fastest solutions of three functionalities [uniq/diff/and] for two common files.

=head1 AUTHOR

K.Kaavannan, <kaavannaniisc@gmail.com>

=head1 BUGS
 
Here, <<kaavannanwayis@solution4u.com>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by kaavannan Karuppaiyah

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
