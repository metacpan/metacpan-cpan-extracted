package SmotifTF::GeometricalCalculations;

use 5.8.8;
use strict;
use warnings;
BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.01";

    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT_OK = qw(
	calc_geom 
	exist_pdb_code_on_obsoletes 
	exist_pdb_code_on_uncompressed 
    exist_pdb_code_on_alternate
	get_full_path_name_for_pdb_code
    get_full_path_name_for_pdb_code_alternate
     _getReadingFileHandle
	get_from_file 
	translate 
	convert 
	COM 
	COM2 
	calculate_axis 
	get_axis 
	calc_I 
	calc_evec 
	projectpoint 
	det 
	find_eigs 
	matmul 
	matvec 
	vecvec 
	find_roots 
	rotateaxis 
	rotate 
	cross 
	dot 
	unit 
	norm 
	vecadd 
	max 
	min 
	dbin 
	angbin 
	pearson 
	find_rmsd 
	superpose 
	dihedral 
	findcb 
	findo 
	pointsonsphere 
	norm2 
    );

    @EXPORT = qw(
    );    # symbols to export on request
}
our @EXPORT_OK;
our $DEBUG = 0;

use Math::Trig;
use Storable qw(dclone);
use Carp;
use IO::Uncompress::Gunzip qw(gunzip);
use File::Spec::Functions qw(catfile);

use Config::Simple;
# accessing a block of an ini-file;
my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set" unless $config_file;

my $cfg              = new Config::Simple($config_file);
my $PDB              = $cfg->param( -block => 'pdb' );
my $PDB_DIR          = $PDB->{'uncompressed'};
my $PDB_OBSOLETES    = $PDB->{'obsoletes'};
my $USER_SPECIFIC_PDB_PATH = $PDB->{'user_specific_pdb_path'};

my $host = "";

=head1 NAME

GeometricalCalculations

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module consists of subroutines that carry out geometrical calculations
using the atomic coordinates obtained from a protein structure. 

=head2 calc_geom 
	
	subroutine  to calculate delta, theta, and rho angles for an smotif
	
    Input 1: $lvec - vector between the anchor points of the bracing secondary structures
	Input 2: $e1 - axis vector for 1st secondary structure
	Input 3: $e2 - axis vector for 2nd secondary structure

=cut
sub calc_geom {
    my ( $lvec, $e1, $e2 ) = @_;
    my $rad    = 180 / 3.14159265;
    my $delta  = ( Math::Trig::acos( dot( @$e1, @$lvec ) ) ) * $rad;
    my $theta  = ( Math::Trig::acos( dot( @$e1, @$e2 ) ) ) * $rad;
    my $rho    = 0;
    my @normal = unit( cross( @$lvec, @$e1 ) );
    my @target = cross( @$e1, @normal );
    my $check  = norm(@target);
    if ( $check ne 0 ) {
        my $proj = dot( @$e1, @$e2 );
        my @proj = (
            $$e2[0] - $proj * $$e1[0],
            $$e2[1] - $proj * $$e1[1],
            $$e2[2] - $proj * $$e1[2]
        );
        my $dproj = norm(@proj);
        if ( $dproj ne 0 ) {
            $rho = Math::Trig::acos( dot( @proj, @normal ) / $dproj ) * $rad;
            if ( dot( @proj, @target ) < 0 ) { $rho = 360 - $rho }
        }
    }
    return ( $delta, $theta, $rho );
}

=head2 _getReadingFileHandle
	subroutine to get a reading file handle
        for a file.

        input: file path name to the file 
=cut
sub _getReadingFileHandle {
    use IO::Uncompress::Gunzip qw(gunzip);

    my $file = shift;
    die "path_name files is required" unless $file;

    my $fh;
    if ( $file =~ /\.gz$/ ) {
        $fh = new IO::Uncompress::Gunzip $file || die("Cannot open $file");
    }
    else {
        open( $fh, "< $file" ) || die("Cannot open $file");
    }
    return $fh;
}

=head2 exist_pdb_code_on_obsoletes
	check if a four-letters pdb code exist in PDB obsoletes folder
	it will return the full path name if a match is found.
	return undef if not file was found
	
        exist_pdb_code_on_obsoletes
	input  : pdb_code (4fab), chain_id
	return : full path name

=cut
sub exist_pdb_code_on_obsoletes {
    my ($pdb_code, $chain) = @_;
    croak "exist_pdb_code_on_obsoletes: pdb_code is required" unless $pdb_code;
	croak "exist_pdb_code_on_obsoletes: chain is required" unless defined $chain;

    chomp $pdb_code;
    croak "$pdb_code does not look like a four-letter PDB_CODE"
      unless $pdb_code =~ /[A-z0-9]{4}/;

    my $pdb_file_name    = "pdb" . $pdb_code . '.ent';
    my $pdb_file_name_gz = "pdb" . $pdb_code . '.ent.gz';

	my $pdb_file_name_ch    = 'pdb' . $pdb_code . $chain . '.ent';
    my $pdb_file_name_ch_gz = 'pdb' . $pdb_code . $chain . '.ent.gz';

    my $uncompressed = catfile ($PDB_OBSOLETES, $pdb_file_name);
    my $compressed   = catfile ($PDB_OBSOLETES, $pdb_file_name_gz);

	my $uncompressed_ch = catfile ($PDB_OBSOLETES, $pdb_file_name_ch);
    my $compressed_ch   = catfile ($PDB_OBSOLETES, $pdb_file_name_ch_gz);

    # try uncompressed pdb filename existence
    if ( -e $uncompressed ) {
        return $uncompressed;
    }
    # try compressed file
    elsif ( -e $compressed ) {
        return $compressed;
    }
	# try uncompressed file with chain
	elsif ( -e $uncompressed_ch ) {
        return $uncompressed_ch;
    }
	# try compressed file with chain
	elsif ( -e $compressed_ch ) {
        return $compressed_ch;
    }
    else {
        return undef;
    }
}

=head2 exist_pdb_code_on_uncompressed

	check if a four-letters pdb code exist in uncompressed PDB folder
	it will return the full path name if a match is found.
	Return undef if not file was found
	
        input  : pdb_code (4fab), chain_id
	return : full path name

=cut
sub exist_pdb_code_on_uncompressed {
    my ($pdb_code, $chain) = @_;
    croak "exist_pdb_code_on_uncompressed: pdb_code is required" unless $pdb_code;
	croak "exist_pdb_code_on_uncompressed: chain is required" unless defined $chain;

    chomp $pdb_code;
    croak "$pdb_code does not look like a four-letter PDB_CODE"
      unless $pdb_code =~ /[A-z0-9]{4}/;

    my $pdb_file_name    = "pdb" . $pdb_code . '.ent';
    my $pdb_file_name_gz = "pdb" . $pdb_code . '.ent.gz';

    my $pdb_file_name_ch    = 'pdb' . $pdb_code . $chain . '.ent';
    my $pdb_file_name_ch_gz = 'pdb' . $pdb_code . $chain . '.ent.gz';

	my $uncompressed = catfile ($PDB_DIR, $pdb_file_name);
 	my $compressed   = catfile ($PDB_DIR, $pdb_file_name_gz);

	my $uncompressed_ch = catfile ($PDB_DIR, $pdb_file_name_ch);
    my $compressed_ch   = catfile ($PDB_DIR, $pdb_file_name_ch_gz);

    # try uncompressed pdb filename existence
    if ( -e $uncompressed ) {
        return $uncompressed;
    }
    # try compressed file
    elsif ( -e $compressed ) {
        return $compressed;
    }
	# try uncompressed file with chain
	elsif ( -e $uncompressed_ch ) {
        return $uncompressed_ch;
    }
    #try compressed file with chain
    elsif ( -e $compressed_ch ) {
    	return $compressed_ch;
    }	
    else {
        return undef;
    }
}

=head2 exist_pdb_code_on_alternate

	check if a four-letters pdb code exist in user defined alternate 
	PDB folder
        it will return the full path name if a match is found.
	Return undef if not file was found
	
        input  : pdb_code (4fab), chain_id
	return : full path name

