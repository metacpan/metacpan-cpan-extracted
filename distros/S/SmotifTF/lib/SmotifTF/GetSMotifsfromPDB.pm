package SmotifTF::GetSMotifsfromPDB;
use strict;
use warnings;

BEGIN {
    # use Exporter qw(import);
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
    $VERSION = "0.01";

    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT = qw();

    # symbols to export on request
    @EXPORT_OK = qw(
      extract_loops
      missing_residues
      extractcoordSSs
      parseGeomResults
      extract_chain_rethash
      check_pdb_file
      extract_SSS
      start_end_loop
      checklength
      CheckCaDistances
      checkloop
      lengthSS_loop
      read_rama_reduced
      read_rama_extended
      bin_phi_psi_angles
      $PDB_DIR
      $PDB_OBSOLETES
    );
}

our @EXPORT_OK;

=head1 NAME

GetSMotifsfromPDB

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module consists of subroutines that identify the Smotifs in a given 
PDB file (required for the creation of the dynamic Smotif library). 

=cut

# our ($PDB_DIR, $PDB_OBSOLETES);
our $PDB_DIR;
our $PDB_OBSOLETES;
our $USER_SPECIFIC_PDB_PATH;

use Data::Dumper;
use Carp;
#use constant DSSP_PATH => "/usr/local/bin";
#use constant DSSP_EXEC => "dsspcmbi";
use constant DISTANCE  => 4.3;

my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
    unless $config_file;

my $cfg           = new Config::Simple($config_file);
my $dssp      = $cfg->param( -block => 'dssp' );
my $DSSP_PATH = $dssp->{'path'};
my $DSSP_EXEC = $dssp->{'exec'};


# LOAD WILMOT-THORTON PHI-PSI SPACE PARTITION
my %ramareduced  = read_rama_reduced();
my %ramaextended = read_rama_extended();

# *******************************************************************************************

#=for

#Run DSSP
#extract loops from dssp file + phi/psi angles -> assign rama. conf (reduced+extended);
#get smotif definition (using vilas's code)  

#=cut

sub extract_loops {
    use File::Basename;

    #use lib "/usr/local/lib/perl/JOELIB/PDB";
    use SmotifTF::PDB::PDBfileParser qw(ParsePDBfile locate_pdb_file);
    $PDB::PDBfileParser::PDB_DIR       = $PDB_DIR;
    $PDB::PDBfileParser::PDB_OBSOLETES = $PDB_OBSOLETES;
	$PDB::PDBfileParser::USER_SPECIFIC_PDB_PATH = $USER_SPECIFIC_PDB_PATH;

    #use lib "/usr/local/lib/perl/VILAS/";
    use SmotifTF::GeometricMeasurements qw(recalc);

    #my $name = (caller(1))[3];
    #print "missing_residues $name $PDB_DIR\n";
    #print "PDBfileParser $PDB::PDBfileParser::PDB_DIR \n";

    my ( $pdb_code, $chain ) = @_;

    die "extract_loops pdb_code required arg" unless $pdb_code;
    die "extract_loops chain    required arg" unless defined $chain;
    die "extract_loops PDB_DIR  required arg" unless $PDB_DIR;

    # get an array of the ATOM (and HETATM) records of each residue
    # in the specified chain
    my (
        $ArrayRef_coordchain,   $HashRef_rescoordinfo,
        $HashRef_resnumtocount, $HashRef_counttoresnum
    ) = SmotifTF::PDB::PDBfileParser::ParsePDBfile( $pdb_code, $chain );

    if ( scalar(@$ArrayRef_coordchain) == 0 ) {
        print "error in PDB file parse: no residues\n";
        die " error in PDB file parse: no residues";
    }

    if (   ( scalar(@$ArrayRef_coordchain) == 1 )
        && ( $$ArrayRef_coordchain[0] eq 'model' ) )
    {
        die "$pdb_code $chain this structure has multiple models (likely NMR)";
        return;
    }

    #PRINT CHAIN TO TEMP FILE
    #my $temppdb = "./" . $uploadpdb . $uploadchain . '.pdb';
    my $temppdb = "./" . $pdb_code . $chain . '.pdb';
    open TEMP, ">$temppdb" or die "can't open $temppdb $!\n";
    foreach my $tmppdbline (@$ArrayRef_coordchain) {
        print TEMP "$tmppdbline\n";
    }
    close(TEMP);

    my $tempdssp   = $pdb_code . $chain . '.dssp';
    my $dsspoutput = $pdb_code . $chain . '.dssp.out';

    my $cmd =
      $DSSP_PATH . "/" . $DSSP_EXEC . " $temppdb $tempdssp > $dsspoutput 2>&1";
    system($cmd );

# EXTRACT LOOPS FROM DSSP FILE + PHI/PSI ANGLES -> ASSIGN RAMA. CONF (REDUCED+EXTENDED);
# my ( $num_extracted, @extracted, $missing_residue ) =
    my ( $missing_residue, $num_extracted, @extracted ) =
      extract_SSS( $tempdssp, $chain, $ArrayRef_coordchain, $pdb_code );

    # extract_SSS
    # parse ddsp to get Smotifs from the structure
    unless ($num_extracted) {
		delete_dssp_tmp_files($pdb_code, $chain);
        die "No valid loop motifs in this pdb file";
    }

    #GEOMETRIES - RAMA PRINT
    my $uploadpdbfull = SmotifTF::PDB::PDBfileParser::locate_pdb_file(
        pdb_obsoletes_path     => $PDB_OBSOLETES,
        pdb_path               => $PDB_DIR,
		user_specific_pdb_path => $USER_SPECIFIC_PDB_PATH,
        pdb_code               => $pdb_code,
        chain                  => $chain,
    );
    
    $uploadpdbfull = basename($uploadpdbfull);
    my @finals;
    foreach my $extracted (@extracted) {
        chomp $extracted;

#35 A HE 426 453 440 447 TDDFYRLGKELALQSGLAHKGDVVVMVS HHHHHHHHHHHHHHCCCCCCCCEEEEEE aaaaaaaaaaaaaaalabbplbbbbbbb aaaaaaaaaaaaaaalabbplbbbbbbb   ss1 lenght ss2 length  loop length
        my @smotiffields = split /\s+/, $extracted;
        unless ( scalar(@smotiffields) == 14 ) {
            print "unexpected splitting results of extracted smotif\n\t$extracted\n";
            #print Dumper ( \@smotiffields );
            delete_dssp_tmp_files($pdb_code, $chain);
            die
              "unexpected splitting results of extracted smotif\n\t$extracted";
            return;
        }

##### start Vilas implementation
        my @idtable = (
            $pdb_code,         $chain,            $smotiffields[3],
            $smotiffields[11], $smotiffields[12], $smotiffields[13],
            0,                 $smotiffields[2],  $smotiffields[4]
          )
          ; #pdb, chain, smotif start, SS1 length, SS2 length, loop length, 0, Smotif type
        my $pdbtoparse = $PDB_DIR . $uploadpdbfull;

# This subroutine calculates the distance and three angles for an smotif, based on Baldo Oliva's description
        my @geoms = recalc( $ArrayRef_coordchain, @idtable );   
        foreach my $val (@geoms) {
            $val = sprintf( "%.6f", $val );
        }
        my $finals = join(
            "\t",
            (
                $pdb_code,         $chain,            $smotiffields[2],
                $smotiffields[3],  $smotiffields[13], $smotiffields[11],
                $smotiffields[12], $smotiffields[7],  $smotiffields[8],
                $smotiffields[9],  $geoms[0],         $geoms[1],
                $geoms[2],         $geoms[3]
            )
        );
        # this output (@finals) is needed by Brinda
        push( @finals, $finals );

    }    #end foreach loop

	delete_dssp_tmp_files($pdb_code, $chain);

    return @finals;

}    #end extract_loops subroutine

