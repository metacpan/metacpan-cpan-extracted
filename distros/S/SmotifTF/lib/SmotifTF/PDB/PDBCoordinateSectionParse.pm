package SmotifTF::PDB::PDBCoordinateSectionParse;
use strict;
use warnings;
BEGIN {
	use Exporter ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = "0.01";
	#$DATE    = "02-19-2015";
        @ISA = qw(Exporter);
	
        # name of the functions to export
	@EXPORT_OK = qw( 
		GetPDBAtomRecordFields
		GetPDBAnisouRecordFields
		GetPDBTerRecordFields
		GetPDBHetatmRecordFields
	);

	@EXPORT  = qw(

        );  # symbols to export on request
}

use Data::Dumper;
use Carp;

our @EXPORT_OK;

=head1 NAME

PDBCoordinateSectionParse

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module consists of subroutines that parse the coordinate section of the PDB file. 

=cut


###
#
##COULD USE SOME ERROR CHECKING
#
###


sub GetPDBAtomRecordFields
{

     my ($line) = @_;
	 unless ($line){
	      die "There was an error: DID NOT RECEIVE ARGUMENTS TO SUBROUTINE.GetPDBAtomRecordFields";
	 }

	 my @fields = split //, $line;
	 unless ( scalar(@fields) == 80 || scalar(@fields) == 78 ){
	      die "There was an error: UNEXPECTED LINE LENGHT FOR ATOM RECORD\n\t$line.GetPDBAtomRecordFields";
	 }
	 
	 my %AtomRecord;

	 ## $value = substr($string, $offset, $count); ##
	 #"ATOM" identifier
	 my $id = substr ($line, 0, 6);
	 $id =~ s/\s+//g;
	 $AtomRecord{'ID'} = $id;

	 #atom number
	 my $atomnum = substr ($line, 6, 5);
	 $atomnum =~ s/\s+//g;
	 $AtomRecord{'AtomNumber'} = $atomnum;

	 #atom name/type
	 my $atomname = substr ($line, 12, 4);
	 $atomname =~ s/\s+//g;
	 $AtomRecord{'AtomName'} = $atomname;

	 #alt location indicator
	 my $altLoc = substr ($line, 16, 1);
	 $AtomRecord{'AltLoc'} = $altLoc;
	 
	 #residue name
	 my $residue = substr ($line, 17, 3);
	 $residue =~ s/\s+//g;
	 $AtomRecord{'ResidueType'} = $residue;
	 
	 #chain identifier
	 my $chain = substr ($line, 21, 1);
	 $chain =~ s/\s+//g;
	 $AtomRecord{'Chain'} = $chain;
	 
	 #residue number
	 my $resnum = substr ($line, 22, 4);
	 $resnum =~ s/\s+//g;
	 $AtomRecord{'ResidueNumber'} = $resnum;
	 
	 #residue insertion code
	 my $resinst = substr ($line, 26, 1);
	 $AtomRecord{'ResidueInsertionCode'} = $resinst;
	 
	 #x coordinatess
	 my $xcords = substr ($line, 30, 8);
	 $xcords =~ s/\s+//g;
	 $AtomRecord{'X'} = $xcords;

	 #y coordinates
	 my $ycords = substr ($line, 38, 8);
	 $ycords =~ s/\s+//g;
	 $AtomRecord{'Y'} = $ycords;

	 #z coordinates
	 my $zcords = substr ($line, 46, 8);
	 $zcords =~ s/\s+//g;
	 $AtomRecord{'Z'} = $zcords;
	 
	 #occupancy
	 my $occ = substr ($line, 54, 6);
	 $occ =~ s/\s+//g;
	 $AtomRecord{'occupancy'} = $occ;

	 #temperature factor
	 my $temp = substr ($line, 60, 6);
	 $temp =~ s/\s+//g;
	 $AtomRecord{'TempFactor'} = $temp;

	 #IT SEEMS THAT THE PDB LINES DON'T NEED the "ELEMENT" AND "CHARGE" FIELDS
	 if ( length($line)>66 ){
	      #element symbol
		  my $ele = substr ($line, 76, 2);
		  $ele =~ s/\s+//g;
		  $AtomRecord{'element'} = $ele;
		  
		  #charge on atom
		  my $charge = substr ($line, 78, 2);
		  $charge =~ s/\s+//g;
		  $AtomRecord{'charge'} = $charge;
	 }else{
	      $AtomRecord{'element'} = '  ';
		  $AtomRecord{'charge'} = '  ';
	 }
	 
	 unless ( scalar(keys(%AtomRecord))==15 ){
	      die "There was an error: UNEXPECTED NUMBER OF FIELDS/KEYS FOR ATOM RECORD HASH. GetPDBAtomRecordFields";
	 }

	 return undef unless (%AtomRecord);
	 return \%AtomRecord;

}