=cut
sub exist_pdb_code_on_alternate { 
    my ($pdb_code, $chain) = @_;
    croak "exist_pdb_code_on_alternate: pdb_code is required" unless $pdb_code;
	croak "exist_pdb_code_on_alternate: chain is required" unless defined $chain;

    chomp $pdb_code;
    croak "$pdb_code does not look like a four-letter PDB_CODE"
      unless $pdb_code =~ /[A-z0-9]{4}/;

    my $pdb_file_name    = 'pdb' . $pdb_code . '.ent';
    my $pdb_file_name_gz = 'pdb' . $pdb_code . '.ent.gz';
	
	my $pdb_file_name_ch    = 'pdb' . $pdb_code . $chain . '.ent';
    my $pdb_file_name_ch_gz = 'pdb' . $pdb_code . $chain . '.ent.gz';

    my $uncompressed = catfile ($USER_SPECIFIC_PDB_PATH, $pdb_file_name);
    my $compressed   = catfile ($USER_SPECIFIC_PDB_PATH, $pdb_file_name_gz);

	my $uncompressed_ch = catfile ($USER_SPECIFIC_PDB_PATH, $pdb_file_name_ch);
	my $compressed_ch   = catfile ($USER_SPECIFIC_PDB_PATH, $pdb_file_name_ch_gz);

    # try uncompressed pdb filename existence
    if ( -e $uncompressed ) {
        return $uncompressed;
    }
    # try compressed file
    elsif ( -e $compressed ) {
        return $compressed;
    }
	#try uncompressed file with chain
	elsif ( -e $uncompressed_ch ) {
 		return $uncompressed_ch;
	}
	#try compressed file with chain
	elsif ( -e $compressed_ch ) {
 		return $compressed_ch;
 	}
    else {
        return undef;
    }
}

=head2 get_full_path_name_for_pdb_code_alternate
	Return a fullpath name for a given four-letter PDB code	
        It will look in USER_SPECIFIC PDB directory

        die if not match found

=cut
sub get_full_path_name_for_pdb_code_alternate {
    use Data::Dumper;
    my ($pdb_code, $chain) = @_;
   
    if ($DEBUG){
	    my  ($package, $filename, $line) = caller;
	    print "package  = $package\n";
	    print "filename = $filename\n";
	    print "line     = $line\n";
	    print Dumper(\@_);
    }

    croak "get_full_path_name_for_pdb_code_alternate: pdb_code is required" unless $pdb_code;
    croak "get_full_path_name_for_pdb_code_alternate: Chain ID is required" unless $chain;

    chomp $pdb_code;
    croak "$pdb_code does not look like a four-letter PDB_CODE"
      unless $pdb_code =~ /[A-z0-9]{4}/;

    my $path;
    
    $path = exist_pdb_code_on_alternate($pdb_code, $chain);
    return $path if $path;

    croak "Could not find $pdb_code $chain on $USER_SPECIFIC_PDB_PATH"
      unless $path;
}

=head2 get_full_path_name_for_pdb_code
    Return a fullpath name for a given four-letter PDB code 
        It will look in obsoletes and uncompressed directories

        die if not match found

=cut
sub get_full_path_name_for_pdb_code {
    use Data::Dumper;
    my ($pdb_code, $chain) = @_;

    if ($DEBUG){
        my  ($package, $filename, $line) = caller;
        print "package  = $package\n";
        print "filename = $filename\n";
        print "line     = $line\n";
        print Dumper(\@_);
    }

    croak "get_full_path_name_for_pdb_code: pdb_code is required" unless $pdb_code;
	croak "get_full_path_name_for_pdb_code: pdb_code is required" unless defined $chain;

    chomp $pdb_code;
    croak "$pdb_code does not look like a four-letter PDB_CODE"
      unless $pdb_code =~ /[A-z0-9]{4}/;

    my $path;
    $path = exist_pdb_code_on_uncompressed($pdb_code, $chain);
    return $path if $path;

    $path = exist_pdb_code_on_obsoletes($pdb_code, $chain);
    return $path if $path;

    $path = exist_pdb_code_on_alternate($pdb_code, $chain);
    return $path if $path;

    croak "Could not find $pdb_code on $PDB_DIR or $PDB_OBSOLETES or $USER_SPECIFIC_PDB_PATH"
      unless $path;
}

=head2 get_from_file

	subroutine to read PDB file and obtain coordinates of backbone atoms.
	
        Input 1: @$data - smotif info (pdb ID, chain ID, start residue, ss1 length, ss2 length, loop length)
	Input/Output 2: @$landmarks - output array with smotif landmarks (0, loop start, ss2 start, ss2 end)
	Input 3: $string - backbone atom (CA, CB, C, N, or O)
	Input/Output 4: $seq - smotif sequence
   
       $VAR1 = [
          '/usr/local/databases/pdb//uncompressed/pdb2kl8.ent.gz',
          'A',
          2,
          7,
          17,
          3,
          0,
          'EH'
        ];


=cut
sub get_from_file {
    my ( $data, $landmarks, $string, $seq ) = @_;

    # data contains pdbid, chain, start, ss1, ss2
    use Data::Dumper;
    use File::Basename;
    #print Dumper($data);

    my $chain    = $$data[1];
    my $startres = $$data[2];
    my $endres   = $$data[2] + $$data[5] + $$data[3] + $$data[4] - 1;
    @$landmarks =
      ( $$data[3], $$data[3] + $$data[5], $$data[3] + $$data[5] + $$data[4] );

    # $$data[0] has values like this:
    # 2kl8/pdb2kl8.ent
    my $pdb_code;
    
    if ( $$data[0] =~ /\// ) {
        # $pdb_code = ( split( /\//, $$data[0] ) )[0];
        my $filename = basename $$data[0];
        if ( $filename =~ /pdb(\w{4}).*/ ) {
            $pdb_code =  $1;
        } 
        elsif ( $filename =~ /(\w{4}).*/ ) {
            $pdb_code =  $1;
        }
        else {} 
    }
    else {
        $pdb_code = $$data[0];
        $pdb_code =~ s/^pdb//g;     # removing leading pdb string
        $pdb_code =~ s/\.(\w+)$//g; # removing file extension
    }
    
    #unless ( $$data[0] ) {
    #   use Data::Dumper;
    #   print "pdb_code $pdb_code\n";
    #   print Dumper($data);
    #   #croak "get_from_file: pdb_code is required";
    #}


    my $full_path_name = get_full_path_name_for_pdb_code($pdb_code, $chain);
    my $fh             = _getReadingFileHandle($full_path_name);

    my $done    = 0;
    my @coords  = ();
    my $prevres = 0;
    my $len     = length($string);
    my $id      = $prevres;
    if ( $string ne 'CB' )
    { #certain residues (GLY) will not have CBs, so this case has to be treated separately
        while ( defined( my $line = <$fh> ) and ( $done == 0 ) ) {
            chomp($line);
            if ( $line =~
                /ATOM\s+-*\d+\s+$string\s+(\w+)\s$chain\s*(-*\d+\w?\s)/ )
            {
                $id = $2;
                my $amino = $1;
                if ( $id =~ /(-*\d+)\D/ ) { $id = $1 }
                if ( $id ne $prevres ) {
                    if ( $id > $endres ) {
                        $done = 1;
                    }
                    elsif ( $id >= $startres ) {
                        push(
                            @coords,
                            [
                                substr( $line, 30, 8 ),
                                substr( $line, 38, 8 ),
                                substr( $line, 46, 8 )
                            ]
                        );

                        #print "$line\t$amino\n";
                        $$seq = $$seq . translate($amino);

                        #print "$line\n";
                    }
                }
                $prevres = $id;
            }
        }
    }
    else {
        $$seq = '';
        my $prevline = <$fh>;
        while ( defined( my $line = <$fh> ) and ( $done == 0 ) ) {
            chomp($line);
            if ( $line =~ /ATOM\s+-*\d+\s+CB\s+(\w+)\s$chain\s*(-*\d+\w?\s)/ ) {
                $id = $2;
                my $amin = substr( $1, -3, 3 );
                if ( $id =~ /(-*\d+)\D/ ) { $id = $1 }
                if ( $id ne $prevres ) {
                    if ( $id > $endres ) {
                        $done = 1;
                    }
                    elsif ( $id >= $startres ) {
                        push(
                            @coords,
                            [
                                substr( $line, 30, 8 ),
                                substr( $line, 38, 8 ),
                                substr( $line, 46, 8 )
                            ]
                        );
                        $$seq = $$seq . translate($amin);

                        #print "$line\t$startres\t$endres\n";
                    }
                }
                $prevres = $id;
            }
            elsif (
                $prevline =~ /ATOM\s+-*\d+\s+O\s+(\w+)\s$chain\s*(-*\d+\w?\s)/ )
            {
                $id = $2;
                my $amin = substr( $1, -3, 3 );
                if ( $id =~ /(-*\d+)\D/ ) { $id = $1 }
                if ( $id ne $prevres ) {
                    if ( $id > $endres ) {
                        $done = 1;
                    }
                    elsif ( $id >= $startres ) {
                        push( @coords, 0 );
                        $$seq = $$seq . translate($amin);
                    }
                }
                $prevres = $id;
            }
            $prevline = $line;
        }
    }
    close($fh);
    return @coords;
}