sub missing_residues {

    #use lib "/usr/local/lib/perl/JOELIB/PDB";
    use SmotifTF::PDB::PDBfileParser qw(ParsePDBfile);
    $PDB::PDBfileParser::PDB_DIR       = $PDB_DIR;
    $PDB::PDBfileParser::PDB_OBSOLETES = $PDB_OBSOLETES;
	$PDB::PDBfileParser::USER_SPECIFIC_PDB_PATH = $USER_SPECIFIC_PDB_PATH;

    #my $name = (caller(1))[3];
    #print "missing_residues $name $PDB_DIR\n";
    #print "PDBfileParser $PDB::PDBfileParser::PDB_DIR \n";

    my ( $pdb_code, $chain ) = @_;

    die "missing_residues pdb_code required arg" unless $pdb_code;
    die "missing_residues chain    required arg" unless defined $chain;
    die "missing_residues PDB_DIR  required arg" unless $PDB_DIR;

    # get an array of the ATOM (and HETATM) records of each residue
    # in the specified chain
    my (
        $ArrayRef_coordchain,   $HashRef_rescoordinfo,
        $HashRef_resnumtocount, $HashRef_counttoresnum
    ) = SmotifTF::PDB::PDBfileParser::ParsePDBfile( $pdb_code, $chain );

    if ( scalar(@$ArrayRef_coordchain) == 0 ) {
        print "$pdb_code\t$chain\t error in PDB file parse: no residues\n";
        die " $pdb_code\t$chain\t error in PDB file parse: no residues";
    }

    if (   ( scalar(@$ArrayRef_coordchain) == 1 )
        && ( $$ArrayRef_coordchain[0] eq 'model' ) )
    {
        warn "$pdb_code $chain this structure has multiple models (likely NMR)";
	#die "$pdb_code $chain this structure has multiple models (likely NMR)";
        
    }

    #PRINT CHAIN TO TEMP FILE
    #my $temppdb = "./" . $uploadpdb . $uploadchain . '.pdb';
    my $temppdb = "./" . $pdb_code . $chain . '.pdb';
    open TEMP, ">$temppdb" or die "can't open $temppdb for $pdb_code\t$chain $!\n";
    foreach my $tmppdbline (@$ArrayRef_coordchain) {
        print TEMP "$tmppdbline\n";
    }
    close(TEMP);
    die "$pdb_code\t$chain\t Error writing chain to temp file" unless -e $temppdb;


    my $tempdssp   = $pdb_code . $chain . '.dssp';
    my $dsspoutput = $pdb_code . $chain . '.dssp.out';

    my $cmd =
      $DSSP_PATH . "/" . $DSSP_EXEC . " $temppdb $tempdssp > $dsspoutput 2>&1";
    system($cmd );
    print "CMD=$cmd\n";

# EXTRACT LOOPS FROM DSSP FILE + PHI/PSI ANGLES -> ASSIGN RAMA. CONF (REDUCED+EXTENDED);
# my ( $num_extracted, @extracted, $missing_residue ) =
    my ( $missing_residue, $num_extracted, @extracted ) =
      extract_SSS( $tempdssp, $chain, $ArrayRef_coordchain, $pdb_code );

	delete_dssp_tmp_files($pdb_code, $chain);

    # extract_SSS
    # parse ddsp to get Smotifs from the structure
    # If structure does not have Smotifs then by default should not be 
    # remodeled just renumbered. 
    my $disordered = 0;
    unless ($num_extracted) {
        # it means this is a disordered chain
        warn "No valid Smotifs in this pdb file pdb_code = $pdb_code chain = $chain";
        $disordered = 1;
    }
    # return $missing_residue;
    return ($missing_residue, $disordered);
}

#####     SUBROUTINES     ##########################################################################

sub extractcoordSSs {

    my ( $typestem, $retstart, $rettype, $pathout, %rethash ) = @_;

    #Nt, loop start, ss type, output dir, pdb file

    die "extractcoordSSs: typestem arg required" unless $typestem;
    die "extractcoordSSs: retstart arg required" unless $retstart;
    die "extractcoordSSs: rettype  arg required" unless $rettype;
    die "extractcoordSSs: pathout  arg required" unless $pathout;
    die "extractcoordSSs: %rethash arg required" unless %rethash;

    my $retcheck = 1;
    my ( $residuenum, $typearch );
    my $tempfile = "$pathout" . '/temp.' . "$typestem";
    open TMP, ">$tempfile" or die "can not open $tempfile\n";
    if ( $typestem eq "Nt" ) {
        if ( $rettype eq "H" ) {
            $typearch = 1;
            for my $rr ( -4 .. 0 ) {
                $residuenum = ( $retstart + $rr );
                if ( defined( $rethash{$residuenum} ) ) {
                    my $ArrayRef_tmpNtarray = $rethash{$residuenum};
                    foreach my $tempele (@$ArrayRef_tmpNtarray) {
                        print TMP "$tempele\n";
                    }
                }
                else { $retcheck = 0; }
            }
        }
        elsif ( $rettype eq "E" || $rettype eq "J" || $rettype eq "A" ) {
            $typearch = 0;
            for my $rr ( -1 .. 0 ) {
                $residuenum = ( $retstart + $rr );
                if ( defined( $rethash{$residuenum} ) ) {
                    my $ArrayRef_tmpNtarray = $rethash{$residuenum};
                    foreach my $tempele (@$ArrayRef_tmpNtarray) {
                        print TMP "$tempele\n";
                    }
                }
                else { $retcheck = 0; }
            }
        }
        else {
            print "unrecognized ss type\n\t$rettype\n";
            die "unrecognized ss type\n\t$rettype";
            return;
        }
    }
    if ( $typestem eq "Ct" ) {
        if ( $rettype eq "H" ) {
            $typearch = "1";
            for my $rr ( 0 .. 4 ) {
                $residuenum = ( $retstart + $rr );
                if ( defined( $rethash{$residuenum} ) ) {
                    my $ArrayRef_tmpCtarray = $rethash{$residuenum};
                    foreach my $tempele (@$ArrayRef_tmpCtarray) {
                        print TMP "$tempele\n";
                    }
                }
                else { $retcheck = 0; }
            }
        }
        elsif ( $rettype eq "E" || $rettype eq "R" || $rettype eq "A" ) {
            $typearch = "0";
            for my $rr ( 0 .. 1 ) {
                $residuenum = ( $retstart + $rr );
                if ( defined( $rethash{$residuenum} ) ) {
                    my $ArrayRef_tmpCtarray = $rethash{$residuenum};
                    foreach my $tempele (@$ArrayRef_tmpCtarray) {
                        print TMP "$tempele\n";
                    }
                }
                else { $retcheck = 0; }
            }
        }
        else {
            print "unrecognized ss type\n\t$rettype\n";
            die "unrecognized ss type\n\t$rettype";
            return;
        }
    }

    return ( $retcheck, $tempfile, $typearch );

}    #end extractcoordSSs subroutine

