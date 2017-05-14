package SmotifTF::PDB::PDBfileParser;
use strict;
use warnings;
BEGIN {
	use Exporter ();
        our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = "0.01";
	#$DATE    = "02-19-2015";
        @ISA = qw(Exporter);
	
        @EXPORT = qw();  # symbols to export on request
	
        # name of the functions to export
	@EXPORT_OK = qw( 
                locate_pdb_file
                ParsePDBfile
		TakeRecordInfo
		PrintChainFile
                $PDB_DIR
                $PDB_OBSOLETES
	);
}

=head1 NAME

PDBfileParser

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module consists of subroutines to parse a PDB file. 

=cut

our @EXPORT_OK;
# This declares the named variables as package globals in the current package.
our $PDB_DIR; 
our $PDB_OBSOLETES;
our $USER_SPECIFIC_PDB_PATH;

use File::Find::Rule;
use Data::Dumper;
use Carp;
use File::Spec::Functions qw(catfile);

#use lib "/usr/local/lib/perl/JOELIB/PDB/";
use SmotifTF::PDB::PDBCoordinateSectionParse qw(
	GetPDBAtomRecordFields  
	GetPDBAnisouRecordFields 
	GetPDBTerRecordFields 
	GetPDBHetatmRecordFields
);

#
# locate_pdb_file
#
# It will look for pdb files on
# $PDB_DIR
# $PDB_OBSOLETES
# $USER_SPECIFIC_PDB_PATH
# in THAT order.
#
#$USER_SPECIFIC_PDB_PATH it could use dfor REMODEL_PDB
#

sub locate_pdb_file {

    my %args = (
        pdb_code           => '',
        chain              => '',
        pdb_path           => '',
        pdb_obsoletes_path => '',
		user_specific_pdb_path => '',
        @_,
    );

    my $pdb_code           = $args{'pdb_code'}           || undef;
    my $chain              = $args{'chain'}              || undef;
    my $pdb_path           = $args{'pdb_path'}           || undef;
    my $pdb_obsoletes_path = $args{'pdb_obsoletes_path'} || undef;
	my $user_specific_pdb_path = $args{'user_specific_pdb_path'} || undef;

    die "pdb_code is required"           unless $pdb_code;
    die "chain is required"              unless defined $chain;
    die "pdb_path is required"           unless $pdb_path;
    die "pdb_obsoletes_path is required" unless $pdb_obsoletes_path;
	die "user_specific_pdb_path is required" unless $user_specific_pdb_path;

    die "PDB_DIR       is not defined" unless $PDB_DIR;
    die "PDB_OBSOLETES is not defined" unless $PDB_OBSOLETES;
	die "USER_SPECIFIC_PDB_PATH is not defined" unless $USER_SPECIFIC_PDB_PATH;
    
    $pdb_code   = lc $pdb_code;

    #my $filename = $PDB_DIR. "/" . "pdb" . $pdb_code . ".ent.gz";
    #unless ( -e $filename ) {
    #    $filename = $PDB_OBSOLETES . "/" . "pdb" . $pdb_code . ".ent.gz";
    #    croak "$filename not found " unless ( -e $filename );
    #}
    #return $filename;
    my $full_path_name;
    $full_path_name = _get_full_path_name($pdb_code, $chain,  $PDB_DIR);
    return $full_path_name if $full_path_name;

    $full_path_name = _get_full_path_name($pdb_code, $chain, $PDB_OBSOLETES);
    return $full_path_name if $full_path_name;

	$full_path_name = _get_full_path_name($pdb_code, $chain, $USER_SPECIFIC_PDB_PATH);
 	return $full_path_name if $full_path_name;
}

sub _get_full_path_name {
    use File::Find::Rule;

    my ($pdb_code_id, $chain, $path) = @_; 

    #my $rule =  File::Find::Rule->new;
    #$rule->file;

    my $file1 = "pdb" . $pdb_code_id . ".ent";
	my $file2 = "pdb" . $pdb_code_id . ".ent.gz";
    # looking for remodel pdb file
	my $file3 = "pdb" . $pdb_code_id . $chain . ".ent";
	my $file4 = "pdb" . $pdb_code_id . $chain . ".ent.gz";

	my $full_name1 = catfile ($path, $file1);
	my $full_name2 = catfile ($path, $file2);
	my $full_name3 = catfile ($path, $file3);
	my $full_name4 = catfile ($path, $file4);

	if (-e $full_name1) {
		return $full_name1;
	}

	elsif (-e $full_name2) {
		return $full_name2;
	}

	elsif (-e $full_name3) {
        return $full_name3;
    }

	elsif (-e $full_name4) {
        return $full_name4;
    }

	else {
		return undef;
	}
    
    #print "Looking for $file ... \n";
    #$rule->name( qr/$file/ );
    #my @file_full_path = $rule->in($path);

    #croak "$file_name was not found in ".$self->{$path} 
    #    unless @file_full_path;
    
    #return $file_full_path[0] || undef;
}