=head2

	translate 
	subroutine to convert from 3-letter codes to 1-letter codes

=cut
sub translate {
    my ($inp) = @_;
    my $out;
    if    ( $inp eq 'ALA' ) { $out = 'A' }
    elsif ( $inp eq 'CYS' ) { $out = 'C' }
    elsif ( $inp eq 'ASP' ) { $out = 'D' }
    elsif ( $inp eq 'GLU' ) { $out = 'E' }
    elsif ( $inp eq 'PHE' ) { $out = 'F' }
    elsif ( $inp eq 'GLY' ) { $out = 'G' }
    elsif ( $inp eq 'HIS' ) { $out = 'H' }
    elsif ( $inp eq 'ILE' ) { $out = 'I' }
    elsif ( $inp eq 'LYS' ) { $out = 'K' }
    elsif ( $inp eq 'LEU' ) { $out = 'L' }
    elsif ( $inp eq 'MET' ) { $out = 'M' }
    elsif ( $inp eq 'ASN' ) { $out = 'N' }
    elsif ( $inp eq 'PRO' ) { $out = 'P' }
    elsif ( $inp eq 'GLN' ) { $out = 'Q' }
    elsif ( $inp eq 'ARG' ) { $out = 'R' }
    elsif ( $inp eq 'SER' ) { $out = 'S' }
    elsif ( $inp eq 'THR' ) { $out = 'T' }
    elsif ( $inp eq 'VAL' ) { $out = 'V' }
    elsif ( $inp eq 'TRP' ) { $out = 'W' }
    else                    { $out = 'Y' }
    return $out;
}

=head2 convert 

	subroutine to convert from 1-letter codes to 3-letter codes

=cut
sub convert {
    my ($aa) = @_;
    if ( $aa eq 'A' ) { return 'ALA' }
    if ( $aa eq 'C' ) { return 'CYS' }
    if ( $aa eq 'D' ) { return 'ASP' }
    if ( $aa eq 'E' ) { return 'GLU' }
    if ( $aa eq 'F' ) { return 'PHE' }
    if ( $aa eq 'G' ) { return 'GLY' }
    if ( $aa eq 'H' ) { return 'HIS' }
    if ( $aa eq 'I' ) { return 'ILE' }
    if ( $aa eq 'K' ) { return 'LYS' }
    if ( $aa eq 'L' ) { return 'LEU' }
    if ( $aa eq 'M' ) { return 'MET' }
    if ( $aa eq 'N' ) { return 'ASN' }
    if ( $aa eq 'P' ) { return 'PRO' }
    if ( $aa eq 'Q' ) { return 'GLN' }
    if ( $aa eq 'R' ) { return 'ARG' }
    if ( $aa eq 'S' ) { return 'SER' }
    if ( $aa eq 'T' ) { return 'THR' }
    if ( $aa eq 'V' ) { return 'VAL' }
    if ( $aa eq 'W' ) { return 'TRP' }
    if ( $aa eq 'Y' ) { return 'TYR' }
}

=head2 COM

	subroutine to find the centre of mass of a set of points, presented in 3 vectors

=cut
sub COM {
    my ( $start, $end, $ca, $n, $c ) = @_;
    my @tots = ( 0, 0, 0 );
    my $count = 3 * ( $end - $start );
    for ( my $a = $start ; $a < $end ; $a++ ) {

        #		print $$ca[$a][0], "\n";
        $tots[0] = $tots[0] + $$ca[$a][0] + $$n[$a][0] + $$c[$a][0];
        $tots[1] = $tots[1] + $$ca[$a][1] + $$n[$a][1] + $$c[$a][1];
        $tots[2] = $tots[2] + $$ca[$a][2] + $$n[$a][2] + $$c[$a][2];
    }
    return ( $tots[0] / $count, $tots[1] / $count, $tots[2] / $count );
}

=head2 COM2

	subroutine to find the centre of mass of a set of points, presented as a single vector

=cut
sub COM2 {
    my ( $start, $end, $c ) = @_;
    my @tots = ( 0, 0, 0 );
    my $count = $end - $start;
    for ( my $a = $start ; $a < $end ; $a++ ) {
        $tots[0] += $$c[$a][0];
        $tots[1] += $$c[$a][1];
        $tots[2] += $$c[$a][2];
    }
    return ( $tots[0] / $count, $tots[1] / $count, $tots[2] / $count );
}

=head2 calculate_axis

	subroutine to calculate the principal axis of a set of points 
	(corresponds to the principal eigenvector for the moment matrix)

=cut
sub calculate_axis {
    my ( $type, $ca, $n, $c ) = @_;
    my @ca2   = @$ca;
    my @n2    = @$n;
    my @c2    = @$c;
    my $count = scalar(@ca2);
    my @com   = COM( 0, $count, \@ca2, \@n2, \@c2 );
    for ( my $a = 0 ; $a < $count ; $a++ ) {
        $ca2[$a][0] -= $com[0];
        $ca2[$a][1] -= $com[1];
        $ca2[$a][2] -= $com[2];
        $n2[$a][0]  -= $com[0];
        $n2[$a][1]  -= $com[1];
        $n2[$a][2]  -= $com[2];
        $c2[$a][0]  -= $com[0];
        $c2[$a][1]  -= $com[1];
        $c2[$a][2]  -= $com[2];
    }
    my @p = ( [@ca2], [@n2], [@c2] );

    #find moment of inertia matrix
    my @I = calc_I( $type, $count, @p );

    #find principal eigenvector
    my @eigs = find_eigs(@I);
    my @evec = calc_evec( $eigs[2], @I );

    #check direction of axis by looking at max eigenvec, difference
    my $i = 2;
    if (    ( abs( $evec[0] ) >= abs( $evec[1] ) )
        and ( abs( $evec[0] ) >= abs( $evec[2] ) ) )
    {    #x-coord is max
        $i = 0;
    }
    elsif ( abs( $evec[1] ) >= abs( $evec[2] ) ) {    #y-coord is max
        $i = 1;
    }
    if ( ( $evec[$i] * ( $p[0][-1][$i] - $p[0][0][$i] ) ) < 0 ) {
        return ( -$evec[0], -$evec[1], -$evec[2] );
    }
    else {
        return @evec;
    }
}

=head2 get_axis
	subroutine to find the axis vector of a secondary structure, 
	using at least 4 residues for a helix or 2 for a strand
	
        Input 1: Type of secondary structure (H=Helix, E=strand)
	Input 2: Option to indicate whether the secondary structure is the first (1) or second (2) part of the smotif
	Input 3: Initial residue number of the secondary structure
	Input 4: Final residue number of the secondar structure
	Input 5-7: Vectors containing the coordinates of C-alpha atoms, N atoms, and C atoms of the smotif