####################

sub parseGeomResults {

    my (@cmd) = @_;

    my ( $l1, $l2, $l3, $l4, $l5 ) = ( 0, 0, 0, 0, 0 );
    my $rettrue = 1;
    foreach my $temp (@cmd) {
        if ( $temp =~ /^\S\sDistance:\s+(\S+)/ )  { $l1 = $1; }
        if ( $temp =~ /Vector\s+\S+\s+(\S+)/ )    { $l2 = $1; }
        if ( $temp =~ /Hoist Angle:\s+(\S+)/ )    { $l3 = $1; }
        if ( $temp =~ /Packing Angle:\s+(\S+)/ )  { $l4 = $1; }
        if ( $temp =~ /Meridian Angle:\s+(\S+)/ ) { $l5 = $1; }
    }
    if (   ( $l1 == 0 )
        && ( $l2 == 0 )
        && ( $l3 == 0 )
        && ( $l4 == 0 ) & ( $l5 == 0 ) )
    {
        $rettrue = 0;
    }

    return ( $rettrue, $l1, $l2, $l3, $l4, $l5 );

}

#################
##### CHECKED but could use some error checking on pdb file parsing
sub extract_chain_rethash {

    my ( $uploadpdbfull, $uploadchain ) = @_;
    unless ( $uploadpdbfull && defined($uploadchain) && $PDB_DIR ) {
        print "arguments for extract_chain_rethash subroutine\n";
        return;
    }

    my ( $residuenum, $chainid, $atomtype );
    my %chainhash     = ();
    my $cont_residues = 0;
    open( PDB, "<$PDB_DIR/$uploadpdbfull" )
      || die "Cannot open $uploadpdbfull\n";

 #ATOM     69  CB  ASP    13      -0.809  13.793  23.588  1.00 18.66      A    C
 #ATOM    452  N   LYS A  59      41.979  13.606   6.699  1.00 23.17           N

    ##### original parse pdb file
    while ( my $pdbline = <PDB> ) {
        chomp $pdbline;
        if ( $pdbline =~ /^ATOM/ ) {
            $chainid = substr( $pdbline, 21, 1 );
            $chainid =~ s/\s//g;
            if ( $chainid eq "" ) { $chainid = "-"; }
            $residuenum = substr( $pdbline, 22, 4 );
            $residuenum =~ s/\s//g;
            $atomtype = substr( $pdbline, 12, 4 );
            $atomtype =~ s/\s//g;
            if ( $chainid eq $uploadchain ) {
                if ( $atomtype eq "CA" ) { $cont_residues++; }
                push( @{ $chainhash{"$residuenum"} }, $pdbline );
            }
        }
    }    #end while loop

    unless ( scalar( keys(%chainhash) ) == $cont_residues ) {
        close(PDB);
        print "number of keys does not match CA atoms in chainhash\n";
        die "number of keys does not match CA atoms in chainhash";
        return;
    }

    close(PDB);

    return ( $cont_residues, %chainhash );

}

############################

sub check_pdb_file {

    my (%rethash) = @_;

    my ( $retkey, $retline );
    my $retcheck = 1;
    my ( @retlines, $retlines );
    my ( $atomtype, $residue, $chainid, $residuenum, $xcoo, $ycoo, $zcoo );
    foreach $retkey ( keys(%rethash) ) {
        @retlines = split( "\n", $rethash{$retkey} );
        foreach $retline ( 0 .. $#retlines ) {
            $atomtype = substr( $retlines[$retline], 13, 3 );
            $atomtype =~ s/\s//g;
            $residue = substr( $retlines[$retline], 17, 3 );
            $residue =~ s/\s//g;
            $chainid = substr( $retlines[$retline], 21, 1 );
            $chainid =~ s/\s//g;
            if ( $chainid eq "" ) { $chainid = "-"; }
            $residuenum = substr( $retlines[$retline], 22, 4 );
            $residuenum =~ s/\s//g;
            $xcoo = substr( $retlines[$retline], 30, 8 );
            $xcoo =~ s/\s//g;
            $ycoo = substr( $retlines[$retline], 38, 8 );
            $ycoo =~ s/\s//g;
            $zcoo = substr( $retlines[$retline], 46, 8 );
            $zcoo =~ s/\s//g;

            if ( $retline == 0 ) {    #N
                if ( $atomtype ne "N" ) {
                    $retcheck = 0;
                }
            }
            elsif ( $retline == 1 ) {    #CA
                if ( $atomtype ne "CA" ) {
                    $retcheck = 0;
                }
            }
            elsif ( $retline == 2 ) {    #C
                if ( $atomtype ne "C" ) {
                    $retcheck = 0;
                }
            }
            elsif ( $retline == 3 ) {    #O
                if ( $atomtype ne "O" ) {
                    $retcheck = 0;
                }
            }
            if (   !($atomtype)
                || !($residue)
                || !($chainid)
                || !($residuenum)
                || !($xcoo)
                || !($ycoo)
                || !($zcoo) )
            {
                $retcheck = 0;
            }
        }
        if ( $retcheck == 0 ) {

            print $rethash{$retkey};
            last;
        }
    }
    return ($retcheck);
}

sub delete_dssp_tmp_files {

	my ($pdb_code, $chain) = @_;

	my $temppdb    = $pdb_code . $chain . '.pdb';
    my $tempdssp   = $pdb_code . $chain . '.dssp';
    my $dsspoutput = $pdb_code . $chain . '.dssp.out';


   if ( -e $temppdb ) {
        unlink($temppdb) or croak "can't delete $temppdb";
    }    
    if ( -e $tempdssp ) {
        unlink($tempdssp) or croak "can't delete $tempdssp";
    }    
    if ( -e $dsspoutput ) {
        unlink($dsspoutput) or croak "can't delete $dsspoutput";
    } 

}