sub ParsePDBfile {
    my ($pdb_code, $chain) = @_;
    
    die "ParsePDBfile pdbfile name required" unless $pdb_code;
    die "ParsePDBfile chain name required"   unless defined $chain;
    
    # print "ParsePDBfile $PDB_DIR\n";   
    # print "ParsePDBfile pdb_code = $pdb_code chain = $chain\n";   
 
    # get back the fullpath name for pdb file with pdb_code = $pdb_code
    my $pdbfile = locate_pdb_file(
        pdb_code           => $pdb_code,
        chain              => $chain,
        pdb_path           => $PDB_DIR,
        pdb_obsoletes_path => $PDB_OBSOLETES,
		user_specific_pdb_path => $USER_SPECIFIC_PDB_PATH,
    );
    die "ParsePDBfile could not find pdb file for $pdb_code $chain at $PDB_DIR or $PDB_OBSOLETES or $USER_SPECIFIC_PDB_PATH" 
        unless $pdbfile; 
    
    print "ParsePDBfile pdbfile = $pdbfile\n";
    
    my $fh; 
    if ( $pdbfile =~ /\.gz$/ ) { 
	    open $fh, '-|', 'gzip', '-dc', $pdbfile or die "can't open file $pdbfile $!";
    } else {
        open $fh, "<", $pdbfile or die "can't open file $pdbfile $!";   
    } 
    my @pdb_lines = <$fh>;
    chomp @pdb_lines;
    close $fh;
	
    my $coordinatesection=0;
	my $numcoordlines=0;
	
    my @coordlines;
    my %rescoordinfo=();
	 
	 my %resnumtocount;
	 my %counttoresnum;
	 my $cont_residues=0;
	 
	 my $previousatomtype='-';
	 my $previousrestype='-';
	 my $previousresseqnumber='-';
	 my $previousaltloc='-';
	 
	 #LINE: while ( my $pdbline = <PDB> ){
	 LINE: foreach my $pdbline (@pdb_lines) {
	      chomp $pdbline;
              # print "$pdbline\n";
		  
		  if ( $pdbline =~ /^ENDMDL/ ){ #this is for structures with multiple models. Uses first model. 
                       #print "this structure has multiple models (likely NMR)\n";
                       #my $tempmessage = 'model';
                       #push @coordlines, $tempmessage;
                       #$rescoordinfo{'model'}=1;
                       #$resnumtocount{'model'}=1;
                       #$counttoresnum{'model'}=1;
                       last LINE; 
                  }
		  
		  if ( $coordinatesection == 0 ){ #read file intil incountering the coordinate section
		       if ( ($pdbline =~ /^(ATOM|SIGATM|ANISOU|SIGUIJ|HETATM|TER)/) ){
			        $coordinatesection=1;
			   }else{
			        next LINE;
			   }
		  }
		  
		  if ( $coordinatesection == 1 and $pdbline =~ /^CONECT/ ){ #this signifies the end of the coordinate section
	               $coordinatesection = 0;
		       next LINE;
		  }
		  
		  if ( $coordinatesection==1 ){ #in the coordinate section of the pdb file
		  
		       #find chain and residue number of current atom.
			   #each type of coord field (ATOM, ANISOU, HETATM, TER) has same format for this field
			   my $currentchain = substr($pdbline, 21, 1);

                           #if the chain is defined from the arguments to the subroutine we only take those residues. otherwise take all residues
                           if ( defined($chain) ){
                                next unless ($currentchain eq $chain);
                           }

			   #find the residue number, residue type and alternate location (if exists)
			   #each type of coord field (ATOM, ANISOU, HETATM, TER) has same format for these fields
			   my $currentatomtype = substr($pdbline, 12, 4); 
                               $currentatomtype =~ s/\s+//g;
			   my $currentresseqnumber = substr($pdbline, 22, 4); 
                               $currentresseqnumber =~ s/\s+//g;
			   my $currentrestype = substr($pdbline, 17, 3); $currentrestype =~ s/\s+//g;
			   my $alternatelocation = substr($pdbline, 16, 1); $alternatelocation =~ s/\s+//g;
			   
			   unless ( $alternatelocation eq '' ){ #this is an alternate location
			        #take the first listed location. if already parsed this atom/residue should skip this line
					#has this atom type for this residue previously been encountered and is this a differnt alt location
					if ( ($currentresseqnumber eq $previousresseqnumber) && ($currentrestype eq $previousrestype) && ( ($previousaltloc ne $alternatelocation) and ($previousaltloc ne '') )){
					     next LINE; #we've already found coordinates for this atom
					}
			   }
			   
			   #set the previous residue info to the current info
			   $previousatomtype = $currentatomtype;
			   $previousrestype = $currentrestype;
			   $previousresseqnumber = $currentresseqnumber;
			   $previousaltloc = $alternatelocation;
			   
			   #count number of atoms found for this molecule (or chain)
			   $numcoordlines++;
			   
			   if ( $pdbline =~ /^ATOM\s+/ ){ #ATOM record: atomic coordinates for standard amino acids and nucleotides
			   
			        my $HashRef_AtomRecord = SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBAtomRecordFields($pdbline);
					TakeRecordInfo($pdbline, \@coordlines, \%rescoordinfo, $HashRef_AtomRecord, \%resnumtocount, \%counttoresnum, \$cont_residues);
			   
			   }elsif( $pdbline =~ /^ANISOU/ ){ #ANISOU record: anisotropic temperatures
			   
			        next LINE; #do not consider these lines
					#my $HashRef_AnisouRecord = GetPDBAnisouRecordFields($pdbline);
			   
			   }elsif ( ($pdbline =~ /^SIGATM/) or ($pdbline =~ /^SIGUIJ/) ){
			        
					next LINE; #do not consider these lines

			   }elsif( $pdbline =~ /^HETATM/ ){ #HETATM record: coordinates for non-polymer or non-standard residues, commonly water molecules
			   
			        my $HashRef_HetatmRecord = SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBHetatmRecordFields($pdbline);
					
					#HETATM can be of various types. taking non standard amino acids
					#skipping water, acetyl groups and amine group
					if ( $$HashRef_HetatmRecord{'ResidueType'} eq 'HOH' ){
			             #water
						 next LINE;
					}elsif ( ($$HashRef_HetatmRecord{'ResidueType'} eq 'ACE') and ($$HashRef_HetatmRecord{'ResidueNumber'}==0) ){
			             #acetyl group at the N terminal of the chain.
						 next LINE;
					}elsif ( ($$HashRef_HetatmRecord{'ResidueType'} eq 'NH2') ){
			             #acetyl group at the N terminal of the chain.
						 next LINE;
					}else{
			        
					     TakeRecordInfo($pdbline, \@coordlines, \%rescoordinfo, $HashRef_HetatmRecord, \%resnumtocount, \%counttoresnum, \$cont_residues);
					
					}
			   
			   }elsif( $pdbline =~ /^TER\s+/ ){ #TER record: defines end of the list of ATOM/HETATM coordinate records for a chain
			   
			        #if a chain is defined and this line was not skipped, it is the end of the defined chain. stop parsing
					#otherwise go to the next line (start of the next chain)
					if ( defined($chain) ){
			             last LINE if ($currentchain eq $chain);
					}else{
			             next LINE;
					}
					
					my $HashRef_TerRecord = SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBTerRecordFields($pdbline);

			   } elsif ( $pdbline =~ /^MASTER\s+/ or $pdbline =~ /^END\s+/ ) {
				    next LINE;
			   }else{
		              # print "unexpected coordinate line format\n$pdbline\n";
		              die "There was an error: $pdb_code $chain: unexpected coordinate line format\n$pdbline";
			   }
		  
		  } #end coordinate=1 coordinate section logic
	 
	 } #end LINE loop
	 
	 # close PDB or die "can't close $pdbfile\n";
	 # close PDB;
	 
	 unless ( (scalar(@coordlines)>=1) or (scalar(keys(%rescoordinfo))>=1) ){
             #print "no data in coordlines array\n";
             # print Dumper(\@coordlines); 
             #print Dumper(\@pdb_lines); 
             die "There was an error: $pdb_code $chain: no data in coordlines array."; 
             #exit;
	 }
	 
	 unless ( scalar(keys(%resnumtocount))==scalar(keys(%counttoresnum)) ){
            #print "hash sizes do not match I\n"; 
            die "There was an error: $pdb_code $chain: hash sizes do not match I."; 
            #exit;
	 }

	 return (\@coordlines, \%rescoordinfo, \%resnumtocount, \%counttoresnum);
	 
	 #####this subroutine call does not work#####
	 #PrintChainFile(\@coordlines, $uploadpdbfull, $$HashRef_TerRecord{'Chain'});
	 #unless ( (scalar(keys(%rescoordinfo))==$cont_residues) ){
	      #my $chainkeynum = scalar(keys(%rescoordinfo));
		  #print "$uploadpdbfull\tnumber of keys does not match CA atoms in rescoordinfo\n\tchain= $chainkeynum\tcount= $cont_residues\n\n"; exit;
	 #}

} #end ParsePDBfile subroutine 