=cut
sub get_axis {
    my ( $type, $ss, $first, $last, $ca, $n, $c ) = @_;
    my $ang = 0;
    my @newaxis;
    my @oldaxis;
    my $j;
    my @use_ca;
    my @use_n;
    my @use_c;
    my $count = $last - $first;
    my $beg   = 0;
    my $end   = 0;
    my $lim   = 5 * 3.14159265 / 180;
    my $term  = 8;
    my $stop  = 3;

    if ( $type eq 'H' ) {
        $stop = 9;
        $term = 100;
    }
    if ( $ss == 1 )
    {    #first ss of motif, measure axis from the loop side (end of ss)
        $beg = max( $last - $stop, $first );
        $end = $last;
    }
    else {
        $beg = $first
          ; #second ss of motif, measure axis from the loop side (beginning of ss)
        $end = min( $first + $stop, $last );
    }
    for ( my $aa = $beg ; $aa < $end ; $aa++ ) {
        push( @use_ca, [ ( $$ca[$aa][0], $$ca[$aa][1], $$ca[$aa][2] ) ] );
        push( @use_n,  [ ( $$n[$aa][0],  $$n[$aa][1],  $$n[$aa][2] ) ] );
        push( @use_c,  [ ( $$c[$aa][0],  $$c[$aa][1],  $$c[$aa][2] ) ] );
    }
    @newaxis = calculate_axis( $type, \@use_ca, \@use_n, \@use_c );
    $j       = $stop;
    @oldaxis = @newaxis;
    while ( ( $j < $count ) and ( $ang < $lim ) and ( $j < $term ) )
    {       #so long as the ss does not curve too much, keep measuring axis
        $j++;
        @use_ca = ();
        @use_n  = ();
        @use_c  = ();

        #extend ss from the appropriate side
        if ( $ss == 1 ) {
            $beg = max( $last - $j, $first );
            $end = $last;
        }
        else {
            $beg = $first;
            $end = min( $first + $j, $last );
        }
        for ( my $aa = $beg ; $aa < $end ; $aa++ ) {
            push( @use_ca, [ ( $$ca[$aa][0], $$ca[$aa][1], $$ca[$aa][2] ) ] );
            push( @use_n,  [ ( $$n[$aa][0],  $$n[$aa][1],  $$n[$aa][2] ) ] );
            push( @use_c,  [ ( $$c[$aa][0],  $$c[$aa][1],  $$c[$aa][2] ) ] );
        }
        @oldaxis = @newaxis;
        @newaxis = calculate_axis( $type, \@use_ca, \@use_n, \@use_c );
        $ang     = Math::Trig::acos( dot( @newaxis, @oldaxis ) );
    }
    return @oldaxis;
}

=head2 calc_I 

	subroutine to calculate the matrix of moments from a set of backbone coordinates
	Input 1: Secondary structure type
	Input 2: Number of backbone atoms;
	Input 3: 3-D vector containing the coordinates of C-alpha, N, and C-atoms

=cut
sub calc_I {
    my ( $type, $count, @p ) = @_;
    my @I = ( [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] );
    my @pt;
    if ( $type eq 'H' ) {    #helix, calculate based on each point
        for ( my $atom = 0 ; $atom < 3 ; $atom++ ) {
            for ( my $a = 0 ; $a < $count ; $a++ ) {
                @pt = ( $p[$atom][$a][0], $p[$atom][$a][1], $p[$atom][$a][2] );
                $I[0][0] = $I[0][0] + ( $pt[1]**2 ) + ( $pt[2]**2 );
                $I[1][1] = $I[1][1] + ( $pt[0]**2 ) + ( $pt[2]**2 );
                $I[2][2] = $I[2][2] + ( $pt[0]**2 ) + ( $pt[1]**2 );
                $I[0][1] = $I[0][1] - $pt[0] * $pt[1];
                $I[0][2] = $I[0][2] - $pt[0] * $pt[2];
                $I[1][2] = $I[1][2] - $pt[1] * $pt[2];
            }
        }
    }
    else {    #strand, calculate based on midpts of successive atoms
        for ( my $atom = 0 ; $atom < 3 ; $atom++ ) {
            for ( my $a = 0 ; $a < $count - 1 ; $a++ ) {
                @pt = (
                    0.5 * ( $p[$atom][$a][0] + $p[$atom][ $a + 1 ][0] ),
                    0.5 * ( $p[$atom][$a][1] + $p[$atom][ $a + 1 ][1] ),
                    0.5 * ( $p[$atom][$a][2] + $p[$atom][ $a + 1 ][2] )
                );
                $I[0][0] = $I[0][0] + ( $pt[1]**2 ) + ( $pt[2]**2 );
                $I[1][1] = $I[1][1] + ( $pt[0]**2 ) + ( $pt[2]**2 );
                $I[2][2] = $I[2][2] + ( $pt[0]**2 ) + ( $pt[1]**2 );
                $I[0][1] = $I[0][1] - $pt[0] * $pt[1];
                $I[0][2] = $I[0][2] - $pt[0] * $pt[2];
                $I[1][2] = $I[1][2] - $pt[1] * $pt[2];
            }
        }
    }
    $I[1][0] = $I[0][1];
    $I[2][0] = $I[0][2];
    $I[2][1] = $I[1][2];
    return @I;
}

=head2 calc_evec

	subroutine to calculate the eigenvector of a 3x3 matrix for a given eigenvalue
	Input 1: Eigenvalue
	Input 2: 3x3 matrix

=cut
sub calc_evec {
    my ( $eval, @M ) = @_;

    #subtract off diagonals
    my @I = @{ Storable::dclone( \@M ) };
    $I[0][0] = $I[0][0] - $eval;
    $I[1][1] = $I[1][1] - $eval;
    $I[2][2] = $I[2][2] - $eval;
    my @evec = ( 0, 0, 0 );

    #Find co-factors of first row
    $evec[0] = $I[1][1] * $I[2][2] - $I[1][2] * $I[2][1];
    $evec[1] = $I[1][2] * $I[2][0] - $I[1][0] * $I[2][2];
    $evec[2] = $I[1][0] * $I[2][1] - $I[1][1] * $I[2][0];
    if ( $evec[0]**2 + $evec[1]**2 + $evec[2]**2 < 0.01 ) {

        #Find co-factors of second row
        $evec[0] = $I[0][2] * $I[2][1] - $I[0][1] * $I[2][2];
        $evec[1] = $I[0][0] * $I[2][2] - $I[0][2] * $I[2][0];
        $evec[2] = $I[0][1] * $I[2][0] - $I[0][0] * $I[2][1];
        if ( $evec[0]**2 + $evec[1]**2 + $evec[2]**2 < 0.01 ) {
            $evec[0] = $I[0][1] * $I[1][2] - $I[0][2] * $I[1][1];
            $evec[1] = $I[0][2] * $I[1][0] - $I[0][0] * $I[1][2];
            $evec[2] = $I[0][0] * $I[1][1] - $I[0][1] * $I[1][0];
        }
    }
    return unit(@evec);
}

=head2 

	subroutine to project a point onto an axis, given a point on the line
	Input 1: Cooridnates of the point
	Input 2: Vector representing the axis
	Input 3: A point on the line

=cut
sub projectpoint {
    my ( $p, $v, $c ) = @_;
    my @newp = ( 0, 0, 0 );
    my @padj = ( $$p[0] - $$c[0], $$p[1] - $$c[1], $$p[2] - $$c[2] );
    my $proj = dot( @padj, @$v );
    $newp[0] = $proj * $$v[0] + $$c[0];
    $newp[1] = $proj * $$v[1] + $$c[1];
    $newp[2] = $proj * $$v[2] + $$c[2];
    return @newp;
}

=head2 det

	subroutine to find the determinant of a 3x3 matrix

=cut
sub det {
    my (@m) = @_;
    my $d =
      $m[0][0] * ( $m[1][1] * $m[2][2] - $m[1][2] * $m[2][1] ) -
      $m[0][1] * ( $m[1][0] * $m[2][2] - $m[1][2] * $m[2][0] ) +
      $m[0][2] * ( $m[1][0] * $m[2][1] - $m[1][1] * $m[2][0] );
    return $d;
}

=head2 find_eigs

	subroutine to find the eigenvalues (ordered) of a 3x3 matrix