###########################
##### CHECKED
sub extract_SSS {

    my ( $tempdssp, $uploadchain, $ArrayRef_coordchain, $uploadpdb ) = @_;

    die "tempdssp is required"            unless $tempdssp,;
    die "uploadchain is required"         unless defined $uploadchain;
    die "uploadpdb is required"           unless $uploadpdb;
    die "ArrayRef_coordchain is required" unless $ArrayRef_coordchain;

    my $missing_residue = 0;
    my @retacepted;
    my $rettrue = 0;

    unless ( -e $tempdssp ) { 
	delete_dssp_tmp_files ($uploadpdb, $uploadchain);
	die " There was error: $tempdssp does not exist for $uploadpdb\t$uploadchain"; 
   }

    open PRED, "<$tempdssp" or die "can not open $tempdssp\n";

    my $cont = 0;
    my @newlines;
    my %dihed;
    my $start = 0;

  DSSPLINE: while ( my $dsspline = <PRED> ) {
        chomp $dsspline;
        if ( $dsspline =~
/^\s+#\s+RESIDUE\s+AA\s+STRUCTURE\s+BP1\s+BP2\s+ACC\s+N-H-->O\s+O-->H-N\s+N-H-->O\s+O-->H-N\s+TCO\s+KAPPA\s+ALPHA\s+PHI\s+PSI\s+X-CA\s+Y-CA\s+Z-CA\s+$/
          )
        {
            $start = 1;
            next DSSPLINE;
        }
        if ( $start == 1 ) {

#FORMAT DSSP
#  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA
#    1    1 A M              0   0    0      0, 0.0     0, 0.0     0, 0.0     0, 0.0   0.000 360.0 360.0 360.0 155.5  -17.8    8.5   95.4
#    2    2 A K        -     0   0    0      1,-0.1   331,-0.1   327,-0.1   330,-0.1  -0.174 360.0-170.5 -53.3 135.8  -14.4    9.1   93.7
#    3    3 A K        +     0   0    0    329,-0.2   406,-3.9   406,-0.1     2,-0.3   0.630  61.6  81.5-100.0 -30.5  -12.0   11.1   95.7
#    4    4 A T  S    S-     0   0    0    404,-0.2   304,-0.2   405,-0.1     2,-0.2  -0.682  77.6-128.4 -83.9 143.3   -9.2   11.7   93.1
#    5    5 A K  E     -a  308   0A   0    302,-2.3   304,-1.9   401,-0.3     2,-0.5  -0.576   9.7-136.6 -92.5 149.7   -9.8   14.5   90.6
#    6    6 A I  E     -ab 309  28A   0     21,-0.6    23,-3.5    -2,-0.2    24,-2.2  -0.925   8.5-160.4-114.5 116.6   -9.6   14.3   86.9
#  345        !              0   0    0      0, 0.0     0, 0.0     0, 0.0     0, 0.0   0.000 360.0 360.0 360.0 360.0    0.0    0.0    0.0

            if ( substr( $dsspline, 13, 1 ) eq '!' ) { next DSSPLINE; }
            my $reschain = substr( $dsspline, 11, 1 );
            unless ( $reschain eq $uploadchain ) { next DSSPLINE; }

            #count line number
            $cont++;

#get pdb residue number, residue type and ss type for current residue, anything undefined becomes a coil, use 3-state definition
            my $lrestype = substr( $dsspline, 13, 2 );
            $lrestype =~ s/\s+//g;
            if ( $lrestype =~ /^[a-z]$/ ) {
                $lrestype = 'C';
            }

#unless( ($lrestype =~ /^[A_C_D_E_F_G_H_I_K_L_M_N_P_Q_R_S_T_V_W_Y_X_B_Z]$/) or ($lrestype =~ /^[a-z]$/)  ){ print "$uploadpdb\t$uploadchain\t unexpected amino acid type\n\t$lrestype\n"; return; }
            unless (
                (
                    $lrestype =~
                    /^[A_C_D_E_F_G_H_I_K_L_M_N_P_Q_R_S_T_V_W_Y_X_B_Z]$/
                )
              )
            {
                print "$uploadpdb\t$uploadchain\t unexpected amino acid type\n\t$lrestype\n";
				delete_dssp_tmp_files ($uploadpdb, $uploadchain);
                die "There was error: $uploadpdb\t$uploadchain\t unexpected amino acid type\n\t$lrestype";
                
            }
            my $lresnum = substr( $dsspline, 5, 6 );
            $lresnum =~ s/\s+//g;
            my $lss = substr( $dsspline, 16, 1 );
            $lss =~ s/\s+//g;
            if ( $lss eq '' ) { $lss = "C"; }
            unless ( $lss =~ /^[H_B_E_G_I_T_S_C]$/ ) {
                print "$uploadpdb\t$uploadchain\t unexpected ss type\n\t$lss\n";
				delete_dssp_tmp_files ($uploadpdb, $uploadchain);
                die "There was error: $uploadpdb\t$uploadchain\t unexpected ss type\n\t$lss";
                
            }

            #convert DSSP definitions to 3-state format
            #E,B --> E
            #H,G --> H
            #I,T,S,C --> L
            if ( ( $lss eq 'B' ) or ( $lss eq 'E' ) ) {
                $lss = 'E';
            }
            elsif ( ( $lss eq 'G' ) or ( $lss eq 'H' ) ) {
                $lss = 'H';
            }
            elsif (( $lss eq 'I' )
                or ( $lss eq 'T' )
                or ( $lss eq 'S' )
                or ( $lss eq 'C' ) )
            {
                $lss = 'C'; #do nothing for now (perhaps will change all to "L"\
            }
            else {
                print "$uploadpdb\t$uploadchain\t unexpected DSSP secondary structure type\t$lss\n";
				delete_dssp_tmp_files ($uploadpdb, $uploadchain);
                die "There was error: $uploadpdb\t$uploadchain\t unexpected DSSP secondary structure type\t$lss";
                
            }

            #get phi and psi values for current residue
            my $lphi = substr( $dsspline, 103, 6 );
            unless ( defined($lphi) ) {
				delete_dssp_tmp_files ($uploadpdb, $uploadchain);
                die "There was error: $uploadpdb\t$uploadchain\t lphi not defined\t$lphi";
            }
            $lphi =~ s/\s+//g;
            if ( $lphi == 360 ) { $lphi = "0.0"; }
            my $lpsi = substr( $dsspline, 109, 6 );
            unless ( defined($lpsi) ) {
                print "$uploadpdb\t$uploadchain\t lphi not defined\t$lpsi\n";
				delete_dssp_tmp_files ($uploadpdb, $uploadchain);
                die "There was error: $uploadpdb\t$uploadchain\t lphi not defined\t$lpsi";
                
            }
            $lpsi =~ s/\s+//g;
            if ( $lpsi == 360 ) { $lpsi = "0.0"; }

            my $newline =
                $lrestype . "\t"
              . $uploadchain . "\t"
              . $cont . "\t"
              . $lresnum . "\t"
              . $lss;
            push( @newlines, $newline );
            $dihed{'phi'}{"$lresnum"} = $lphi;
            $dihed{'psi'}{"$lresnum"} = $lpsi;
        }

    }    #end DSSPLINE loop
    unless ( $start == 1 ) {
        print "error; never found dssp header line for $uploadpdb $uploadchain\n";
		delete_dssp_tmp_files ($uploadpdb, $uploadchain);
        die "There was error: never found dssp header line for $uploadpdb $uploadchain";
        
    }

    close(PRED);

    #EXTRACT MOTIFS
    my $lastnumber = "10000";    #assume there is no chain with 10,000 residues
    my %type;
    my %start;
    my %end;
    my %sslength;
    my $sselecont = 0;
    my $lastss;
    my ( $lastres, $contSSlng ) = 0;

    foreach my $infoline (@newlines) {

        #line format; C - 1 1 E
        chomp $infoline;
        my @temp_infoline = split /\t/, $infoline;
        unless ( scalar(@temp_infoline) == 5 ) {
            print "$uploadpdb\t$uploadchain\t unexpected residue,ss info\n\t$infoline\n";
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: $uploadpdb\t$uploadchain\t unexpected residue,ss info\n\t$infoline";
           
        }

        #set variables from line info
        my $SEQ           = $temp_infoline[0];
        my $numbercont    = $temp_infoline[2];
        my $residuenumber = $temp_infoline[3];
        my $SS            = $temp_infoline[4];

        if ( ( $SS eq 'H' ) || ( $SS eq 'E' ) ) {    # helix or strand

            my $next = $numbercont - 1;

            if ( $lastnumber ne $next )
            {    #INICI SS this is the beginning of a ss helix or strand

                if ( $lastnumber == 10000 )
                {    #beginning of the first ss element of the chain

                    $lastnumber =
                      $numbercont; #current number becomes new end of ss element
                    $lastss =
                      $SS;    #current ss type becomes new type of ss element
                    $lastres = $residuenumber
                      ;    #current residue number becomes new end of ss element

                    $sselecont++
                      ; #increase count of the secondary structure element to identify the current ss element
                    $start{$sselecont} = $residuenumber
                      ; #populate the "start" hash with the beginning residue number for the current ss element
                    $type{$sselecont} = $SS
                      ; #populate the "type" hash with the type of ss for the currenent ss element

                    $contSSlng = 1
                      ; #this variable counts the number of residues in the current ss element (for length of helix or strand)

                }
                else {    #beginning of an ss element but not first in the chain

#populate the "sslength" and "end" hashes for the previous ss element (prior to updating the count variable)
                    $sslength{$sselecont} = $contSSlng; #$tamany{$cont}=$contSS;
                    $end{$sselecont}      = $lastres;

                    #update the numbers based on the current ss element
                    $lastnumber = $numbercont;
                    $lastss     = $SS;
                    $lastres    = $residuenumber;

#increase the "count" variable to identify the current ss element and populate the "start" and "type" hashes for the current element
                    $sselecont++;
                    $start{$sselecont} = $residuenumber;
                    $type{$sselecont}  = $SS;

                    $contSSlng = 1;

                }

            }
            else {    #in the middle of a ss element (helix or strand)

                if ( $lastss ne $SS )
                { #0 this means we are actually in the beginning of a new secondary structure element but there was no loop between this and the last element

#populate the "sslength" and "end" hashes for the previous ss element (prior to updating the count variable)
                    $sslength{$sselecont} =
                      $contSSlng;    #$tamany{$cont}= $contSS;
                    $end{$sselecont} = $lastres;

                    #update the numbers based on the current ss element
                    $lastnumber = $numbercont;
                    $lastss     = $SS;
                    $lastres    = $residuenumber;

#increase the "count" variable to identify the current ss element and populate the "start" and "type" hashes for the current element
                    $sselecont++;
                    $start{$sselecont} = $residuenumber;
                    $type{$sselecont}  = $SS;

                    $contSSlng = 1;

                }
                else { #in the middle of the current ss element (helix or strand

     #revise the numbers for the current ss element based on the current residue
                    $lastnumber = $numbercont;
                    $lastss     = $SS;
                    $lastres    = $residuenumber;
                    $contSSlng++;

                }
            }

        }
        elsif ( ( $SS eq 'C' ) ) {
            next;
        }
        else {
            print "$uploadpdb\t$uploadchain\t H/E/C logic\n";
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: $uploadpdb\t$uploadchain\t H/E/C logic";
           # return;
        }    #end "H" or "E" if/else logic

    }    #end foreach loop

    #LAST populate the "sslength" and "end" hashes for the last ss element
    $sslength{$sselecont} = $contSSlng;    #$tamany{$cont}= $contSS;
    $end{$sselecont}      = $lastres;

    my %StartResKeyIDLookup;
    while ( my ( $keyid, $start ) = each(%start) ) {
        $StartResKeyIDLookup{"$start"} = $keyid;
    }

    #CHECK LENGTHS OF SS   -> HELIX AT LEAST 5 RESIDUES LONG
    #		            -> BETA AT LEAST 2 RESIDUES LONG
    #any ss elements that do not meet lenght requirements are removed
    my @preacepted;
    my @sorted = sort { $a <=> $b } keys %type;
    foreach my $key (@sorted) {
        if ( $type{$key} eq "H" ) {
            if ( $sslength{$key} > 4 ) {
                my $preacepted = $key . "\t" . $start{$key} . "\t" . $end{$key};
                push( @preacepted, $preacepted );
            }
        }
        elsif ( $type{$key} eq "E" ) {
            if ( $sslength{$key} > 1 ) {
                my $preacepted = $key . "\t" . $start{$key} . "\t" . $end{$key};
                push( @preacepted, $preacepted );
            }
        }
        else {
            print "$uploadpdb\t$uploadchain\t LOGIC ERROR\n";
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: $uploadpdb\t$uploadchain\t LOGIC ERROR";
           # return;
        }
    }    #end foreach loop

    my $extractmotif;
    my @extracted;
  PREMOTIF: for ( my $i = 0 ; $i <= $#preacepted - 1 ; $i++ ) {
        my $newline = $preacepted[$i] . "\t" . $preacepted[ $i + 1 ];

        #1               14      15       2   22      26
        my @temp_newline = split /\s+/, $newline;    #$temp[1]$temp[8]
        unless ( scalar(@temp_newline) ) {
            print "$uploadpdb\t$uploadchain\t unexpected combineline contents\n\t$newline\n";
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: $uploadpdb\t$uploadchain\t unexpected combineline contents\n\t$newline";
           # return;
        }
        unless ( exists $StartResKeyIDLookup{"$temp_newline[1]"} ) {
            print "$uploadpdb\t$uploadchain\t start residue does not exist in hash\n";
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: $uploadpdb\t$uploadchain\t start residue does not exist in hash";
           # return;
        }
        my $ss1keyid = $StartResKeyIDLookup{"$temp_newline[1]"};
        my $ss1type  = $type{"$ss1keyid"};
        my $ss1ln    = $sslength{"$ss1keyid"};
        unless ( exists $StartResKeyIDLookup{"$temp_newline[4]"} ) {
            print "$uploadpdb\t$uploadchain\t start residue does not exist in hash\n";
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: $uploadpdb\t$uploadchain\t start residue does not exist in hash";
           # return;
        }
        my $ss2keyid = $StartResKeyIDLookup{"$temp_newline[4]"};
        my $ss2type  = $type{"$ss2keyid"};
        my $ss2ln    = $sslength{"$ss2keyid"};

        #parse each line of the dssp output array (produced above)
        my ( $SS, $SEQ, $lramastr, $lramastrext );
        my $take = 0;
        for ( my $j = 0 ; $j < scalar(@newlines) ; $j++ ) {

            #C - 1 14 C
            my $infoline = $newlines[$j];
            my @temp2 = split /\s+/, $infoline;
            unless ( scalar(@temp2) == 5 ) {
                print "$uploadpdb\t$uploadchain\t unexpected newline line\n\t$infoline\n";
				delete_dssp_tmp_files ($uploadpdb, $uploadchain);
                die "There was error: $uploadpdb\t$uploadchain\t unexpected newline line\n\t$infoline";
               # return;
            }

            if ( $temp2[3] eq $temp_newline[1] )
            {    #this is the first residue of the Smotif
                my @takefields;
                do {
                    my $takeindex = $j + $take;
                    my $takeline  = $newlines[$takeindex];

                    #print "$takeline\n";
                    @takefields = split /\s+/, $takeline;
                    $SS  .= "C";
                    $SEQ .= $takefields[0];
                    my ( $binnedphi, $binnedpsi ) = &bin_phi_psi_angles(
                        $dihed{'phi'}{ $takefields[3] },
                        $dihed{'psi'}{ $takefields[3] }
                    );
                    $lramastr    .= $ramareduced{$binnedphi}{$binnedpsi};
                    $lramastrext .= $ramaextended{$binnedphi}{$binnedpsi};
                    $take++;
                } until $takefields[3] eq $temp_newline[5];

            #replace substrings at beginning and end of SS (now CCCCCCCCCCCCCC).
                my $ss1seq;
                for ( my $count1 = 1 ; $count1 <= $ss1ln ; $count1++ ) {
                    $ss1seq .= "$ss1type";
                }
                my $ss2seq;
                for ( my $count2 = 1 ; $count2 <= $ss2ln ; $count2++ ) {
                    $ss2seq .= "$ss2type";
                }
                substr( $SS, 0,       $ss1ln ) = $ss1seq;
                substr( $SS, -$ss2ln, $ss2ln ) = $ss2seq;
                last;
                last;
            }
        }    #end foreach/for loop
        $extractmotif =
            $temp_newline[0] . "\t"
          . $uploadchain . "\t"
          . $type{ $temp_newline[0] }
          . $type{ $temp_newline[3] } . "\t"
          . $temp_newline[1] . "\t"
          . $temp_newline[5] . "\t"
          . $SEQ . "\t"
          . $SS . "\t"
          . $lramastr . "\t"
          . $lramastrext;
        push( @extracted, $extractmotif );
    }    #end PREMOTIF loop

    foreach my $motif (@extracted) {

        # 1      -   EH      14      26      CCFAYIRPLPRAH   EECCCCCCHHHHH  aaabbbaaaaa  aabbbbaaaaa
        my @temp_motif = split /\s+/, $motif;
        unless ( scalar(@temp_motif) == 9 ) {
            warn "Warning: unexpected motif line format:\t$motif\n";
            next;
        }

#check to determine if start/end residue distance matches lenght of sequence (to verify that dssp/pdb sequence info is correct)
        my ($checklength) = &checklength(
            $temp_motif[3], $temp_motif[4], $temp_motif[5],
            $temp_motif[6], $ArrayRef_coordchain
          )
          ; #sending Smotif start, end, residue sequence, ss sequence and PDB coordinates array to subroutine

#check to determine if there is a loop of >= 1 residue between the two secondary structures (definition of an Smotif)
        my ($checkloop) = &checkloop( $temp_motif[6] )
          ;    #sending sequence SS element to subroutine
        if ( $checklength > 0 && $checkloop > 0 ) {
            my ( $loopstart, $loopend ) =
              &start_end_loop( $temp_motif[6], $temp_motif[3],
                $ArrayRef_coordchain )
              ;    #sending ss sequence and Smotif start to subroutine
            my ( $ss1length, $ss2length, $looplength ) =
              &lengthSS_loop( $temp_motif[6] )
              ;    #sending ss sequence to subroutine
            my $retaccepted = join(
                " ",
                (
                    $temp_motif[0], $temp_motif[1], $temp_motif[2],
                    $temp_motif[3], $temp_motif[4], $loopstart,
                    $loopend,       $temp_motif[5], $temp_motif[6],
                    $temp_motif[7], $temp_motif[8], $ss1length,
                    $ss2length,     $looplength
                )
            );
            $rettrue++;
            push( @retacepted, $retaccepted );

        }
        elsif ( $checkloop > 0 && $checklength == 0 ) {
            $missing_residue++;
            warn
"$uploadpdb\t$uploadchain\t$motif\t -> Discarded: missing residues!!!\n";
        }
        elsif ( $checklength > 0 && $checkloop == 0 ) {
            warn "$motif\t -> Discarded: loop length O\n";
        }
        elsif ( $checklength == 0 && $checkloop == 0 ) {
            $missing_residue++;
            warn
"$uploadpdb\t$uploadchain\t$motif\t -> Discarded: missing residues!!!\n";
            warn "$motif\t -> Discarded: loop length O\n";
        }
        else {
			delete_dssp_tmp_files ($uploadpdb, $uploadchain);
            die "There was error: logic error in checkloop and checklength";

            # orginal code
            # return;
        }
    }    #end foreach loop

    return ( $missing_residue, $rettrue, @retacepted );

}    #end extract_SSS subroutine