sub TakeRecordInfo
{

	 my ($pdbline, $ArrayRef_coordlines, $HashRef_rescoordinfo, $HashRef_CoordRecord, $HashRef_resnumtocount, $HashRef_counttoresnum, $ScalarRef_cont_residues) = @_;
	 
	 #or take only some atoms from each residue
	 unless (  exists($$HashRef_CoordRecord{'Chain'})         && 
		   exists($$HashRef_CoordRecord{'AtomName'})      && 
                   exists($$HashRef_CoordRecord{'ResidueNumber'}) && 
                   exists($$HashRef_CoordRecord{'ResidueInsertionCode'}) 
         )
         {
	      die "There was an error: AtomName/ResidueNumber/ResidueInsertionCode do not exist";
	 }

	 my $atomtype = $$HashRef_CoordRecord{'AtomName'};
	 my $residuenum = $$HashRef_CoordRecord{'Chain'}.'_'.$$HashRef_CoordRecord{'ResidueNumber'}.$$HashRef_CoordRecord{'ResidueInsertionCode'};
	 $residuenum =~ s/\s+//g;
	 
	 #take all atoms in ATOM record
	 push @$ArrayRef_coordlines, $pdbline;
	 push( @{$$HashRef_rescoordinfo{"$residuenum"}}, $pdbline );

	 if ($atomtype eq 'N' || $atomtype eq 'CA' || $atomtype eq 'C' || $atomtype eq 'O'){
		  
		  if ( !exists($$HashRef_resnumtocount{"$residuenum"}) ){ #only count this once per residue, not per atom
			$$ScalarRef_cont_residues++;
			$$HashRef_resnumtocount{"$residuenum"} = $$ScalarRef_cont_residues;
			if ( !exists($$HashRef_counttoresnum{"$$ScalarRef_cont_residues"}) ){
				$$HashRef_counttoresnum{"$$ScalarRef_cont_residues"}=$residuenum;
			} 
                        else {
				die "There was an error: error in residue counting.TakeRecordInfo"; 
                                #exit;
			}
		  }
		  
		  ####or take only selected atom types
		  #push @$ArrayRef_coordlines, $pdbline;
		  #push( @{$$HashRef_rescoordinfo{"$residuenum"}}, $pdbline );
	 }
	 
	 #take all lines
	 #push( @{$$HashRef_rescoordinfo{"$residuenum"}}, $pdbline );

	 return;

}

sub PrintChainFile
{

     my ($ArrayRef_coordlines, $pdbid, $chain) = @_;

     die "There was an error:  ArrayRef_coordlines is required. PrintChainFile" unless ($ArrayRef_coordlines);  
     die "There was an error:  pdb_id is required. PrintChainFile"  unless $pdbid;
     die "There was an error:  chain is required. PrintChainFile"   unless defined $chain;

	 my $pdbchainfilename = uc($pdbid).$chain.'.pdb';
	 if ( -e $pdbchainfilename ){
	      print "$pdbchainfilename file exists\n";
	      return;
	 }
	 open OUT, ">$pdbchainfilename" or die "can't open $pdbchainfilename\n";
	 
	 foreach my $line (@$ArrayRef_coordlines){
		chomp $line;
		print OUT "$line\n";
	 }
	 
	 close OUT;

	 return;
}

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDBfileParser

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