=cut
sub find_eigs {

    #return eigenvalues
    my (@I) = @_;
    my $a = -1 * ( $I[0][0] + $I[1][1] + $I[2][2] );
    my $b =
      $I[0][0] * $I[2][2] +
      $I[1][1] * $I[2][2] +
      $I[0][0] * $I[1][1] -
      $I[0][2] * $I[2][0] -
      $I[1][2] * $I[2][1] -
      $I[0][1] * $I[1][0];
    my $c = -1 * det(@I);
    my @eigs = find_roots( $a, $b, $c );
    my @temp;
    if ( ( $eigs[0] > $eigs[1] ) and ( $eigs[0] > $eigs[2] ) ) {
        $temp[0] = $eigs[0];
        if ( $eigs[1] > $eigs[2] ) {
            $temp[1] = $eigs[1];
            $temp[2] = $eigs[2];
        }
        else {
            $temp[1] = $eigs[2];
            $temp[2] = $eigs[1];
        }
    }
    elsif ( $eigs[1] > $eigs[2] ) {
        $temp[0] = $eigs[1];
        if ( $eigs[0] > $eigs[2] ) {
            $temp[1] = $eigs[0];
            $temp[2] = $eigs[2];
        }
        else {
            $temp[1] = $eigs[2];
            $temp[2] = $eigs[0];
        }
    }
    else {
        $temp[0] = $eigs[2];
        if ( $eigs[0] > $eigs[1] ) {
            $temp[1] = $eigs[0];
            $temp[2] = $eigs[1];
        }
        else {
            $temp[1] = $eigs[1];
            $temp[2] = $eigs[0];
        }
    }
    return @temp;
}

=head2 matmul

	subroutine to multiply two matrices
	Input 1: Matrix 1
	Input 2: Matrix 2
	Input 3: Number of rows in matrix 1
	Input 4: Number of columns in matrix 1, also the number of rows in matrix 2
	Input 5: Numer of columns in matrix 2

=cut
sub matmul {
    my ( $m, $n, $dim1, $dim2, $dim3 ) = @_;
    my @o;
    my @row;
    for ( my $aa = 0 ; $aa < $dim3 ; $aa++ ) {
        push( @row, 0 );
    }
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        push( @o, [@row] );
    }
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        for ( my $bb = 0 ; $bb < $dim3 ; $bb++ ) {
            for ( my $cc = 0 ; $cc < $dim2 ; $cc++ ) {
                $o[$aa][$bb] += $$m[$aa][$cc] * $$n[$cc][$bb];
            }
        }
    }
    return @o;
}

=head2 matvec
	
	subroutine to multiply a vector by a matrix
	
	Input 1: Matrix
	Input 2: Vector
	Input 3: Number of rows in the matrix
	Input 4: Number of columns in the matrix, also the number of elements in the vector

=cut
sub matvec {
    my ( $m, $n, $dim1, $dim2 ) = @_;
    my @o;
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        push( @o, 0 );
    }
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        for ( my $cc = 0 ; $cc < $dim2 ; $cc++ ) {
            $o[$aa] += $$m[$aa][$cc] * $$n[$cc];
        }
    }
    return @o;
}

=head2 vecvec
 
	subroutine to find the outer product of two vectors of the same length
	Input 1: Vector 1
	Input 2: Vector 2
	Input 3: Dimension of vector 1, also dimension of vector 2

=cut
sub vecvec {
    my ( $m, $n, $dim1 ) = @_;
    my @o;
    my @row;
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        push( @row, 0 );
    }
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        push( @o, [@row] );
    }
    for ( my $aa = 0 ; $aa < $dim1 ; $aa++ ) {
        for ( my $bb = 0 ; $bb < $dim1 ; $bb++ ) {
            $o[$aa][$bb] = $$m[$aa] * $$n[$bb];
        }
    }
    return @o;
}

=head2 find_roots 

	subroutine to find the roots of a cubic equation of the form x^3+ax^2+bx+cx=0

=cut
sub find_roots {
    my ( $a, $b, $c ) = @_;
    my $p = $b - ( $a**2 ) / 3;
    my $q = $c + ( 2 * $a**3 - 9 * $a * $b ) / 27;
    my $urad = ( ( $q**2 ) / 4 + ( $p**3 ) / 27 );
    my $mag = sqrt( 0.25 * ( $q**2 ) - $urad );
    my $newmag = $mag**( 1 / 3 );
    my $ang    = Math::Trig::acos( -0.5 * $q / $mag );
    my $m      = abs( cos( $ang / 3 ) );
    my $n      = abs( sin( $ang / 3 ) * ( 3**(0.5) ) );
    my $x1     = 2 * $newmag * $m - ( $a / 3 );
    my $x2     = -1 * $newmag * ( $m + $n ) - ( $a / 3 );
    my $x3     = -1 * $newmag * ( $m - $n ) - ( $a / 3 );
    return ( $x1, $x2, $x3 );
}

=head2 rotateaxis

	subroutine to rotate a point (pt) around an axis (vec) by a given angle (ang)
=cut
sub rotateaxis {
    my ( $pt, $vec, $ang ) = @_;
    my @res = ( $$pt[0], $$pt[1], $$pt[2] );
    my $cos = cos( $$ang * 3.1415926 / 180 );
    my $sin = sin( $$ang * 3.1415926 / 180 );
    my $uv  = $$vec[0]**2 + $$vec[1]**2;
    my $vw  = $$vec[1]**2 + $$vec[2]**2;
    my $uw  = $$vec[0]**2 + $$vec[2]**2;
    $res[0] =
      ( $$vec[0] * dot( @$pt, @$vec ) ) -
      ( $$vec[0] * ( $$vec[1] * $$pt[1] + $$vec[2] * $$pt[2] ) - $$pt[0] * $vw )
      * $cos +
      ( $$vec[1] * $$pt[2] - $$vec[2] * $$pt[1] ) * $sin;
    $res[1] =
      ( $$vec[1] * dot( @$pt, @$vec ) ) -
      ( $$vec[1] * ( $$vec[0] * $$pt[0] + $$vec[2] * $$pt[2] ) - $$pt[1] * $uw )
      * $cos +
      ( $$vec[2] * $$pt[0] - $$vec[0] * $$pt[2] ) * $sin;
    $res[2] =
      ( $$vec[2] * dot( @$pt, @$vec ) ) -
      ( $$vec[2] * ( $$vec[0] * $$pt[0] + $$vec[1] * $$pt[1] ) - $$pt[2] * $uv )
      * $cos +
      ( $$vec[0] * $$pt[1] - $$vec[1] * $$pt[0] ) * $sin;
    return @res;
}

=head2 rotate

	subroutine to rotate a point (pt) such that one axis (u) aligns with another (v)

=cut
sub rotate {
    my ( $pt, $u, $v ) = @_;

    #rotate a point (pt) such that vector u aligns with vector v
    my @res = ( $$pt[0], $$pt[1], $$pt[2] );
    my $cos = dot( @$u, @$v ) / ( norm(@$u) * norm(@$v) );
    if ( $cos ne 1 ) {    #if vectors are already aligned
        my @n    = unit( cross( @$u, @$v ) );
        my $ocos = 1 - $cos;
        my $sin  = sin( Math::Trig::acos($cos) );
        $res[0] =
          ( ( $ocos * $n[0] * $n[0] ) + $cos ) * $$pt[0] +
          ( ( $ocos * $n[0] * $n[1] ) - $n[2] * $sin ) * $$pt[1] +
          ( ( $ocos * $n[0] * $n[2] ) + $n[1] * $sin ) * $$pt[2];
        $res[1] =
          ( ( $ocos * $n[0] * $n[1] ) + $n[2] * $sin ) * $$pt[0] +
          ( ( $ocos * $n[1] * $n[1] ) + $cos ) * $$pt[1] +
          ( ( $ocos * $n[1] * $n[2] ) - $n[0] * $sin ) * $$pt[2];
        $res[2] =
          ( ( $ocos * $n[0] * $n[2] ) - $n[1] * $sin ) * $$pt[0] +
          ( ( $ocos * $n[1] * $n[2] ) + $n[0] * $sin ) * $$pt[1] +
          ( ( $ocos * $n[2] * $n[2] ) + $cos ) * $$pt[2];
    }
    return @res;
}

=head2 cross

	subroutine to find the cross product of two 3-d vectors
	Input 1: Concatenated vector whose first three elements represent vector 1 and whose last three represent vector 2