################################################################
##### CHECKED

sub start_end_loop {

    my ( $ssseq, $motifstart, $ArrayRef_coordchain ) = @_;
    my $ss1lng     = 0;
    my $looplength = 0;
    my @sselements = split //, $ssseq;
    my $motifres   = "first";
    foreach my $ele (@sselements) {
        if ( $ele ne "C" && $motifres eq "first" ) {
            $ss1lng++;
        }
        if ( $ele eq "C" ) {
            $motifres = "second";
            $looplength++;
        }
    }
    my $loopstart;
    my $loopend;
    my $InRange = 0;
    my $count   = 0;
  PDBLINE: foreach my $line (@$ArrayRef_coordchain) {
        next PDBLINE unless ( $line =~ /^(ATOM|HETATM)/ );
        my ($HashRef_CoordRecord);
        if ( $line =~ /^ATOM/ ) {
            $HashRef_CoordRecord =
              SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBAtomRecordFields($line);
        }
        elsif ( $line =~ /^HETATM/ ) {
            $HashRef_CoordRecord =
              SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBHetatmRecordFields($line);
        }
        else {
            die  "There was error: unexpected line-start\n\t$line";
            
        }
        unless ( ( exists( $$HashRef_CoordRecord{'AtomName'} ) )
            && ( exists( $$HashRef_CoordRecord{'ResidueNumber'} ) )
            && ( exists( $$HashRef_CoordRecord{'ResidueInsertionCode'} ) ) )
        {
            die
"There was error: no atom name or res num or insertion code in returned hash\n\t$line\n";
           # return;
        }
        my $AtomType = $$HashRef_CoordRecord{'AtomName'};
        next PDBLINE unless ( $AtomType eq 'CA' );
        my $num           = $$HashRef_CoordRecord{'ResidueNumber'};
        my $insert        = $$HashRef_CoordRecord{'ResidueInsertionCode'};
        my $residuenumber = $num . $insert;
        $residuenumber =~ s/\s+//g;
        if ( $residuenumber eq $motifstart ) {
            $InRange = 1;
            $count++;
        }
        if ($InRange) {
            $count++;
            if ( $count == $ss1lng + 1 ) {
                $loopstart = $residuenumber;
            }
            if ( $count == ( $ss1lng + $looplength ) ) {
                $loopend = $residuenumber;
                last;
            }
        }
        else {
            next PDBLINE;
        }

    }    #end PDBLINE loop

    return ( $loopstart, $loopend );

}
################################################################
##### CHECKED
#####################MUST CHANGE THIS SUBROUTINE TO WORK WITH PDB FILE
sub checklength {
    my ( $start, $end, $ressequence, $sssequence, $ArrayRef_coordchain ) = @_
      ; #smotif start residue, end residue, aa sequence, secondary structure sequence, pdb coord records for chain
    unless ( defined($start)
        && defined($end)
        && defined($ressequence)
        && defined($sssequence)
        && defined($ArrayRef_coordchain) )
    {
        die "There was error: arguments for checklength subroutine\n";
       # return;
    }
    my $checklength;

    #count insertions in the start-end range
    my $numinsertions = 0;
    my $InRange       = 0;
    my $rescount      = 0;
    my %CAcoords;
    my $firstresnum = 'NA';
    my $lastresnum  = 'NA';
  PDBLINE: foreach my $line (@$ArrayRef_coordchain) {

        #get the coordinate line info for any ATOM or HETATM record
        next PDBLINE unless ( $line =~ /^(ATOM|HETATM)/ );
        my ($HashRef_CoordRecord);
        if ( $line =~ /^ATOM/ ) {
            $HashRef_CoordRecord =
              SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBAtomRecordFields($line);
        }
        elsif ( $line =~ /^HETATM/ ) {
            $HashRef_CoordRecord =
              SmotifTF::PDB::PDBCoordinateSectionParse::GetPDBHetatmRecordFields($line);
        }
        else {
            die "There was error: unexpected line-start\n\t$line\n";
           # return;
        }
        unless ( ( exists( $$HashRef_CoordRecord{'AtomName'} ) )
            && ( exists( $$HashRef_CoordRecord{'ResidueNumber'} ) )
            && ( exists( $$HashRef_CoordRecord{'ResidueInsertionCode'} ) ) )
        {
            die
"There was error: no atom name or res num or insertion code in returned hash\n\t$line\n";
           # return;
        }

        #check the CA atoms
        my $AtomType = $$HashRef_CoordRecord{'AtomName'};
        next PDBLINE unless ( $AtomType eq 'CA' );

        #get the current residue PDB number (number and insert code)
        #when the smotif start residue/insert code is encountered, set InRange=1
        my $num           = $$HashRef_CoordRecord{'ResidueNumber'};
        my $insert        = $$HashRef_CoordRecord{'ResidueInsertionCode'};
        my $residuenumber = $num . $insert;
        $residuenumber =~ s/\s+//g;
        if ( $residuenumber eq $start ) {
            $InRange = 1;
        }

        #if the parseing is in the coordinates for the smotif
        if ($InRange) {

            #check to see if there is an insertion code.
            #this is used to count the number of insertions.
            if ( $insert !~ /\s+/ ) { $numinsertions++; }
            if ( $insert =~ /\s+/ ) {

                #set first and last PDB residue numbers
                if ( $firstresnum eq 'NA' ) {
                    $firstresnum = $num;
                }
                $lastresnum = $num;
            }

            #increase the residue count line and take the CA coords
            $rescount++;
            if ( !exists( $CAcoords{"$rescount"} ) ) {
                my @coordsarray;
                my $x = $$HashRef_CoordRecord{'X'};
                push @coordsarray, $x;
                my $y = $$HashRef_CoordRecord{'Y'};
                push @coordsarray, $y;
                my $z = $$HashRef_CoordRecord{'Z'};
                push @coordsarray, $z;
                $CAcoords{"$rescount"} = \@coordsarray;
            }
            else {
                die "There was error: rescoord already exists in hash\n";
               # return;
            }
        }

        #when the smotif end residue/insert code is encountered, set InRange=0;
        #end parsing at the smotif end residue/insert code
        if ( $residuenumber eq $end ) {
            $InRange = 0;
            last;
        }

    }    #end PDBLINE loop

#compare the actual length of the smotifs (residues and secondary structre counting)
#to the PDB residue numbering to determine if it correlates with residue lengths
    my $resseqlength = length($ressequence);
    my $ssseqlength  = length($sssequence);
    unless ( $resseqlength == $ssseqlength ) {
        #print "num of residues does not equal SS assignment length\n";
        die "num of residues does not equal SS assignment length";
        
    }

    my $startendlength;
    if ( ( $firstresnum ne 'NA' ) and ( $lastresnum ne 'NA' ) ) {
        $startendlength =
          ( ( $lastresnum - $firstresnum ) + 1 ) + $numinsertions;
    }
    elsif ( ( $firstresnum eq 'NA' ) and ( $lastresnum eq 'NA' ) ) {
        $startendlength = $numinsertions;
    }
    else {
        #print "logic at line 827\n";
        die "There was error: logic at line 827";
        
    }

    my $uninterrupted; 
    if ( $resseqlength == $startendlength ) {
        $checklength = 1;
    }
    else {
    #is this a chain break or a gap in the residue numbering? check CA distances
        $uninterrupted = CheckCaDistances( \%CAcoords, $startendlength );
        if ( $uninterrupted == 0 ) {
            $checklength = 0;
        }
        elsif ( $uninterrupted == 1 ) {
            $checklength = 1;
        }
        else {
            #print "logic error\n";
            die "There was error: logic error";
            
        }
    }

    return ($checklength);

}    #end checklenght subroutine

