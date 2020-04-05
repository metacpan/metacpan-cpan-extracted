#!/bin/perl

use Modern::Perl;
use strict;
use warnings;
use autodie qw(:all);
no indirect ':fatal';

use Carp;

use Readonly ;
use File::Basename;
use Smart::Comments;
use Try::Tiny;
use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;


use version ; our $VERSION = qv('1.0.1');
our $opt_inputfile;
my $inputfile             = $opt_inputfile;

open(my $file, "<", $inputfile)  or die "Could not open file $!";
#skip header
my @rows = <$file>;

chomp $rows[0] ;say $rows[0];
chomp $rows[1] ;say $rows[1];
#                  10      SQLCHAR 0       4       ""      10      modelintroduced                                 SQL_Latin1_general_CP1_CI_AS
my $matchExp = qr/^  (\d+)  (\s+SQLCHAR\s0\s+\d+\s+)  ("[^"]*")  (\s+)  (\d+)  (\s+)(\w+\s+SQL_Latin1_general_CP1_CI_AS\s*)  $/x;
for my $li (0 .. scalar(@rows) -3){
    chomp $rows[$li+2];#say $rows[$li+2];
    my @matches = ($rows[$li+2] =~ m/$matchExp/);
 #   warn Dumper @matches;
    my $firstadj  = length($matches[0]) - length($li+1);
    my $secondadj = length($matches[4]) - length($li+1);    
#warn $secondadj;
    say $li+1
   
#, " " ,$matches[0]     
        , ($firstadj>0?" "x$firstadj:"")
        , ($firstadj<0?substr($matches[1],-$firstadj):$matches[1])
    #    , $matches[2]
        , (($li != scalar(@rows) -3) ? '""' : '"\r\n"')
#        , ($secondadj>0?" "x$secondadj:"")
#        , (($li != scalar(@rows) -3) ? ($secondadj<0?substr('      ',-$secondadj):'      ') : ($secondadj<0?substr('  ',-$secondadj):'  '))
        , (($li != scalar(@rows) -3) ? '      ' : '  ')
        , $li+1
        , ($secondadj>0?" "x$secondadj:"")
        , ($secondadj<0?substr($matches[5],-$secondadj):$matches[5])
        , $matches[6];
    #my $col1 = 
}
#warn Dumper @rows;


exit ;

# #######################################################################################


END {
}

__DATA__


=head1 NAME


renumber-FormatFile.pl - ???????????????????

=head1 VERSION

1.0.1

=head1 USAGE

renumber-FormatFile.pl -i <formatfile> 


=head1 REQUIRED ARGUMENTS

=over

=item  -i[nput][file]   [=] <formatfile>

Specify format file

=for Euclid:
    formatfile.type:    readable


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