=cut
sub cross {
    my (@v) = @_;
    my @res = ( 0, 0, 0 );
    $res[0] = $v[1] * $v[5] - $v[2] * $v[4];
    $res[1] = $v[2] * $v[3] - $v[0] * $v[5];
    $res[2] = $v[0] * $v[4] - $v[1] * $v[3];
    return @res;
}

=head2 dot2

	subroutine to find the dot product of two vectors
	Input 1: Concatenated vector whose first half represents vector 1 and whose second half represents vector 2

=cut
sub dot {
    my (@v) = @_;
    my $max = scalar(@v) / 2;
    my $res = 0;
    for ( my $aa = 0 ; $aa < $max ; $aa++ ) {
        $res += $v[$aa] * $v[ $aa + $max ];
    }
    return $res;
}

=head2 unit

	subroutine to return the unit vector corresponding to a given vector
=cut
sub unit {
    my (@v)  = @_;
    my $norm = norm(@v);
    my $max  = scalar(@v);
    for ( my $a = 0 ; $a < $max ; $a++ ) {
        $v[$a] = $v[$a] / $norm;
    }
    return @v;
}

=head2 norm
	
	subroutine to return the 2-norm of a given vector

=cut
sub norm {
    my (@v) = @_;
    my $res = 0;
    foreach (@v) {
        $res += $_**2;
    }
    return sqrt($res);
}

=head2 vecadd

	subroutine to add two vectors
	Input 1: Scalar factor to multiply the second vector
	Input 2: Concatenated vector whose first half represents the first vector 
		 and whose second half represents the second vector

=cut
sub vecadd {
    my ( $scale, @v1 ) = @_;

    #v1+scale*v2
    my $dim = scalar(@v1) / 2;
    my @res;
    for ( my $aa = 0 ; $aa < $dim ; $aa++ ) {
        push( @res, $v1[$aa] + $scale * $v1[ $dim + $aa ] );
    }
    return @res;
}

=head2 max

	subroutine to find the maximum of an array

=cut
sub max {
    my (@a) = @_;
    my $m = $a[0];
    foreach (@a) {
        if ( $_ > $m ) { $m = $_ }
    }
    return $m;
}

=head2 min 

	subroutine to find the minimum of an array

=cut
sub min {
    my (@a) = @_;
    my $m = $a[0];
    foreach (@a) {
        if ( $_ < $m ) { $m = $_ }
    }
    return $m;
}

=head2 dbin
 
	subroutine to Fbin a value from 0-40 using a given binsize

=cut
sub dbin {
    my ( $val, $binsize ) = @_;
    my $binval = 41;
    if ( $val <= 40 ) {
        $binval = $binsize * ( int( $val / $binsize ) + 1 );
    }
    return $binval;
}

=head2 angbin

	subroutine to bin a value using a given bin size

=cut
sub angbin {
    my ( $val, $binsize ) = @_;
    my $binval = $binsize * ( int( $val / $binsize ) + 1 );
    return $binval;
}

=head2 pearson

	subroutine to find the Pearson correlation coefficient between two data sets

=cut
sub pearson {
    my ( $x, $y ) = @_;
    my $xm    = 0;
    my $ym    = 0;
    my $xsd   = 0;
    my $ysd   = 0;
    my $count = scalar(@$x);
    foreach (@$x) {
        $xm  += $_;
        $xsd += $_ * $_;
    }
    foreach (@$y) {
        $ym  += $_;
        $ysd += $_ * $_;
    }
    $xm /= $count;
    $ym /= $count;
    $xsd = sqrt( ( $xsd / $count ) - ( $xm * $xm ) );
    $ysd = sqrt( ( $ysd / $count ) - ( $ym * $ym ) );
    my $r = 0;
    for ( my $aa = 0 ; $aa < $count ; $aa++ ) {
        $r += ( ( $$x[$aa] - $xm ) * ( $$y[$aa] - $ym ) / ( $xsd * $ysd ) );
    }
    $r /= $count;
    return $r;
}

=head2 find_rmsd

	subroutine to find the RMSD between two sets of points, 
	using the method described by Theobald
	
	Input 1: Number of points to consider
	Input 2: Vector with the first set of coordinates
	Input 3: Vector with the second set of coordinates

=cut
sub find_rmsd {
    my ( $c, $x, $y ) = @_;
    my @R = ( [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] );
    my @xcom = COM2( 0, $c, \@$x );
    my @ycom = COM2( 0, $c, \@$y );
    my $e0   = 0;
    for ( my $aa = 0 ; $aa < $c ; $aa++ ) {
        for ( my $bb = 0 ; $bb < 3 ; $bb++ ) {
            for ( my $cc = 0 ; $cc < 3 ; $cc++ ) {
                $R[$bb][$cc] +=
                  ( $$x[$aa][$bb] - $xcom[$bb] ) *
                  ( $$y[$aa][$cc] - $ycom[$cc] );
            }
            $e0 +=
              ( ( $$x[$aa][$bb] - $xcom[$bb] )**2 +
                  ( $$y[$aa][$bb] - $ycom[$bb] )**2 );
        }
    }

    #calculate cross-coefficients
    my $xx    = $R[0][0]**2;
    my $xy    = $R[0][1]**2;
    my $xz    = $R[0][2]**2;
    my $yx    = $R[1][0]**2;
    my $yy    = $R[1][1]**2;
    my $yz    = $R[1][2]**2;
    my $zx    = $R[2][0]**2;
    my $zy    = $R[2][1]**2;
    my $zz    = $R[2][2]**2;
    my $D     = ( $xy + $xz - $yx - $zx )**2;
    my $temp  = -$xx + $yy + $zz + $yz + $zy;
    my $temp2 = 2 * ( $R[1][1] * $R[2][2] - $R[1][2] * $R[2][1] );
    my $E     = ( $temp - $temp2 ) * ( $temp + $temp2 );
    my $xzpzx = $R[0][2] + $R[2][0];
    my $xzmzx = $R[0][2] - $R[2][0];
    my $yzpzy = $R[1][2] + $R[2][1];
    my $yzmzy = $R[1][2] - $R[2][1];
    my $xypyx = $R[0][1] + $R[1][0];
    my $xymyx = $R[0][1] - $R[1][0];
    my $xmymz = $R[0][0] - $R[1][1] - $R[2][2];
    my $xmypz = $R[0][0] - $R[1][1] + $R[2][2];
    my $xpymz = $R[0][0] + $R[1][1] - $R[2][2];
    my $xpypz = $R[0][0] + $R[1][1] + $R[2][2];
    my $F =
      ( -( $xzpzx * $yzmzy ) + ( $xymyx * $xmymz ) ) *
      ( -( $xzmzx * $yzpzy ) + ( $xymyx * $xmypz ) );
    my $G =
      ( -( $xzpzx * $yzpzy ) - ( $xypyx * $xpymz ) ) *
      ( -( $xzmzx * $yzmzy ) - ( $xypyx * $xpypz ) );
    my $H =
      ( ( $xypyx * $yzpzy ) + ( $xzpzx * $xmypz ) ) *
      ( -( $xymyx * $yzmzy ) + ( $xzpzx * $xpypz ) );
    my $I =
      ( ( $xypyx * $yzmzy ) + ( $xzmzx * $xmymz ) ) *
      ( -( $xymyx * $yzpzy ) + ( $xzmzx * $xpymz ) );
    my $c0 = $D + $E + $F + $G + $H + $I;
    my $c1 =
      8 *
      ( ( $R[0][0] * ( $R[1][2] * $R[2][1] - $R[1][1] * $R[2][2] ) ) +
          ( $R[0][1] * ( $R[1][0] * $R[2][2] - $R[1][2] * $R[2][0] ) ) +
          ( $R[0][2] * ( $R[1][1] * $R[2][0] - $R[1][0] * $R[2][1] ) ) );
    my $c2     = -2 * ( $xx + $xy + $xz + $yx + $yy + $yz + $zx + $zy + $zz );
    my $lam    = 0.5 * $e0;
    my $prec   = 0.00001;
    my $lamold = $lam + 1;

    #Use Newton's method to find the largest eigenvalue
    while ( abs( $lam - $lamold ) > $prec ) {
        $lamold = $lam;
        my $t = 4 * ( $lam**3 ) + 2 * $c2 * $lam + $c1;
        if ( $t ne 0 ) {
            $lam -=
              ( $lam**4 + $c2 * ( $lam**2 ) + $c1 * $lam + $c0 ) /
              ( 4 * ( $lam**3 ) + 2 * $c2 * $lam + $c1 );
        }
    }
    my $rms = sqrt( abs( ( $e0 - 2 * $lam ) / $c ) );
    return $rms;
}