sub CheckCaDistances {
    my ( $HashRef_CAcoords, $startendlength ) = @_;

    #unless ( defined($HashRef_CAcoords) && defined($startendlength) ) {
    #    print "arguments for CheckCaDistances subroutine\n";
    #    return;
    #}
    die "HashRef_CAcoords is required" unless $HashRef_CAcoords;
    die "startendlength is required"   unless $startendlength;

    my $uninterrupted = 1;
    for (
        my $resnum = 1 ;
        $resnum < ( scalar( keys(%$HashRef_CAcoords) ) ) ;
        $resnum++
      )
    {
        unless ( exists( $$HashRef_CAcoords{"$resnum"} ) ) {
            #print "this resnum doesn't exist in the hash\n";
            die "There was error: this resnum doesn't exist in the hash";
            
        }
        my $ArrayRef_coordsarrayI  = $$HashRef_CAcoords{"$resnum"};
        my $ArrayRef_coordsarrayII = $$HashRef_CAcoords{ $resnum + 1 };

        my $distance = sqrt(
            ( $$ArrayRef_coordsarrayII[0] - $$ArrayRef_coordsarrayI[0] )**2 +
              ( $$ArrayRef_coordsarrayII[1] - $$ArrayRef_coordsarrayI[1] )**2 +
              ( $$ArrayRef_coordsarrayII[2] - $$ArrayRef_coordsarrayI[2] )**2 );

        # if ( $distance > 4.3 ) {
        if ( $distance > DISTANCE ) {
            $uninterrupted = 0;
        }

    }

    unless ( $uninterrupted == 0 or $uninterrupted == 1 ) {
        print "error in value of uninterrupted variable\n";
        die "There was error: error in value of uninterrupted variable";
    }

=for
     $uninterrupted == 0, means break     in the structure
     $uninterrupted == 1, means no breaks in the structure

=cut

    return $uninterrupted;

}
##################################################################
##### CHECKED
sub checkloop {

    my ($sssequence) = @_;

    my $checkloop;
    my $loopcount = 0;

    my @ssarray = split //, $sssequence;
    unless ( scalar(@ssarray) == length($sssequence) ) {
        print "splitting error in checkloop subroutine\n";
        die "There was error: splitting error in checkloop subroutine";
    }

    foreach my $ele (@ssarray) {
        if ( $ele eq "C" ) {
            $loopcount++;
        }
    }

    if ( $loopcount > 0 ) {
        $checkloop = 1;
    }
    else {
        $checkloop = 0;
    }

    return ($checkloop);

}    #end checkloop subroutine
##############################################################
###### CHECKED