sub GetPDBAnisouRecordFields
{

     my ($line) = @_; 
	 unless ($line){
	 die "There was an error: DID NOT RECEIVE ARGUMENTS TO SUBROUTINE. GetPDBAnisouRecordFields";
	 }
	 
	 my @fields = split //, $line;
     unless ( scalar(@fields) == 80 || scalar(@fields) == 78 ){
	     die "There was an error: UNEXPECTED LINE LENGHT FOR ATOM RECORD\n\t$line. GetPDBAnisouRecordFields";
	 }
	 
	 my %AnisouRecord;

	 ## $value = substr($string, $offset, $count); ##
	 #"ANISOU" identifier
	 my $id = substr ($line, 0, 6);
	 $id =~ s/\s+//g;
	 $AnisouRecord{'ID'} = $id;
	 
	 #atom number
	 my $atomnum = substr ($line, 6, 5);
	 $atomnum =~ s/\s+//g;
	 $AnisouRecord{'AtomNumber'} = $atomnum;
	 
	 #atom name/type
	 my $atomname = substr ($line, 12, 4);
	 $atomname =~ s/\s+//g;
	 $AnisouRecord{'AtomName'} = $atomname;
	 
	 #alt location indicator
	 my $altLoc = substr ($line, 16, 1);
	 $AnisouRecord{'AltLoc'} = $altLoc;
	 
	 #residue name
	 my $residue = substr ($line, 17, 3);
	 $residue =~ s/\s+//g;
	 $AnisouRecord{'ResidueType'} = $residue;

	 #chain identifier
	 my $chain = substr ($line, 21, 1);
	 $chain =~ s/\s+//g;
	 $AnisouRecord{'Chain'} = $chain;
	 
	 #residue number
	 my $resnum = substr ($line, 22, 4);
	 $resnum =~ s/\s+//g;
	 $AnisouRecord{'ResidueNumber'} = $resnum;
	 
	 #residue insertion code
	 my $resinst = substr ($line, 26, 1);
	 $AnisouRecord{'ResidueInsertionCode'} = $resinst;

	 #temperature factors
	 my $u0_0 = substr ($line, 28, 7);
	 $u0_0 =~ s/\s+//g;
	 $AnisouRecord{'u00'} = $u0_0;

	 my $u1_1 = substr ($line, 35, 7);
	 $u1_1 =~ s/\s+//g;
	 $AnisouRecord{'u11'} = $u1_1;

	 my $u2_2 = substr ($line, 42, 7);
	 $u2_2 =~ s/\s+//g;
	 $AnisouRecord{'u22'} = $u2_2;

	 my $u0_1 = substr ($line, 49, 7);
	 $u0_1 =~ s/\s+//g;
	 $AnisouRecord{'u01'} = $u0_1;

	 my $u0_2 = substr ($line, 56, 7);
	 $u0_2 =~ s/\s+//g;
	 $AnisouRecord{'u02'} = $u0_2;

	 my $u1_2 = substr ($line, 64, 7);
	 $u1_2 =~ s/\s+//g;
	 $AnisouRecord{'u12'} = $u1_2;
	 
	 #IT SEEMS THAT THE PDB LINES DON'T NEED the "ELEMENT" AND "CHARGE" FIELDS
	 if ( length($line)>66 ){
	      
		  #element symbol
		  my $ele = substr ($line, 76, 2);
		  $ele =~ s/\s+//g;
		  $AnisouRecord{'element'} = $ele;
		  
		  #charge on atom
		  my $charge = substr ($line, 78, 2);
		  $charge =~ s/\s+//g;
		  $AnisouRecord{'charge'} = $charge;
	 }else{
	      $AnisouRecord{'element'} = '  ';
		  $AnisouRecord{'charge'} = '  ';
	 }
	 
	 unless ( scalar(keys(%AnisouRecord))==16 ){
	      die "There was an error: UNEXPECTED NUMBER OF FIELDS/KEYS FOR ANISOU RECORD HASH. GetPDBAnisouRecordFields";
	 }
	 
	 return undef unless (%AnisouRecord);
	 return \%AnisouRecord;

}

sub GetPDBTerRecordFields
{

     my ($line) = @_;
	 unless ($line){
	      die "There was an error: DID NOT RECEIVE ARGUMENTS TO SUBROUTINE. GetPDBTerRecordFields";
	 }
	 
	 my @fields = split //, $line;
	 unless ( scalar(@fields) == 80 || scalar(@fields) == 78 ){     
          die "There was an error: UNEXPECTED LINE LENGHT FOR ATOM RECORD\n\t$line. GetPDBTerRecordFields";
	 }
	 
	 my %TerRecord;
	 
	 ## $value = substr($string, $offset, $count); ##
	 #"ATOM" identifier
	 my $id = substr ($line, 0, 6);
	 $id =~ s/\s+//g;
	 $TerRecord{'ID'} = $id;
	 
	 #atom number
	 my $atomnum = substr ($line, 6, 5);
	 $atomnum =~ s/\s+//g;
	 $TerRecord{'AtomNumber'} = $atomnum;
	 
	 #residue name
	 my $residue = substr ($line, 17, 3);
	 $residue =~ s/\s+//g;
	 $TerRecord{'ResidueType'} = $residue;
	 
	 #chain identifier
	 my $chain = substr ($line, 21, 1);
	 $chain =~ s/\s+//g;
	 $TerRecord{'Chain'} = $chain;
	 
	 #residue number
	 my $resnum = substr ($line, 22, 4);
	 $resnum =~ s/\s+//g;
	 $TerRecord{'ResidueNumber'} = $resnum;
	 
	 #residue insertion code
	 my $resinst = substr ($line, 26, 1);
	 $TerRecord{'ResidueInsertionCode'} = $resinst;
	 
	 unless ( scalar(keys(%TerRecord))==6 ){
	      die "There was an error: UNEXPECTED NUMBER OF FIELDS/KEYS FOR TER RECORD HASH. GetPDBTerRecordFields";
	 }
	 
	 return undef unless (%TerRecord);
	 return \%TerRecord;

}