=head2 superpose

	subroutine to superpose one set of points onto another

	Input 1: Number of points to superpose
	Input 2: Vector of points to be used as the superposition template
	Input 3: Vector of points to be aligned and superposed
	Input 4: Vector of extra points to be superposed (not aligned, since they are "carried along")

=cut
sub superpose {
    my ( $c, $x, $y, $extra ) = @_;
    my @R = ( [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] );
    my @xcom = COM2( 0, $c, \@$x );
    my @ycom = COM2( 0, $c, \@$y );
    my $e0   = 0;
    for ( my $aa = 0 ; $aa < $c ; $aa++ ) {
        for ( my $bb = 0 ; $bb < 3 ; $bb++ ) {
            for ( my $cc = 0 ; $cc < 3 ; $cc++ ) {
                $R[$bb][$cc] +=
                  ( $$x[$aa][$bb] - $xcom[$bb] ) *
                  ( $$y[$aa][$cc] - $ycom[$cc] );
            }
            $e0 +=
              ( ( $$x[$aa][$bb] - $xcom[$bb] )**2 +
                  ( $$y[$aa][$bb] - $ycom[$bb] )**2 );
        }
    }

    #calculate cross-coefficients
    my $xx    = $R[0][0]**2;
    my $xy    = $R[0][1]**2;
    my $xz    = $R[0][2]**2;
    my $yx    = $R[1][0]**2;
    my $yy    = $R[1][1]**2;
    my $yz    = $R[1][2]**2;
    my $zx    = $R[2][0]**2;
    my $zy    = $R[2][1]**2;
    my $zz    = $R[2][2]**2;
    my $D     = ( $xy + $xz - $yx - $zx )**2;
    my $temp  = -$xx + $yy + $zz + $yz + $zy;
    my $temp2 = 2 * ( $R[1][1] * $R[2][2] - $R[1][2] * $R[2][1] );
    my $E     = ( $temp - $temp2 ) * ( $temp + $temp2 );
    my $xzpzx = $R[0][2] + $R[2][0];
    my $xzmzx = $R[0][2] - $R[2][0];
    my $yzpzy = $R[1][2] + $R[2][1];
    my $yzmzy = $R[1][2] - $R[2][1];
    my $xypyx = $R[0][1] + $R[1][0];
    my $xymyx = $R[0][1] - $R[1][0];
    my $xmymz = $R[0][0] - $R[1][1] - $R[2][2];
    my $xmypz = $R[0][0] - $R[1][1] + $R[2][2];
    my $xpymz = $R[0][0] + $R[1][1] - $R[2][2];
    my $xpypz = $R[0][0] + $R[1][1] + $R[2][2];
    my $F =
      ( -( $xzpzx * $yzmzy ) + ( $xymyx * $xmymz ) ) *
      ( -( $xzmzx * $yzpzy ) + ( $xymyx * $xmypz ) );
    my $G =
      ( -( $xzpzx * $yzpzy ) - ( $xypyx * $xpymz ) ) *
      ( -( $xzmzx * $yzmzy ) - ( $xypyx * $xpypz ) );
    my $H =
      ( ( $xypyx * $yzpzy ) + ( $xzpzx * $xmypz ) ) *
      ( -( $xymyx * $yzmzy ) + ( $xzpzx * $xpypz ) );
    my $I =
      ( ( $xypyx * $yzmzy ) + ( $xzmzx * $xmymz ) ) *
      ( -( $xymyx * $yzpzy ) + ( $xzmzx * $xpymz ) );
    my $c0 = $D + $E + $F + $G + $H + $I;
    my $c1 =
      8 *
      ( ( $R[0][0] * ( $R[1][2] * $R[2][1] - $R[1][1] * $R[2][2] ) ) +
          ( $R[0][1] * ( $R[1][0] * $R[2][2] - $R[1][2] * $R[2][0] ) ) +
          ( $R[0][2] * ( $R[1][1] * $R[2][0] - $R[1][0] * $R[2][1] ) ) );
    my $c2     = -2 * ( $xx + $xy + $xz + $yx + $yy + $yz + $zx + $zy + $zz );
    my $lam    = 0.5 * $e0;
    my $prec   = 0.00001;
    my $lamold = $lam + 1;

    #Use Newton's method to find largest eigenvalue
    while ( abs( $lam - $lamold ) > $prec ) {
        $lamold = $lam;
        my $t = 4 * ( $lam**3 ) + 2 * $c2 * $lam + $c1;
        if ( $t ne 0 ) {
            $lam -=
              ( $lam**4 + $c2 * ( $lam**2 ) + $c1 * $lam + $c0 ) /
              ( 4 * ( $lam**3 ) + 2 * $c2 * $lam + $c1 );
        }
    }
    my $rms = sqrt( abs( ( $e0 - 2 * $lam ) / $c ) );
    if ( $rms > 0 ) {

        #find eigenvector of 4x4 quaternion matrix for largest eigenvalue
        my @evec = ( 0, 0, 0, 0 );
        my @M;
        push( @M, [ ( $xpypz - $lam, $yzmzy, -$xzmzx, $xymyx ) ] );
        push( @M, [ ( $yzmzy, $xmymz - $lam, $xypyx, $xzpzx ) ] );
        push( @M, [ ( -$xzmzx, $xypyx, -$xmypz - $lam, $yzpzy ) ] );
        push( @M, [ ( $xymyx, $xzpzx, $yzpzy, -$xpymz - $lam ) ] );

        #Find co-factors of first row
        $evec[0] = det(
            (
                [ @{ $M[1] }[ 1 .. 3 ] ],
                [ @{ $M[2] }[ 1 .. 3 ] ],
                [ @{ $M[3] }[ 1 .. 3 ] ]
            )
        );
        $evec[1] = -1 * det(
            (
                [ ( $M[1][0], @{ $M[1] }[ 2 .. 3 ] ) ],
                [ ( $M[2][0], @{ $M[2] }[ 2 .. 3 ] ) ],
                [ ( $M[3][0], @{ $M[3] }[ 2 .. 3 ] ) ]
            )
        );
        $evec[2] = det(
            (
                [ ( @{ $M[1] }[ 0 .. 1 ], $M[1][3] ) ],
                [ ( @{ $M[2] }[ 0 .. 1 ], $M[2][3] ) ],
                [ ( @{ $M[3] }[ 0 .. 1 ], $M[3][3] ) ]
            )
        );
        $evec[3] = -1 * det(
            (
                [ @{ $M[1] }[ 0 .. 2 ] ],
                [ @{ $M[2] }[ 0 .. 2 ] ],
                [ @{ $M[3] }[ 0 .. 2 ] ]
            )
        );
        if (
            abs( $evec[0] ) +
            abs( $evec[1] ) +
            abs( $evec[2] ) +
            abs( $evec[3] ) < 0.001 )
        {

            #Find co-factors of second row
            $evec[0] = -1 * det(
                (
                    [ @{ $M[0] }[ 1 .. 3 ] ],
                    [ @{ $M[2] }[ 1 .. 3 ] ],
                    [ @{ $M[3] }[ 1 .. 3 ] ]
                )
            );
            $evec[1] = det(
                (
                    [ ( $M[0][0], @{ $M[0] }[ 2 .. 3 ] ) ],
                    [ ( $M[2][0], @{ $M[2] }[ 2 .. 3 ] ) ],
                    [ ( $M[3][0], @{ $M[3] }[ 2 .. 3 ] ) ]
                )
            );
            $evec[2] = -1 * det(
                (
                    [ ( @{ $M[0] }[ 0 .. 1 ], $M[0][3] ) ],
                    [ ( @{ $M[2] }[ 0 .. 1 ], $M[2][3] ) ],
                    [ ( @{ $M[3] }[ 0 .. 1 ], $M[3][3] ) ]
                )
            );
            $evec[3] = det(
                (
                    [ @{ $M[0] }[ 0 .. 2 ] ],
                    [ @{ $M[2] }[ 0 .. 2 ] ],
                    [ @{ $M[3] }[ 0 .. 2 ] ]
                )
            );
            if ( $evec[0]**2 + $evec[1]**2 + $evec[2]**2 + $evec[3]**2 < 0.001 )
            {

                #Find co-factors of third row
                $evec[0] = det(
                    (
                        [ @{ $M[0] }[ 1 .. 3 ] ],
                        [ @{ $M[1] }[ 1 .. 3 ] ],
                        [ @{ $M[3] }[ 1 .. 3 ] ]
                    )
                );
                $evec[1] = -1 * det(
                    (
                        [ ( $M[0][0], @{ $M[0] }[ 2 .. 3 ] ) ],
                        [ ( $M[1][0], @{ $M[1] }[ 2 .. 3 ] ) ],
                        [ ( $M[3][0], @{ $M[3] }[ 2 .. 3 ] ) ]
                    )
                );
                $evec[2] = det(
                    (
                        [ ( @{ $M[0] }[ 0 .. 1 ], $M[0][3] ) ],
                        [ ( @{ $M[1] }[ 0 .. 1 ], $M[1][3] ) ],
                        [ ( @{ $M[3] }[ 0 .. 1 ], $M[3][3] ) ]
                    )
                );
                $evec[3] = -1 * det(
                    (
                        [ @{ $M[0] }[ 0 .. 2 ] ],
                        [ @{ $M[1] }[ 0 .. 2 ] ],
                        [ @{ $M[3] }[ 0 .. 2 ] ]
                    )
                );
                if ( $evec[0]**2 + $evec[1]**2 + $evec[2]**2 + $evec[3]**2 <
                    0.001 )
                {

                    #Find co-factors of fourth row
                    $evec[0] = -1 * det(
                        (
                            [ @{ $M[0] }[ 1 .. 3 ] ],
                            [ @{ $M[1] }[ 1 .. 3 ] ],
                            [ @{ $M[2] }[ 1 .. 3 ] ]
                        )
                    );
                    $evec[1] = det(
                        (
                            [ ( $M[0][0], @{ $M[0] }[ 2 .. 3 ] ) ],
                            [ ( $M[1][0], @{ $M[1] }[ 2 .. 3 ] ) ],
                            [ ( $M[2][0], @{ $M[2] }[ 2 .. 3 ] ) ]
                        )
                    );
                    $evec[2] = -1 * det(
                        (
                            [ ( @{ $M[0] }[ 0 .. 1 ], $M[0][3] ) ],
                            [ ( @{ $M[1] }[ 0 .. 1 ], $M[1][3] ) ],
                            [ ( @{ $M[2] }[ 0 .. 1 ], $M[2][3] ) ]
                        )
                    );
                    $evec[3] = det(
                        (
                            [ @{ $M[0] }[ 0 .. 2 ] ],
                            [ @{ $M[1] }[ 0 .. 2 ] ],
                            [ @{ $M[2] }[ 0 .. 2 ] ]
                        )
                    );
                }
            }
        }
        my @quat = unit(@evec);
        my $scal = $quat[0];
        my @vec  = @quat[ 1 .. 3 ];
        foreach (@vec) { $_ = -1 * $_ }

        #Form rotation matrix
        foreach my $coord (@$y) {
            my @new = (
                ${$coord}[0] - $ycom[0],
                ${$coord}[1] - $ycom[1],
                ${$coord}[2] - $ycom[2]
            );
            my $s1 = -1 * dot( @vec, @new );
            my @svec = vecadd( $scal, cross( @vec, @new ), @new );
            my @rotpt =
              vecadd( -1 * $s1, vecadd( $scal, cross( @vec, @svec ), @svec ),
                @vec );
            $coord = [ vecadd( 1, @xcom, @rotpt ) ];
        }
        foreach my $coord (@$extra) {
            my @new = (
                ${$coord}[0] - $ycom[0],
                ${$coord}[1] - $ycom[1],
                ${$coord}[2] - $ycom[2]
            );
            my $s1 = -1 * dot( @vec, @new );
            my @svec = vecadd( $scal, cross( @vec, @new ), @new );
            my @rotpt =
              vecadd( -1 * $s1, vecadd( $scal, cross( @vec, @svec ), @svec ),
                @vec );
            $coord = [ vecadd( 1, @xcom, @rotpt ) ];
        }
    }
    else {
        @$y = @{ Storable::dclone( \@$x ) };
    }
    return $rms;
}