sub lengthSS_loop {

    my ($sssequence) = @_;
    my ( $ss1length, $ss2length, $looplength ) = ( 0, 0, 0 );
    my @tmpseq = split //, $sssequence;
    my $ssID = "first";
    foreach my $ele (@tmpseq) {
        if ( $ele eq "E" || $ele eq "H" ) {
            if ( $ssID eq "first" )  { $ss1length++; }
            if ( $ssID eq "second" ) { $ss2length++; }
        }
        if ( $ele eq "C" ) {
            $ssID = "second";
            $looplength++;
        }
    }

    return ( $ss1length, $ss2length, $looplength );

}    #end lengthSS_loop subroutine

#####################################################################
#####CHECKED
sub read_rama_reduced {

# * a: alpha helix
# * l: left handed alpha helix
# * b: beta strand
# * p: parellel beta sheet
# * g: gamma
# * e: epsilon
# * o: others
# * .: undefined
#char  thornton[22]={'.',' ',
#		     'N','I','E','T','S','O','*','M','U','G','F','b','p','x','e','a','l','g','v','X'};
#char  thornton[22]={'.',' ',
#		     'a','a','b','a','e','b','a','e','l','g','a','b','p','x','e','a','l','g','v','X'};
#
#PHI -> X-axis
#PSI -> Y-axis
#			       PHI
#-180 <----------------------   0  --------------------------> 180
    my $rama_map = "b 	b 	x 	p 	o 	e 	e 	e 	e   #+180
b 	b 	x 	p 	o 	e 	e 	e 	e
b 	b 	x 	p 	. 	l 	v 	s 	e
a 	a 	a 	a 	. 	l 	v 	g 	a
a 	a 	a 	a 	. 	l 	v 	g 	a   # 0    #PSI
a 	a 	a 	a 	. 	l 	g 	g 	a
a 	a 	a 	a 	. 	g 	g 	g 	a
e 	a 	a 	a 	o 	e 	e 	e 	e
b 	b 	x 	p 	o 	e 	e 	e 	e   # 180";

    my @binsphi   = qw(-180 -140 -100 -60 -20 20 60 100 140);
    my @binspsi   = qw(140 100 60 20 -20 -60 -100 -140 -180);
    my @ramalines = split( "\n", $rama_map );
    my %lramaplots;
    my $lcont = 0;

    #parse each line of the rama table. this is parsing through the psi values
    foreach my $ramaline (@ramalines) {

        #get the current psi value from the array;
        my $lpsi = $binspsi[$lcont];
        my @lrama = split( " ", $ramaline );

    #get each phi value from the line and put in hash with the current psi value
        for my $lp ( 0 .. $#binsphi ) {
            $lramaplots{ $binsphi[$lp] }{$lpsi} = $lrama[$lp];
        }

        #increase the count for getting the psi value from the array
        $lcont++;
    }

    return (%lramaplots);
}