sub GetPDBHetatmRecordFields
{

     my ($line) = @_;
	 unless ($line){
	      die "There was an error: DID NOT RECEIVE ARGUMENTS TO SUBROUTINE. GetPDBHetatmRecordFields";
	 }
	 
	 my @fields = split //, $line;
	 unless ( scalar(@fields)==80 ){
	      die "There was an error: UNEXPECTED LINE LENGHT FOR HETATM RECORD\t$line. GetPDBHetatmRecordFields";
	 }
	 
	 my %HetatmRecord;
	 
	 ## $value = substr($string, $offset, $count); ##
	 #"ATOM" identifier
	 my $id = substr ($line, 0, 6);
	 $id =~ s/\s+//g;
	 $HetatmRecord{'ID'} = $id;
	 
	 #atom number
	 my $atomnum = substr ($line, 6, 5);
	 $atomnum =~ s/\s+//g;
	 $HetatmRecord{'AtomNumber'} = $atomnum;
	 
	 #atom name/type
	 my $atomname = substr ($line, 12, 4);
	 $atomname =~ s/\s+//g;
	 $HetatmRecord{'AtomName'} = $atomname;
	 
	 #alt location indicator
	 my $altLoc = substr ($line, 16, 1);
	 $HetatmRecord{'AltLoc'} = $altLoc;
	 
	 #residue name
	 my $residue = substr ($line, 17, 3);
	 $residue =~ s/\s+//g;
	 $HetatmRecord{'ResidueType'} = $residue;
	 
	 #chain identifier
	 my $chain = substr ($line, 21, 1);
	 $chain =~ s/\s+//g;
	 $HetatmRecord{'Chain'} = $chain;
	 
	 #residue number
	 my $resnum = substr ($line, 22, 4);
	 $resnum =~ s/\s+//g;
	 $HetatmRecord{'ResidueNumber'} = $resnum;
	 
	 #residue insertion code
	 my $resinst = substr ($line, 26, 1);
	 $HetatmRecord{'ResidueInsertionCode'} = $resinst;
	 
	 #x coordinatess
	 my $xcords = substr ($line, 30, 8);
	 $xcords =~ s/\s+//g;
	 $HetatmRecord{'X'} = $xcords;
	 
	 #y coordinates
	 my $ycords = substr ($line, 38, 8);
	 $ycords =~ s/\s+//g;
	 $HetatmRecord{'Y'} = $ycords;
	 
	 #z coordinates
	 my $zcords = substr ($line, 46, 8);
	 $zcords =~ s/\s+//g;
	 $HetatmRecord{'Z'} = $zcords;
	 
	 #occupancy
	 my $occ = substr ($line, 54, 6);
	 $occ =~ s/\s+//g;
	 $HetatmRecord{'occupancy'} = $occ;
	 
	 #temperature factor
	 my $temp = substr ($line, 60, 6);
	 $temp =~ s/\s+//g;
	 $HetatmRecord{'TempFactor'} = $temp;
	 
	 #IT SEEMS THAT THE PDB LINES DON'T NEED the "ELEMENT" AND "CHARGE" FIELDS
	 if ( length($line)>66 ){
	      #element symbol
		  my $ele = substr ($line, 76, 2);
		  $ele =~ s/\s+//g;
		  $HetatmRecord{'element'} = $ele;
		  
		  #charge on atom
		  my $charge = substr ($line, 78, 2);
		  $charge =~ s/\s+//g;
		  $HetatmRecord{'charge'} = $charge;
	 } else {
	      $HetatmRecord{'element'} = '  ';
              $HetatmRecord{'charge'} = '  ';
	 }
	 
	 unless ( scalar(keys(%HetatmRecord))==15 ){
	     die "There was an error: UNEXPECTED NUMBER OF FIELDS/KEYS FOR HETATM RECORD HASH.GetPDBHetatmRecordFields";
	 }
	 
	 return undef unless (%HetatmRecord);
	 return \%HetatmRecord;

}

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDBCoordinateSectionParse

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/.>

=item * Search CPAN

L<http://search.cpan.org/dist/./>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Fiserlab Members .

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