=head2 dihedral

	subroutine to calculate the dihedral angle generated by four atoms

=cut
sub dihedral {
    my ( $c1, $c2, $c3, $c4 ) = @_;
    my @v21 = unit( vecadd( -1, @$c1, @$c2 ) );
    my @v23 = unit( vecadd( -1, @$c3, @$c2 ) );
    my @v34 = unit( vecadd( -1, @$c4, @$c3 ) );
    my @v21orth = unit( vecadd( -1 * dot( @v21, @v23 ), @v21, @v23 ) );
    my @v34orth = unit( vecadd( -1 * dot( @v34, @v23 ), @v34, @v23 ) );
    my $ang = Math::Trig::acos( dot( @v21orth, @v34orth ) ) * 180 / 3.14159265;
    my @dirvec = cross( @v21orth, @v34orth );
    if ( dot( @v23, @dirvec ) < 0 ) { $ang *= -1 }
    return $ang;
}

=head2 findcb

	subroutine to calculate the coordinates of a beta-carbon, given statistically observed tetrahedral geometry######
	
	Input 1: C-alpha coordinates
	Input 2: C coordinates
	Input 3: N coordinates
=cut
sub findcb {
    my ( $ca, $c, $n ) = @_;
    my @v3 = unit( vecadd( -1, @$c,  @$n ) );
    my @v1 = unit( vecadd( -1, @$ca, @$c ) );
    my @v2 = unit( vecadd( -1, @$ca, @$n ) );
    my @v4 = unit( vecadd( 1,  @v1,  @v2 ) );
    my $ang = 53.2;
    my @dist = rotateaxis( \@v4, \@v3, \$ang );
    @dist = ( $dist[0] * 1.53, $dist[1] * 1.53, $dist[2] * 1.53 );
    my @cb = vecadd( 1, @$ca, @dist );
    return @cb;
}

=head2 findo

=cut
sub findo {
    my ( $ca, $c, $n ) = @_;
    my @c_to_ca = unit( vecadd( -1, @$ca, @$c ) );
    my @c_to_n  = unit( vecadd( -1, @$n,  @$c ) );
    my @normal = unit( cross( @c_to_n, @c_to_ca ) );

    #rotate c-ca bond around normal counterclockwise 121 degrees
    my $ang = 121;
    my @out = rotateaxis( \@c_to_ca, \@normal, \$ang );
    my @o   = vecadd( 1.23, @$c, @out );
    return @o;
}

=head2 pointsonsphere

	subroutine to distribute points evenly on a sphere
	Input 1: Number of points to distribute
	Input 2: Radius of sphere

=cut
sub pointsonsphere {
    my ( $n, $rad ) = @_;
    my @pts;
    my $increment = 3.14159265359 * ( 3 - sqrt(5) );
    my $offset = 2 / $n;
    for ( my $aa = 0 ; $aa < $n ; $aa++ ) {
        my $y   = $aa * $offset - 1 + 0.5 * $offset;
        my $r   = sqrt( 1 - $y * $y );
        my $phi = $aa * $increment;
        push( @pts,
            [ ( $rad * $r * cos($phi), $rad * $y, $rad * $r * sin($phi) ) ] );
    }
    return @pts;
}

=head2 norm2

	subroutine to find the square of the 2-norm of a vector
=cut
sub norm2 {
    my (@v) = @_;
    my $res = 0;
    foreach (@v) {
        $res += $_**2;
    }
    return $res;
}

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GeometricalCalculations

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

1; # End of GeometricalCalculations