############################
#####CHECKED
sub read_rama_extended {

# * a: alpha helix
# * l: left handed alpha helix
# * b: beta strand
# * p: parellel beta sheet
# * g: gamma
# * e: epsilon
# * o: others
# * .: undefined
#char  thornton[22]={'.',' ',
#		     'N','I','E','T','S','O','*','M','U','G','F','b','p','x','e','a','l','g','v','X'};
#char  thornton[22]={'.',' ',
#		     'a','a','b','a','e','b','a','e','l','g','a','b','p','x','e','a','l','g','v','X'};
#
#PHI -> X-axis
#PSI -> Y-axis
#			       PHI
#-180 <----------------------   0  --------------------------> 180
    my $rama_map = "b 	b 	x 	p 	o 	M 	e 	e 	e   #+180
b 	b 	x 	p 	o 	M 	M 	e 	e
b 	b 	x 	p 	. 	l 	v 	s 	e
a 	a 	a 	T 	. 	l 	v 	g 	N
N 	a 	a 	a 	. 	U 	v 	g 	N   # 0    #PSI
N 	a 	a 	a 	. 	U 	g 	g 	N
I 	a 	a 	a 	. 	G 	G 	G 	I
e 	F 	F 	F 	o 	e 	e 	e 	e
b 	b 	x 	p 	o 	e 	e 	e 	e   # 180";

    my @binsphi   = qw(-180 -140 -100 -60 -20 20 60 100 140);
    my @binspsi   = qw(140 100 60 20 -20 -60 -100 -140 -180);
    my @ramalines = split( "\n", $rama_map );
    my %lramaplots;
    my $lcont = 0;
    foreach my $ramaline (@ramalines) {

        #get the current psi value from the array
        my $lpsi = $binspsi[$lcont];
        my @lrama = split( " ", $ramaline );

    #get each phi value from the line and put in hash with the current psi value
        for my $lp ( 0 .. $#binsphi ) {
            $lramaplots{ $binsphi[$lp] }{$lpsi} = $lrama[$lp];
        }
        $lcont++;
    }
    return (%lramaplots);
}

#########################
##### CHECKED

sub bin_phi_psi_angles {

    my ( $lphi, $lpsi ) = @_;

    #PHI
    if ( $lphi >= -180 && $lphi < -140 ) {
        $lphi = -180;
    }
    elsif ( $lphi >= -140 && $lphi < -100 ) {
        $lphi = -140;
    }
    elsif ( $lphi >= -100 && $lphi < -60 ) {
        $lphi = -100;
    }
    elsif ( $lphi >= -60 && $lphi < -20 ) {
        $lphi = -60;
    }
    elsif ( $lphi >= -20 && $lphi < 20 ) {
        $lphi = -20;
    }
    elsif ( $lphi >= 20 && $lphi < 60 ) {
        $lphi = 20;
    }
    elsif ( $lphi >= 60 && $lphi < 100 ) {
        $lphi = 60;
    }
    elsif ( $lphi >= 100 && $lphi < 140 ) {
        $lphi = 100;
    }
    elsif ( $lphi >= 140 && $lphi <= 180 ) {
        $lphi = 140;
    }
    else {
        print "phi binning logic error\n\t$lphi can't be binned\n";
        die "There was error: phi binning logic error\n\t$lphi can't be binned";
    }

    #PSI
    if ( $lpsi >= -180 && $lpsi < -140 ) {
        $lpsi = -180;
    }
    elsif ( $lpsi >= -140 && $lpsi < -100 ) {
        $lpsi = -140;
    }
    elsif ( $lpsi >= -100 && $lpsi < -60 ) {
        $lpsi = -100;
    }
    elsif ( $lpsi >= -60 && $lpsi < -20 ) {
        $lpsi = -60;
    }
    elsif ( $lpsi >= -20 && $lpsi < 20 ) {
        $lpsi = -20;
    }
    elsif ( $lpsi >= 20 && $lpsi < 60 ) {
        $lpsi = 20;
    }
    elsif ( $lpsi >= 60 && $lpsi < 100 ) {
        $lpsi = 60;
    }
    elsif ( $lpsi >= 100 && $lpsi < 140 ) {
        $lpsi = 100;
    }
    elsif ( $lpsi >= 140 && $lpsi <= 180 ) {
        $lpsi = 140;
    }
    else {
        die "There was error: psi binning logic error\n\t$lpsi can't be binned";
    }

    return ( $lphi, $lpsi );

}    #end bin_phi_psi_angles subroutine

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>. 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GetSMotifsfromPDB

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
