package SmotifCS::Protein;

use 5.10.1 ;
use strict;
use warnings;

use SmotifCS::GeometricalCalculations;
use SmotifCS::StatisticalPotential;
use SmotifCS::MYSQLSmotifs;
use Data::Dumper;
use Math::Trig;

=head1 NAME

Protein Class

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This package contains the 'Protein' class used to represent a protein 
structure composed of smotifs and the set of subroutines available for 
constructing, modifying, and evaluating the given protein structure

    use Protein;

    my $foo = Protein->new();
    ...

=head2 new

Initialize a new Protein object

=cut

sub new {
	my ($class, @args) = @_;
	my $self = {};
	$self->{c}  = ();	#coordinates of backbone carbonyl atoms
	$self->{ca} = ();	#coordinates of backbone c-alpha atoms
	$self->{n}  = ();	#coordinates of backbone n atoms
	$self->{cb} = ();	#coordinates of backbone c-beta atoms
	$self->{o}  = ();	#coordinates of backbone o atoms
	$self->{h}  = ();	#coordinates of backbone amide hydrogens, reconstructed
	$self->{lm} = ();	#landmarks for each smotif (start, loopstart, ss2start, ss2end)
	$self->{type} = ();	#smotif type - HH, HE, EH, EE
	$self->{num}  = 0;	#number of smotifs
	$self->{axis1} = ();	#ss1 axes coordinates
	$self->{axis2} = ();	#ss2 axes coordinates
	$self->{lvec} = ();	#lvec (vector joining flanking residues of loop) coordinates
	$self->{d}    = ();	#distance between c-alpha atoms of flanking residues of a loop
	$self->{delta} = ();	#smotif hoist angles
	$self->{theta} = ();	#smotif packing angles
	$self->{rho}   = ();	#smotif meridian angles
	$self->{ssrot} = ();	#rotation angles of smotifs
	$self->{created} = 1;	#whether protein exists
	$self->{seq} = '';	#amino acid sequence
	$self->{stat_pot} = {};	#statistical potential reference value table
	$self->{hb_d} = {};	#hydrogen bond distance reference value table
	$self->{hb_t} = {};	#hydrogen bond theta angle reference value table
	$self->{hb_p} = {};	#hydrogen bond psi angle reference value table
	#bless $self, 'protein';
	if (defined($args[0]) and ref($args[0]) eq 'protein') {
		%{$self} = %{$args[0]};
	}
	#return $self;
	return bless ($self, $class);
}

=head2 last_pt

Returns or changes the last coordinate (C-terminus) of the protein
test->last_pt($atom,@pt) 

INPUTS: 
$atom = atom type ('CA','C','N','O','CB','H');
@pt (optional) = new coordinates to be assigned to the last atom

=cut

sub last_pt {
	my ($self, $atom, @pt) = @_;
	if (@pt) {
		push @{$self->{$atom}}, [@pt];
	}
	return @{$self->{c}[-1]};
}


=head2 num_res

	Returns the number of residues in the protein
	test->num_res() 

=cut

sub num_res {
	my ($self) = @_;
	my @lm=$self->one_landmark(-1);
	return $lm[3];
}

=head2 change_pt
	Changes the coordinates of an existing atom in the protein
	test->change_pt($atom,$index,@pt) 
    INPUTS:
	$atom  = atom type ('CA','C','N','O','CB','H');
	$index = residue number
	@pt new coordinates to be assigned to the atom

=cut

sub change_pt {
	my ($self, $atom, $index, @pt) = @_;
	@{$self->{$atom}[$index]}=@pt;
}

=head2 get_coords
	
Returns the coordinates (as an Nx3 array of arrays) of atoms in consecutive residues
test->get_coords($atom,$first,$last) 

INPUTS:
$atom = atom type ('CA','C','N','O','CB','H');
$first = first residue index
$last = last residue index

=cut

sub get_coords {
	my ($self, $atom,$first,$last) = @_;
	return @{$self->{$atom}}[$first..$last];
}

=head2 types

	Returns an array of types (HH, HE, EH, EE) of all the smotifs in the structure
	test->types()

=cut

sub types {
	my ($self) = @_;
	return @{$self->{type}};
}

=head2 one_landmark

	Returns or assigns an array of the landmarks (start, loop start, ss2 start, end) for a given smotif
	test->one_landmark($index,@newlm)
	
        INPUTS:
	$index = smotif index
	@newlm (optional) = array of landmarks to be assigned to the smotif

=cut

sub one_landmark {
	my ($self, $index, @newlm) = @_;
	if (@newlm) {
		if ($index==-1) {
			push(@{$self->{lm}},[@newlm]);
		} else {
			${$self->{lm}}[$index]=[@newlm];
		}
	}
	return @{$self->{lm}[$index]};
}

=head2 get_seq 
	
    Returns or assigns a portion of the protein sequence as a string
	test->get_seq($start,$len,$seq) 
	
    INPUTS:
	$start = start position of the sequence portion
	$len = length of the sequence portion
	$seq (optional) = new sequence of amino acids to assign to the given portion of the sequence

=cut

sub get_seq {
	my ($self,$start,$len,$seq) = @_;
	if ($seq) {
  		substr($self->{seq}, $start, $len) = $seq;
	};
	return substr($self->{seq}, $start,$len);
}

=head2 print_to_file

	Prints the contents of the protein object to a PDB-formatted file
	test->print_to_file($filename)
	INPUTS:
	$filename = name of the output file (will be overwritten)

=cut

sub print_to_file {
	my ($self, $filename) = @_;

    my @temp1 = ('ATOM',0);
	my @temp2 = ('GLY','A',0,0,0,0,1,0);
	my $index = 0;
	
    open( OUTFILE,">$filename") or die "Unable to open file to print PDB $filename\n";
	my $fin = $self->num_res;
	for (my $aa = 0; $aa < $fin; $aa++ ) {
		$temp1[1]++;
		$temp2[0]=SmotifCS::GeometricalCalculations::convert($self->get_seq($aa,1));
		$temp2[2]=$aa+1;
		$temp2[3]=${$self->get_coords('n',$aa,$aa)}[0];
		$temp2[4]=${$self->get_coords('n',$aa,$aa)}[1];
		$temp2[5]=${$self->get_coords('n',$aa,$aa)}[2];
		my $pline=sprintf('%s%7d  %s  %3s %s%4d     %7.3f %7.3f %7.3f  %4.2f %5.2f           %s',@temp1,'N ',@temp2,'N');
		print OUTFILE "$pline\n";
		if (($aa>0) and (exists(${$self->{h}}[$aa]))) {
			$temp1[1]++;
			$temp2[3]=${$self->get_coords('h',$aa,$aa)}[0];
			$temp2[4]=${$self->get_coords('h',$aa,$aa)}[1];
			$temp2[5]=${$self->get_coords('h',$aa,$aa)}[2];
			$pline=sprintf('%s%7d  %s  %3s %s%4d     %7.3f %7.3f %7.3f  %4.2f %5.2f           %s',@temp1,'H',@temp2,'H');
			print OUTFILE "$pline\n";
		}	
		$temp1[1]++;
		$temp2[3]=${$self->get_coords('ca',$aa,$aa)}[0];
		$temp2[4]=${$self->get_coords('ca',$aa,$aa)}[1];
		$temp2[5]=${$self->get_coords('ca',$aa,$aa)}[2];
		$pline=sprintf('%s%7d  %s  %3s %s%4d     %7.3f %7.3f %7.3f  %4.2f %5.2f           %s',@temp1,'CA',@temp2,'C');
		print OUTFILE "$pline\n";
		$temp1[1]++;
		$temp2[3]=${$self->get_coords('c',$aa,$aa)}[0];
		$temp2[4]=${$self->get_coords('c',$aa,$aa)}[1];
		$temp2[5]=${$self->get_coords('c',$aa,$aa)}[2];
		$pline=sprintf('%s%7d  %s  %3s %s%4d     %7.3f %7.3f %7.3f  %4.2f %5.2f           %s',@temp1,'C ',@temp2,'C');
		print OUTFILE "$pline\n";
		if (exists(${$self->{o}}[$aa])) {
			$temp1[1]++;
			$temp2[3]=${$self->get_coords('o',$aa,$aa)}[0];
			$temp2[4]=${$self->get_coords('o',$aa,$aa)}[1];
			$temp2[5]=${$self->get_coords('o',$aa,$aa)}[2];
			$pline=sprintf('%s%7d  %s  %3s %s%4d     %7.3f %7.3f %7.3f  %4.2f %5.2f           %s',@temp1,'O ',@temp2,'O');
			print OUTFILE "$pline\n";
		}
		if (exists(${$self->{cb}}[$aa])) {
			$temp1[1]++;
			$temp2[3]=${$self->get_coords('cb',$aa,$aa)}[0];
			$temp2[4]=${$self->get_coords('cb',$aa,$aa)}[1];
			$temp2[5]=${$self->get_coords('cb',$aa,$aa)}[2];
			$pline=sprintf('%s%7d  %s  %3s %s%4d     %7.3f %7.3f %7.3f  %4.2f %5.2f           %s',@temp1,'CB',@temp2,'C');
			print OUTFILE "$pline\n";
		}
	}
	print OUTFILE "TER\nEND\n";
	close(OUTFILE);
}

=head2 num_motifs

	Returns the number of smotifs in the protein
	test->num_motifs()

=cut

sub num_motifs {
	my ($self) = @_;
	return $self->{num};
}

=head2 add_motif

	Appends an smotif to the end of the protein structure
	test->add_motif(@proptable)

	INPUTS:
	@proptable = array of properties, can be in one of two formats -
		1) a single entry containing the smotif nid number
		2) an array with the PDB code, chain, smotif start residue, loop length, ss1 length, ss2 length, type

=cut

sub add_motif {
	my ($self, @proptable) = @_;
	my $check;

    my $DEBUG = 0;
    if ($DEBUG){
            print Dumper(\@proptable);
		    my  ($package, $filename, $line) = caller;
		    print "package  = $package\n";
		    print "filename = $filename\n";
		    print "line     = $line\n";
		    print Dumper(\@_);
	}

	if ($self->num_motifs() == 0 ) {
        # print "add_motif_from_file\n";
		$check = $self->add_motif_from_file(@proptable);
    } 
	else {
       # print "add_partial_motif\n";
		$check = $self->add_partial_motif(@proptable);
    };
	return $check;
}

=head2 add_motif_from_file

	Adds an smotif to an empty structure
	test->add_motif_from_file(@proptable)
	DO NOT CALL THIS FUNCTION DIRECTLY! Use test->add_motif(@proptable) instead

	INPUTS:
	@proptable = array of properties, can be in one of two formats -
                1) a single entry containing the smotif nid number
                2) an array with the PDB code, chain, smotif start residue, loop length, ss1 length, ss2 length, type

=cut

sub add_motif_from_file {
#add an smotif to an empty structure - do not call this function directly
	my ($self, @proptable)=@_;
	#get filename and mysql info
	my $check=0;
	my @idtable;
	my @lm;
	my $seq='';
	if (scalar(@proptable) eq 8) {
		@idtable=@proptable;
	} else {
		# GeometricalCalculations::getnid(\@proptable, \@idtable);
		# print Dumper(\@proptable);
		# print Dumper(\@idtable);
        SmotifCS::MYSQLSmotifs::getnid(\@proptable, \@idtable);
		#print Dumper(\@idtable);

	}
    # print "start get_from_file\n";
    my @ca = SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'CA',\$seq);
	my @n  = SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'N',\$seq);
	my @c  = SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'C',\$seq);
	my @cb = SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'CB',\$seq);
	my @o  = SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'O',\$seq);
    # print scalar(@ca),"\t",scalar(@n),"\t",scalar(@c),"\t",scalar(@cb),"\t",scalar(@o),"\n";
	#look for missing cb atoms (from glycines)
	for (my $aa=0;$aa<scalar(@cb);$aa++) {
		if ($cb[$aa]==0) {
			$cb[$aa]=[SmotifCS::GeometricalCalculations::findcb(\@{$ca[$aa]},\@{$c[$aa]},\@{$n[$aa]})];
		}
	}
	unshift(@lm,0);
	for (my $aa=0;$aa<$lm[3];$aa++) {
		push(@{$self->{ca}},$ca[$aa] );
		push(@{$self->{c}}, $c[$aa]  );
		push(@{$self->{n}}, $n[$aa]  );
		push(@{$self->{cb}},$cb[$aa] );
		push(@{$self->{o}}, $o[$aa]  );
	}
	$self->one_landmark(-1,@lm);
	$self->{num}++;
	push(@{$self->{type}},$idtable[7]);
	$self->axis($self->num_motifs-1,1,1);
	$self->axis($self->num_motifs-1,2,1);
	$self->lvec($self->num_motifs-1,1);
	$self->calc_angles($self->num_motifs-1,1);
	$self->get_seq(0,$lm[2],$seq);
	my @aa=$self->one_landmark(0);
	push(@{$self->{ssrot}},0);
	$check=1;
	return $check;
}

=head2 add_partial_motif

Adds an smotif to an existing structure by aligning
its first secondary structure to the final secondary structure of the protein.
test->add_partial_motif(@proptable)
DO NOT CALL THIS FUNCTION DIRECTLY! Use test->add_motif(@proptable) instead
INPUTS:
    @proptable = array of properties, can be in one of two formats -
    1) a single entry containing the smotif nid number
    2) an array with the PDB code, chain, smotif start residue, loop length, ss1 length, ss2 length, type

=cut

sub add_partial_motif {
	my ($self, @proptable)=@_;
	#get filename and mysql info, if a simple smotif nid is given
	my $check=0;
	my @idtable;
	my @lm;
	my $seq='';
	if (scalar(@proptable) eq 8) {
		@idtable=@proptable;
	} else {
		# GeometricalCalculations::getnid(\@proptable, \@idtable);
		SmotifCS::MYSQLSmotifs::getnid(\@proptable, \@idtable);
	}
    my @ca=SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'CA',\$seq);
	my @n=SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'N',\$seq);
	my @c=SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'C',\$seq);
	my @cb=SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'CB',\$seq);
	my @o=SmotifCS::GeometricalCalculations::get_from_file(\@idtable,\@lm,'O',\$seq);
	# generate missing C-beta atoms for glycine residues
	for (my $aa=0;$aa<scalar(@cb);$aa++) {
		if ($cb[$aa]==0) {
			$cb[$aa]=[SmotifCS::GeometricalCalculations::findcb(\@{$ca[$aa]},\@{$c[$aa]},\@{$n[$aa]})];
		}
	}
	unshift(@lm,0);
	# align last residues of previous motif with last residues of ss1 in current motif
	my @prevlm=$self->one_landmark($self->num_motifs-1);
	my $num_to_align=$prevlm[3]-$prevlm[2];
	if ($num_to_align>$lm[1]) {$num_to_align=$lm[1]};
	my @cap=$self->get_coords('ca',$prevlm[3]-$num_to_align,$prevlm[3]-1);
	my @np=$self->get_coords('n',$prevlm[3]-$num_to_align,$prevlm[3]-1);
	my @cp=$self->get_coords('c',$prevlm[3]-$num_to_align,$prevlm[3]-1);
	my @x=(@cap,@np,@cp);
	my @y=(@ca[$lm[1]-$num_to_align..$lm[1]-1],@n[$lm[1]-$num_to_align..$lm[1]-1],@c[$lm[1]-$num_to_align..$lm[1]-1]);
	my @extra=(@ca,@n,@c,@cb,@o);
    
    # scalar(@x)=number of atoms, 
    # x=template to align to, 
    # y=template to align, 
    # extra=additional points 'carried along' during alignment
	my $rms=SmotifCS::GeometricalCalculations::superpose(scalar(@x),\@x,\@y,\@extra);	
	my @newca;
	my @newn;
	my @newc;
	my @newcb;
	my @newo;
	for (my $aa=$lm[1];$aa<$lm[3];$aa++) {
		push(@newca, $extra[$aa]);
		push(@newn, $extra[scalar(@ca)+$aa]);
		push(@newc, $extra[2*scalar(@ca)+$aa]);
		push(@newcb, $extra[3*scalar(@ca)+$aa]);
		push(@newo, $extra[4*scalar(@ca)+$aa]);
	}
	my @temp=($prevlm[2],$prevlm[3],$prevlm[3]+$lm[2]-$lm[1],$prevlm[3]+$lm[3]-$lm[1]);
	$self->one_landmark(-1,@temp);
	for (my $aa=$temp[1];$aa<$temp[3];$aa++) {
		if (exists(${$self->{ca}}[$aa])) {
			$self->change_pt('ca',$aa,@{$newca[$aa-$temp[1]]});
			$self->change_pt('c',$aa,@{$newc[$aa-$temp[1]]});
			$self->change_pt('n',$aa,@{$newn[$aa-$temp[1]]});
			$self->change_pt('cb',$aa,@{$newcb[$aa-$temp[1]]});
			$self->change_pt('o',$aa,@{$newo[$aa-$temp[1]]});
		} else {
			my $bbbb=$aa-$temp[1]+$lm[1];
			push(@{$self->{ca}},$newca[$aa-$temp[1]]);
			push(@{$self->{c}},$newc[$aa-$temp[1]]);
			push(@{$self->{n}},$newn[$aa-$temp[1]]);
			push(@{$self->{cb}},$newcb[$aa-$temp[1]]);
			push(@{$self->{o}},$newo[$aa-$temp[1]]);
		}
	}		
	$self->{num}++;
	push(@{$self->{type}},$idtable[7]);
	$self->axis($self->num_motifs-1,1,1);
	$self->axis($self->num_motifs-1,2,1);
	$self->lvec($self->num_motifs-1,1);
	$self->calc_angles($self->num_motifs-1,1);
	@lm=$self->one_landmark(-1);
	$self->get_seq($lm[1],$lm[3]-$lm[1],substr($seq,$lm[1]-$lm[3],$lm[3]-$lm[1]));
	my $aa=$self->{seq};
	my @aa=$self->one_landmark(1);
	$check=1;
	return $check;
}

=head2 axis

	Calculates or returns the axis corresponding to a given motif ss
	test->axis(mot, ss, option)

	Inputs:
	mot = smotif number
	ss = secondary structure in the motif (either 1 or 2)
	option = recalculate and return (1) or just return (0)

=cut

sub axis {
	my ($self, $mot, $ss, $option) = @_;
	#option 0 = get, #option 1 = calculate
	my $v="axis".$ss;
	if ($option==1) {	#recalculate the axis based on the residues closest to the loop
		my @lm=$self->one_landmark($mot);
		my $first=$lm[0];
		my $last=$lm[1];
		if ($ss==2) {
			$first=$lm[2];
			$last=$lm[3];
		}
		my @ca=$self->get_coords('ca',$first,$last-1);
		my @c=$self->get_coords('c',$first,$last-1);
		my @n=$self->get_coords('n',$first,$last-1);
		my $type=${$self->{type}}[$mot];
		if ($last-$first==1) {
			for (my $aa=0;$aa<$self->num_motifs();$aa++) {
				my @lm2=$self->one_landmark($aa);
				print "@lm2\n";
			}
		}
		@{$self->{$v}[$mot]}=SmotifCS::GeometricalCalculations::get_axis(substr($type,$ss-1,1),$ss,0,$last-$first,\@ca,\@n,\@c);
	}	
	return @{$self->{$v}[$mot]};
}

=head2 cal_angles

	Calculates or returns the geometric parameters of an smotif (d, delta, theta, rho)
	test->calc_angles(mot, option)

	Inputs:
	mot = smotif number
	option = recalculate and return (1) or just return (0)

=cut

sub calc_angles {
	my ($self, $mot, $option) = @_;
	#option 0 = get, option 1 = calculate
	if ($option==1) {	#recalculate
		my @lm=$self->one_landmark($mot);
		my @ax1=$self->axis($mot,1,0);	#secondary structure 1
		my @ax2=$self->axis($mot,2,0);	#secondary structure 2
		my @lvec=$self->lvec($mot,1);	#vector joining flanking residues
		my @list=SmotifCS::GeometricalCalculations::calc_geom(\@lvec, \@ax1, \@ax2);	#calculate the geometric parameters
		$self->{delta}[$mot]=$list[0];
		$self->{theta}[$mot]=$list[1];
		$self->{rho}[$mot]=$list[2];
	}
	return ($self->{d}[$mot], $self->{delta}[$mot], $self->{theta}[$mot], $self->{rho}[$mot]);
}	

=head2 rotate_theta

	Changes the theta (packing) angle of an smotif in a structure - all the torsional 'stress' is placed on the flanking residue
	test->rotate_theta(mot, ang)

	Inputs:
	mot = smotif number
	ang = degrees by which to change the theta angle

=cut

sub rotate_theta {
	my ($self, $mot, $ang) = @_;
	my @e1=$self->axis($mot,1,0);
	my @e2=$self->axis($mot,2,0);
	my @lm=$self->one_landmark($mot);
	$self->calc_angles($mot,1);
	my @point=@{$self->get_coords('ca',$lm[2],$lm[2])};
	my @ca     = $self->get_coords('ca',$lm[2],$lm[3]-1);
	my @com    = SmotifCS::GeometricalCalculations::COM(0,$lm[3]-$lm[2],\@ca,\@ca,\@ca);
	my @p2     = SmotifCS::GeometricalCalculations::projectpoint(\@point,\@e2,\@com);
	my $proj   = SmotifCS::GeometricalCalculations::dot(@e1,@e2);
	my @proj   =($e2[0]-$proj*$e1[0],$e2[1]-$proj*$e1[1],$e2[2]-$proj*$e1[2]);
	my @rotvec = SmotifCS::GeometricalCalculations::unit(SmotifCS::GeometricalCalculations::cross(@e1,@proj));
	my @arr    =$self->one_landmark(-1);
	
	for (my $aa=$lm[2];$aa<$arr[3];$aa++) {
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('ca',$aa,$aa)},@p2);
		$self->change_pt(
            'ca',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@rotvec,\$ang),
                @p2
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('n',$aa,$aa)},@p2);
		$self->change_pt(
            'n',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@rotvec,\$ang),
                @p2
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('c',$aa,$aa)},@p2);
		$self->change_pt(
            'c',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@rotvec,\$ang),
                @p2
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('cb',$aa,$aa)},@p2);
		$self->change_pt(
            'cb',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@rotvec,\$ang),
                @p2
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('o',$aa,$aa)},@p2);
		$self->change_pt(
            'o',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@rotvec,\$ang),
                @p2
            )
        );
	}
	#recalculate axes and angles
	$self->axis($mot,1,1);
	$self->axis($mot,2,1);
	$self->lvec($mot,1);
	$self->calc_angles($mot,1);
}


=head2 rotate_rho 

	Changes the rho (meridian) angle of an smotif in a structure - all the torsional 'stress' is placed on the flanking residue
	test->rotate_rho(mot, ang)

	Inputs:
	mot = smotif number
	ang = degrees by which to change the rho angle

=cut

sub rotate_rho {
	my ($self, $mot, $ang) = @_;
	my @e1 = $self->axis($mot,1,0);
	my @e2 = $self->axis($mot,2,0);
	my @lm = $self->one_landmark($mot);
	my @point = @{$self->get_coords('ca',$lm[2],$lm[2])};
	my @ca  = $self->get_coords('ca',$lm[2],$lm[3]-1);
	my @com = SmotifCS::GeometricalCalculations::COM(0,$lm[3]-$lm[2],\@ca,\@ca,\@ca);
	my @p2  = SmotifCS::GeometricalCalculations::projectpoint(\@point,\@e2,\@com);
	my @angs= $self->calc_angles($mot,1);
	my @arr = $self->one_landmark(-1);
	my @startpt = @p2;
	my @rotvec  = @e1;
	
	for (my $aa=$lm[2];$aa<$arr[3];$aa++) {
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('ca',$aa,$aa)},@p2);
		$self->change_pt(
            'ca',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@e1,\$ang),
                @p2
            )
         );
		 @point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('n',$aa,$aa)},@p2);
		$self->change_pt(   
                'n',
                $aa,
                SmotifCS::GeometricalCalculations::vecadd(
                    1,
                    SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@e1,\$ang),
                    @p2
                )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('c',$aa,$aa)},@p2);
		$self->change_pt(
            'c',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@e1,\$ang),
                @p2
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('cb',$aa,$aa)},@p2);
		$self->change_pt(
            'cb',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@e1,\$ang),
                @p2
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('o',$aa,$aa)},@p2);
		$self->change_pt(
            'o',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@e1,\$ang),
                @p2
            )
         );
	}
	#theta angle will have been modified as well - recalculate theta and adjust it
	@e2 = $self->axis($mot,2,1);
	my $rotangle = $angs[2]-((acos(SmotifCS::GeometricalCalculations::dot(@e1,@e2)))*180/3.14159265);
	$self->rotate_theta($mot,$rotangle);
}

=head2 rotate_delta

Changes the delta (hoist) angle of an smotif in a structure - all the torsional 'stress' is placed on the flanking residue
test->rotate_delta(mot, ang) 

Inputs:

mot = smotif number
ang = degrees by which to change the delta angle
=cut

sub rotate_delta {
	my ($self, $mot, $ang) = @_;
	my @e1 =$self->axis($mot,1,1);
	my @e2 =$self->axis($mot,2,1);
	my @lm =$self->one_landmark($mot);
	my @point=@{$self->get_coords('ca',$lm[1]-1,$lm[1]-1)};
	my @ca =$self->get_coords('ca',$lm[0],$lm[1]-1);
	my @com = SmotifCS::GeometricalCalculations::COM(0,$lm[1]-$lm[0],\@ca,\@ca,\@ca);
	my @p1  = SmotifCS::GeometricalCalculations::projectpoint(\@point,\@e1,\@com);
	my @lvec=$self->lvec($mot,1);
	my @oldangs=$self->calc_angles($mot,1);
	
	my $rad=180/3.14159265;
	my @prevc=@{$self->get_coords('c',$lm[2]-1,$lm[2]-1)};
	
	my @normal = SmotifCS::GeometricalCalculations::unit(
        SmotifCS::GeometricalCalculations::cross(@e1,@lvec)
    );
	
    my @arr = $self->one_landmark(-1);
	#change the delta angle by rotating around the anchor of the loop, like a hinge
	for (my $aa=$lm[1];$aa<$arr[3];$aa++) {
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('ca',$aa,$aa)},@p1);
		$self->change_pt(
            'ca',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@normal,\$ang),
                @p1
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('n',$aa,$aa)},@p1);
		$self->change_pt(
            'n',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@normal,\$ang),
                @p1
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('c',$aa,$aa)},@p1);
		$self->change_pt(
            'c',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@normal,\$ang),
                @p1
            )
        );
		
        @point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('cb',$aa,$aa)},@p1);
		$self->change_pt(
            'cb',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@normal,\$ang),
                @p1
            )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('o',$aa,$aa)},@p1);
		$self->change_pt(
            'o',
            $aa,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@normal,\$ang),
                @p1
            )
        );
	}
	for (my $aa=0;$aa<$self->num_motifs;$aa++) {
		$self->axis($aa,1,1);
		$self->axis($aa,2,1);
		$self->lvec($mot,1);
	}
	#rho and theta angles will have changed - modify them back to their original values
	my @newangs=$self->calc_angles($mot,1);
	my $inc=$oldangs[2]-$newangs[2];
	$self->rotate_theta($mot,$oldangs[2]-$newangs[2]);
	@newangs=$self->calc_angles($mot,0);
	$self->rotate_rho($mot,$oldangs[3]-$newangs[3]);
}

=head2 lvec

	Calculates or returns the l-vector (vector joining the flanking loop residues)
	test->lvec(mot, option)

	Inputs:

	mot = smotif number
	option = recalculate and return (1) or just return (0)
=cut

sub lvec {
	my ($self,$mot,$option) = @_;
	#option=0, return, option=1 calculate
	if ($option==1) {	#recalculate
		my @e1 = $self->axis($mot,1,0);
		my @e2 = $self->axis($mot,2,0);
		my @lm = $self->one_landmark($mot);
		my @point = @{$self->get_coords('ca',$lm[1]-1,$lm[1]-1)};
		my @ca  = $self->get_coords('ca',$lm[0],$lm[1]-1);
		my @com = SmotifCS::GeometricalCalculations::COM(0,$lm[1]-$lm[0],\@ca,\@ca,\@ca);
		my @p1  = SmotifCS::GeometricalCalculations::projectpoint(\@point,\@e1,\@com);
		@point = @{$self->get_coords('ca',$lm[2],$lm[2])};
		@ca = $self->get_coords('ca',$lm[2],$lm[3]-1);
		@com   = SmotifCS::GeometricalCalculations::COM(0,$lm[3]-$lm[2],\@ca,\@ca,\@ca);
		my @p2 = SmotifCS::GeometricalCalculations::projectpoint(\@point,\@e2,\@com);
		my @t1 = SmotifCS::GeometricalCalculations::vecadd(-1,@p2,@p1);
		my $d  = SmotifCS::GeometricalCalculations::norm(@t1);
		my @lvec=SmotifCS::GeometricalCalculations::unit(@t1);
		@{$self->{lvec}[$mot]}=@lvec;
		$self->{d}[$mot]=$d;
	}
	return @{$self->{lvec}[$mot]};
}

=head2 shorten

	Shortens a secondary structure by removing a specified number of residues
	test->shorten(mot, num)

	Inputs:

	mot = secondary structure number (use -1 for the last secondary structure)
	num = number of residues to shorten by

=cut

sub shorten {
	my ($self,$mot,$num) = @_;
	#motif number is where ss occurs as first structure
	#motif number = -1 shortens the final ss
	if ($mot eq 0) {	#first secondary structure, simply remove the initial residues and recalculate landmarks
		@{$self->{ca}} = $self->get_coords('ca',$num,$self->num_res-1);
		@{$self->{n}}  = $self->get_coords('n',$num,$self->num_res-1);
		@{$self->{c}}  = $self->get_coords('c',$num,$self->num_res-1);
		@{$self->{cb}} = $self->get_coords('cb',$num,$self->num_res-1);
		@{$self->{o}}  = $self->get_coords('o',$num,$self->num_res-1);
		#recalculating landmarks
		my @lm=$self->one_landmark(0);
		$lm[1] -= $num;	
		$lm[2] -= $num;
		$lm[3] -= $num;
		@{$self->{lm}[0]}=@lm;
		$self->{seq}=substr($self->{seq},$num,$self->num_res);
		for (my $aa=1;$aa<$self->num_motifs;$aa++) {
			@lm=$self->one_landmark($aa);
			for (my $bb=0;$bb<4;$bb++) {
				$lm[$bb] -= $num;
			}
			@{$self->{lm}[$aa]}=@lm;
		}
	} elsif ($mot eq -1) {	#last secondary structure, simply remove final residues and recalculate landmarks
		@{$self->{ca}} = $self->get_coords('ca',0,$self->num_res-$num-1);
		@{$self->{n}}  = $self->get_coords('n',0,$self->num_res-$num-1);
		@{$self->{c}}  = $self->get_coords('c',0,$self->num_res-$num-1);
		@{$self->{cb}} = $self->get_coords('cb',0,$self->num_res-$num-1);
		@{$self->{o}}  = $self->get_coords('o',0,$self->num_res-$num-1);
		my @lm=$self->one_landmark(-1);
		$lm[3] -= $num;
		$self->{seq}=substr($self->{seq},0,$self->num_res-$num);
		@{$self->{lm}[-1]}=@lm;
	} else {	#intermediate secondary structure, remove residues starting from the previous loop and re-align the remaining residues
		my @lmkeep=$self->one_landmark($mot);
		my $total=$self->num_res;
		#remember the position of the last c atom
		#use 4 residue blocks to align residues, smaller blocks if secondary structure does not have 4 residues
		my $num_to_align=4;
		if ($lmkeep[1]-$lmkeep[0]<$num_to_align) {$num_to_align=$lmkeep[1]-$lmkeep[0]};
		my @cap=$self->get_coords('ca',$lmkeep[0],$lmkeep[0]+$num_to_align-1);
		my @np=$self->get_coords('n',$lmkeep[0],$lmkeep[0]+$num_to_align-1);
		my @cp=$self->get_coords('c',$lmkeep[0],$lmkeep[0]+$num_to_align-1);
		my @x=(@cap,@np,@cp);
		my @can=$self->get_coords('ca',$lmkeep[0]+$num,$lmkeep[0]+$num+$num_to_align-1);
		my @nn=$self->get_coords('n',$lmkeep[0]+$num,$lmkeep[0]+$num+$num_to_align-1);
		my @cn=$self->get_coords('c',$lmkeep[0]+$num,$lmkeep[0]+$num+$num_to_align-1);
		my @y=(@can,@nn,@cn);
		my @car=$self->get_coords('ca',$lmkeep[0]+$num,$total-1);
		my @nr=$self->get_coords('n',$lmkeep[0]+$num,$total-1);
		my @cr=$self->get_coords('c',$lmkeep[0]+$num,$total-1);
		my @cbr=$self->get_coords('cb',$lmkeep[0]+$num,$total-1);
		my @or=$self->get_coords('o',$lmkeep[0]+$num,$total-1);
		my $len=scalar(@car);
		my @extra=(@car,@nr,@cr,@cbr,@or);
		# c=number, 
        # x=template to align to, 
        # y=template to align, 
        # extra=things to align
		my $rms = SmotifCS::GeometricalCalculations::superpose(scalar(@x),\@x,\@y,\@extra);	
		my @newca = @extra[0..$len-1];
		my @newn  = @extra[$len..2*$len-1];
		my @newc  = @extra[2*$len..3*$len-1];
		my @newcb = @extra[3*$len..4*$len-1];
		my @newo  = @extra[4*$len..5*$len-1];

		#insert new coordinates, overwriting the old ones
		for (my $aa=0;$aa<$len;$aa++) {
			$self->change_pt('ca',$aa+$lmkeep[0],@{$newca[$aa]});
			$self->change_pt('n',$aa+$lmkeep[0],@{$newn[$aa]});
			$self->change_pt('c',$aa+$lmkeep[0],@{$newc[$aa]});
			$self->change_pt('cb',$aa+$lmkeep[0],@{$newcb[$aa]});
			$self->change_pt('o',$aa+$lmkeep[0],@{$newo[$aa]});
		}
		#adjust landmarks
		my @lm=$self->one_landmark($mot);
		$lm[1] -= $num;
		$lm[2] -= $num;
		${$self->{lm}[$mot-1]}[3] -= $num;
		$lm[3] -= $num;
		@{$self->{lm}[$mot]}=@lm;
		my $start=$mot+1;
		if ($start==0) {$start=$self->num_motifs};
		for (my $aa=$start;$aa<$self->num_motifs;$aa++) {
			@lm=$self->one_landmark($aa);
			for (my $bb=0;$bb<4;$bb++) {
				$lm[$bb] -= $num;
			}
			@{$self->{lm}[$aa]}=@lm;
		}
		#change sequence
		my @seq=split('',$self->{seq});
		splice(@seq,$lmkeep[0],$num);
		$self->{seq}=join('',@seq);
		#recalculate geometric parameters
		for (my $aa=0;$aa<$self->num_motifs;$aa++) {
			$self->axis($aa,1,1);
			$self->axis($aa,2,1);
			$self->lvec($aa,1);
			my @newangles=$self->calc_angles($aa,1);
		}			
		return 1;
	} 
}


=head2 elongate

	Elongates a secondary structure by a specified number of residues. The elongation is performed
	by sequentially taking a portion of the C-terminal end of the secondary structure, shifting it 
	by one residue, and aligning it to the unshifted end, thus generating the coordinates of one 
	new residue at a time.
	test->elongate(mot, num)

	Inputs:

	mot = secondary structure number (use -1 for the final secondary structure)
	num = number of residues to extend the secondary strucure by

=cut

sub elongate {
	my ($self,$mot,$num) = @_;
	#motif number is where ss occurs as first structure
	#motif number = -1 elongates the final ss
	my $set=4;	#size of block used for alignment and extension
	my @startlm=$self->one_landmark($mot);
	#make block size smaller if the secondary structure does not have enough residues
	if (($mot eq -1) and ($startlm[3]-$startlm[2]<5)) {
		$set=$startlm[3]-$startlm[2]-1;	
	}
	if (($mot ne -1) and ($startlm[1]-$startlm[0]<5)) {
		$set=$startlm[1]-$startlm[0]-1;
	}
	if ($mot eq 0) {	#initial secondary structure - elongate the N-terminal end
		my $addstr='';
		for (my $aa=0;$aa<$num;$aa++) {
			#get coords of resid 2-5
			my @toalign=($self->get_coords('ca',1,$set),$self->get_coords('n',1,$set),$self->get_coords('c',1,$set),$self->get_coords('cb',1,$set),$self->get_coords('o',1,$set));
			#get coords of resid 0-4
			my @template=($self->get_coords('ca',0,$set-1),$self->get_coords('n',0,$set-1),$self->get_coords('c',0,$set-1),$self->get_coords('cb',0,$set-1),$self->get_coords('o',0,$set-1));	
			#get coords of resid 0
			my @newpoints=($self->get_coords('ca',0,0),$self->get_coords('n',0,0),$self->get_coords('c',0,0),$self->get_coords('cb',0,0),$self->get_coords('o',0,0));
			#superimpose residues 2-5 onto 1-4, thereby making residue 1 an extension in the N-terminal direction
			SmotifCS::GeometricalCalculations::superpose(5*$set,\@template,\@toalign,\@newpoints);
			#add extra, elongated residue
			unshift(@{$self->{ca}},$newpoints[0]);
			unshift(@{$self->{n}},$newpoints[1]);
			unshift(@{$self->{c}},$newpoints[2]);
			unshift(@{$self->{cb}},$newpoints[3]);
			unshift(@{$self->{o}},$newpoints[4]);
			#add alanine to sequence
			$addstr = $addstr.'A';
		}			
		#adjust landmarks
		my @lm=$self->one_landmark(0);
		$lm[1] += $num;
		$lm[2] += $num;
		$lm[3] += $num;
		@{$self->{lm}[0]}=@lm;
		$self->{seq}=$addstr.$self->{seq};
		for (my $aa=1;$aa<$self->num_motifs;$aa++) {
			@lm=$self->one_landmark($aa);
			for (my $bb=0;$bb<4;$bb++) {
				$lm[$bb] += $num;
			}
			@{$self->{lm}[$aa]}=@lm;
		}
	} elsif ($mot eq -1) {	#final secondary structure
		my $addstr='';
		for (my $aa=0;$aa<$num;$aa++) {
			my $last=$self->num_res;
			# get coordinates of residues -5 to -2 (where -1 is the last residue)
			my @toalign = (
                $self->get_coords('ca',$last-$set-1,$last-2),
                $self->get_coords('n',$last-$set-1,$last-2),
                $self->get_coords('c',$last-$set-1,$last-2),
                $self->get_coords('cb',$last-$set-1,$last-2),
                $self->get_coords('o',$last-$set-1,$last-2)
            );
			# get coordinates of residues -4 to -1 (where -1 is the last residue)
			my @template = (
                $self->get_coords('ca',$last-$set,$last-1),
                $self->get_coords('n',$last-$set,$last-1),
                $self->get_coords('c',$last-$set,$last-1),
                $self->get_coords('cb',$last-$set,$last-1),
                $self->get_coords('o',$last-$set,$last-1)
            );
			# get coordinates of residue -1 (the last residue)	
			my @newpoints = (
                $self->get_coords('ca',$last-1,$last-1),
                $self->get_coords('n',$last-1,$last-1),
                $self->get_coords('c',$last-1,$last-1),
                $self->get_coords('cb',$last-1,$last-1),
                $self->get_coords('o',$last-1,$last-1)
            );
			
            # superimpose resiudes -5 to -2 onto -4 to -1, thereby making residue -1 an extension in the C-terminal direction
			SmotifCS::GeometricalCalculations::superpose(5*$set,\@template,\@toalign,\@newpoints);
			#add coordinates of extra residue
			push(@{$self->{ca}},$newpoints[0]);
		 	push(@{$self->{n}},$newpoints[1]);
			push(@{$self->{c}},$newpoints[2]);
			push(@{$self->{cb}},$newpoints[3]);
			push(@{$self->{o}},$newpoints[4]);
			#add alanine to sequence
			$addstr = $addstr.'A';
			my @lm=$self->one_landmark(-1);
			$lm[3]++;
			@{$self->{lm}[-1]}=@lm;
		}	
		$self->{seq}=$self->{seq}.$addstr;
	} else {	#intermediate secondary structure
		my @lmkeep = $self->one_landmark($mot);
		my $total  = $self->num_res;
		#align 4 residues, fewer if the ss is shorter
		my $num_to_align=4;
		if ($lmkeep[1]-$lmkeep[0]<$num_to_align) {$num_to_align=$lmkeep[1]-$lmkeep[0]};
		my @cap=$self->get_coords('ca',$lmkeep[0],$lmkeep[0]+$num_to_align-1);
		my @np=$self->get_coords('n',$lmkeep[0],$lmkeep[0]+$num_to_align-1);
		my @cp=$self->get_coords('c',$lmkeep[0],$lmkeep[0]+$num_to_align-1);
		my @x=(@cap,@np,@cp);
		my @can=$self->get_coords('ca',$lmkeep[0]+$num,$lmkeep[0]+$num+$num_to_align-1);
		my @nn=$self->get_coords('n',$lmkeep[0]+$num,$lmkeep[0]+$num+$num_to_align-1);
		my @cn=$self->get_coords('c',$lmkeep[0]+$num,$lmkeep[0]+$num+$num_to_align-1);
		my @y=(@can,@nn,@cn);
		my @car=$self->get_coords('ca',$lmkeep[0]+$num,$total-1);
		my @nr=$self->get_coords('n',$lmkeep[0]+$num,$total-1);
		my @cr=$self->get_coords('c',$lmkeep[0]+$num,$total-1);
		my @cbr=$self->get_coords('cb',$lmkeep[0]+$num,$total-1);
		my @or=$self->get_coords('o',$lmkeep[0]+$num,$total-1);
		my $len=scalar(@car);
		my @extra = (@car,@nr,@cr,@cbr,@or);
		
        # c=number, x=template to align to, y=template to align, extra=things to align
		my $rms = SmotifCS::GeometricalCalculations::superpose(scalar(@x),\@x,\@y,\@extra);	
		my @newca = @extra[0..$len-1];
		my @newn  = @extra[$len..2*$len-1];
		my @newc  = @extra[2*$len..3*$len-1];
		my @newcb = @extra[3*$len..4*$len-1];
		my @newo  = @extra[4*$len..5*$len-1];

		#shift coords
		for (my $aa=0;$aa<$len;$aa++) {
			$self->change_pt('ca',$aa+$lmkeep[0],@{$newca[$aa]});
			$self->change_pt('n',$aa+$lmkeep[0],@{$newn[$aa]});
			$self->change_pt('c',$aa+$lmkeep[0],@{$newc[$aa]});
			$self->change_pt('cb',$aa+$lmkeep[0],@{$newcb[$aa]});
			$self->change_pt('o',$aa+$lmkeep[0],@{$newo[$aa]});
		}
		#change landmarks
		my @lm=$self->one_landmark($mot);
		$lm[1] -= $num;
		$lm[2] -= $num;
		${$self->{lm}[$mot-1]}[3] -= $num;
		$lm[3] -= $num;
		@{$self->{lm}[$mot]}=@lm;
		my $start=$mot+1;
		if ($start==0) {$start=$self->num_motifs};
		for (my $aa=$start;$aa<$self->num_motifs;$aa++) {
			@lm=$self->one_landmark($aa);
			for (my $bb=0;$bb<4;$bb++) {
				$lm[$bb] -= $num;
			}
			@{$self->{lm}[$aa]}=@lm;
		}
		#change sequence
		my @seq=split('',$self->{seq});
		splice(@seq,$lmkeep[0],$num);
		$self->{seq}=join('',@seq);
		#recalculate geometric parameters
		for (my $aa=0;$aa<$self->num_motifs;$aa++) {
			$self->axis($aa,1,1);
			$self->axis($aa,2,1);
			$self->lvec($aa,1);
			my @newangles=$self->calc_angles($aa,1);
		}			
		return 1;
	} 
}

=head2 check_ster_viols

	Checks for steric distance violations in a structure, given an inter-atomic distance and an atom type
	@violations=test->check_ster_viols(atom, sterdist)

	Inputs:

	atom = backbone atom type, can be 'all', 'ca', 'c', 'n', 'cb', 'o'
	sterdist = distance (Angstrom) under which a violation is recorded

	OUTPUTS:
	
	If a specific atom type is specified, output array contains (residue numbers that clash, minimum distance), 
	or (100,100) if no clashes
	If atom type is specified as 'all', output array contains (residue numbers that clash, atom types that 
	clash, minimum distance), or (100,100) if no clashes

	Note: In all cases, only the 'worst offending' set of atoms (i.e. the pair with smallest inter-atomic distance) is returned

=cut

sub check_ster_viols {
    my ($self,$atom,$sterdist) = @_;
    
    my @lm    = $self->one_landmark(-1);
    $sterdist = $sterdist**2;
    my $ster  = 0;
    my @min   = (100,100);	#minimum inter-atomic distance (most extreme violation)
    my $viols = 0;
    my $seq = $self->{seq};
	
    if ($atom ne 'all') {	#check a single atom type
        OUTLOOP:for (my $aa=0;$aa<$self->num_res();$aa++) {
            if (($atom eq 'cb') and (substr($seq,$aa,1) eq 'G')) {
                next OUTLOOP;
            }	#glycine, no beta-carbon
            INLOOP:for (my $bb=$aa+2;$bb<$self->num_res();$bb++) {
                my $dist = SmotifCS::GeometricalCalculations::norm2(
                    GeometricalCalculations::vecadd(
                    -1,
                    @{$self->get_coords($atom,$aa,$aa)},
                    @{$self->get_coords($atom,$bb,$bb)}
                    )
                );
                if ($dist<$sterdist) {
                    if ($dist<$min[2]) {@min=($aa,$bb,$dist);}
                    $viols++;
                }
            }
        }
     
     } 
     else {	 #all atom types, check every pairwise distance
        my @atomlist=('ca','c','n','cb','o');
        for (my $aa=0;$aa<$self->num_res();$aa++) {
            for (my $bb=$aa+2;$bb<$self->num_res();$bb++) {
                LOOP1:foreach my $at1 (@atomlist) {
                    # glycine, no beta carbon
                    if (($at1 eq 'cb') and ((substr($seq,$aa,1) eq 'G') or (substr($seq,$bb,1) eq 'G'))) {
                        next LOOP1;
                    }
                    LOOP2:foreach my $at2 (@atomlist) {
                            # glycine, no beta carbon
                            if (($at2 eq 'cb') and ((substr($seq,$aa,1) eq 'G') or (substr($seq,$bb,1) eq 'G'))) {
                                next LOOP2;
                            }
                            my $dist = SmotifCS::GeometricalCalculations::norm2( 
                                    SmotifCS::GeometricalCalculations::vecadd(
                                            -1,
                                            @{$self->get_coords($at1,$aa,$aa)},
                                            @{$self->get_coords($at2,$bb,$bb)}
                                    )
                            );
                            if ($dist<$sterdist) {
                                if ($dist<$min[-1]) {@min=($aa,$bb,$at1,$at2,$dist);}
                                    $viols++;
                                }
                            }
                    }
                }
        }
    }
    return (@min,$viols);
}

=head2 statpot

	Calculates the total statistical potential scoring function value using Rykunov's potential
	test->statpot()

	Note: test->stat_table() has to be called before running this method

=cut

sub statpot {
	my ($self) = @_;
	my $max=10;	#inter-atomic distance cutoff
	my $counts=0;
	for (my $aa=0;$aa<$self->num_res;$aa++) {	#sum pairwise potential for all cb atoms
		for (my $bb=$aa+1;$bb<$self->num_res;$bb++) {
			my @ca1 = @{$self->get_coords('ca',$aa,$aa)};
			my @cb1 = @{$self->get_coords('cb',$aa,$aa)};
			my @ca2 = @{$self->get_coords('ca',$bb,$bb)};
			my @cb2 = @{$self->get_coords('cb',$bb,$bb)};
			my $d = SmotifCS::GeometricalCalculations::norm(
                    SmotifCS::GeometricalCalculations::vecadd(-1,@cb1,@cb2)
            );
			if (($d>3) and ($d<$max)) {
				my @cab1 = SmotifCS::GeometricalCalculations::vecadd(-1,@cb1,@ca1);
				my @cab2 = SmotifCS::GeometricalCalculations::vecadd(-1,@cb2,@ca2);
				$d=int($d);
				my $hashtag=$d.$self->get_seq($aa,1).$self->get_seq($bb,1);
				if (SmotifCS::GeometricalCalculations::dot(@cab1,@cab2) >= 0) {
					$hashtag="p$hashtag"; #ca-cb vectors are parallel
				} else {
					my $caadist = SmotifCS::GeometricalCalculations::norm2(
                            SmotifCS::GeometricalCalculations::vecadd(-1,@ca1,@ca2)
                    );
					my $cbbdist = SmotifCS::GeometricalCalculations::norm2(
                            SmotifCS::GeometricalCalculations::vecadd(-1,@cb1,@cb2)
                    );
					if ($cbbdist<=$caadist) {$hashtag="f$hashtag"} #c-beta atoms are facing each other
					else {$hashtag="a$hashtag"}	#c-beta atoms are facing opposite directions
				}
				if (exists(${$self->{statpot}}{$hashtag})) {
					$counts += ${$self->{statpot}}{$hashtag};
				}
			}
		}
	}
	return $counts/$self->num_res;
}


=head2 rmsd

	Returns the RMSD between the backbone atoms (CA, C, N, and O) of the structures in test and test2
	rmsd=test->rmsd(test2)

	NOTE: test2 must have at least as many residues as $test1

=cut

sub rmsd {
	my ($self,$other) = @_;
	
    my $last = $self->num_res;
	my @c1 = (  
        $self->get_coords('ca',0,$last-1),
        $self->get_coords('c',0,$last-1),
        $self->get_coords('n',0,$last-1)
    );
	my @c2 = (
        $other->get_coords('ca',0,$last-1),
        $other->get_coords('c',0,$last-1),
        $other->get_coords('n',0,$last-1)
    );
	if (scalar(@c2) ne scalar(@c1)) {
        print "different lengths for rmsd: ",scalar(@c1)," and ",scalar(@c2),"\n";
    }
	
    # if the structures have oxygen atoms, add them
	if ((exists(${$self->{o}}[$last-2])) and (exists(${$other->{o}}[$last-2]))) {
		push(@c1,$self->get_coords('o',0,$last-2));
		push(@c2,$other->get_coords('o',0,$last-2));
	}
	return SmotifCS::GeometricalCalculations::find_rmsd(scalar(@c1),\@c1,\@c2);
}

=head2 rmsd_loops

	Returns the RMSD between the backbone atoms (CA, C, N, and O) in all the loop regions of the test1 
	and test2 structures
	rmsd=test->rmsd_loops(test2)

	NOTE: test2 must have at least as many loop residues as test1

=cut

sub rmsd_loops {
	my ($self,$other)=@_;
	my @c1;
	my @c2;
	for (my $aa=0;$aa<$self->num_motifs;$aa++) {
		my @lm =$self->one_landmark($aa);
		push(@c1, (
                $self->get_coords('ca',$lm[1],$lm[2]-1),
                $self->get_coords('c',$lm[1],$lm[2]-1),
                $self->get_coords('n',$lm[1],$lm[2]-1)
                )
        );
		
        push( @c2,(
                $other->get_coords('ca',$lm[1],$lm[2]-1),
                $other->get_coords('c',$lm[1],$lm[2]-1),
                $other->get_coords('n',$lm[1],$lm[2]-1)
                )
        );
	}   
	return SmotifCS::GeometricalCalculations::find_rmsd(scalar(@c1),\@c1,\@c2);
}


=head2 rmsd_loops_flanking_ss

	Returns the RMSD between the backbone atoms (CA, C, N, and O) in all the loop regions and 
	flanking 3 ss residues of the test1 anf test2 structures
	rmsd=test->rmsd_loops_flanking_ss(test2) 

	NOTE: test2 must have at least as many loop residues as test1

=cut

sub rmsd_loops_flanking_ss {
        my ($self,$other)=@_;
        my @c1;
        my @c2;
        for (my $aa = 0;$aa < $self->num_motifs; $aa++) {
                my @lm = $self->one_landmark($aa);
                push ( @c1,(
                    $self->get_coords('ca',$lm[1]-3,$lm[2]+2),
                    $self->get_coords('c',$lm[1]-3,$lm[2]+2),
                    $self->get_coords('n',$lm[1]-3,$lm[2]+2)
                    )
                );
                push( @c2, (
                        $other->get_coords('ca',$lm[1]-3,$lm[2]+2),
                        $other->get_coords('c',$lm[1]-3,$lm[2]+2),
                        $other->get_coords('n',$lm[1]-3,$lm[2]+2)
                        )
                );
        }
        return SmotifCS::GeometricalCalculations::find_rmsd(scalar(@c1),\@c1,\@c2);
}


=head2 rmsd_ss

	Returns the RMSD between the backbone atoms (CA, C, N, and O) in all the secondary 
	structure regions of the test1 and test2 structures.
	rmsd=test->rmsd_ss(test2,@order)

	The order of secondary structures in test structure are given by the optional array @order. 
	An example of @order would be (0 1 2 3 5 4), where the third secondary structure is oriented 
	in the reverse direction in test as opposed to test2. If @order is omitted, the routine 
	assumes the same order for both structures.

	NOTE: test2 must have the same ordered initial and intermediate secondary structure 
	lengths as test1, or else the function returns -1

=cut

sub rmsd_ss {
	my ($self,$other,@order)=@_;
	my @c1;
	my @c2;
	my @types=('ca','c','n');
	if (scalar(@order)==0) {
		@order=0..$self->num_motifs*2+1;
	}
	#get rearranged order of points in $self, based on @order
	my @points1;
	my @points2;
	#first, get straightforward list of residue numbers in all the secondary structures
	for (my $aa=0;$aa<$self->num_motifs;$aa++) {
		my @lm=$self->one_landmark($aa);
		push(@points1,[$lm[0]..$lm[1]-1]);
		my @lm2=$other->one_landmark($aa);
		push(@points2,$lm2[0]..$lm2[1]-1);
	}
	my @lm=$self->one_landmark(-1);
	push(@points1,[$lm[2]..$lm[3]-1]);	#last secondary structure
	my @lm2=$other->one_landmark(-1);
	push(@points2,$lm2[2]..$lm2[3]-1);

	#now, rearrange the residue numbers according to @order
	my @shuffledpoints1;
	for (my $aa=0;$aa<scalar(@order);$aa+=2) {
		my $ssnumber=int($order[$aa]/2);
		if ($order[$aa]<$order[$aa+1]) {	#normal secondary structure orientation
			push(@shuffledpoints1,@{$points1[$ssnumber]});	
		} else {				#reverse secondary structure orientation
			push(@shuffledpoints1,reverse(@{$points1[$ssnumber]}));
		}
	}

	#check to see that both structures have the same number of residues, otherwise return -1
	if (scalar(@points2) ne scalar(@shuffledpoints1)) {return -1}
	
	#get all the coordinates for both structures, making sure to get the points for $self in the shuffled order
	for (my $aa=0;$aa<scalar(@points2);$aa++) {
		foreach my $atomtype (@types) {
			push(@c1,$self->get_coords($atomtype,$shuffledpoints1[$aa],$shuffledpoints1[$aa]));
			push(@c2,$other->get_coords($atomtype,$points2[$aa],$points2[$aa]));
		}
	}
	my $rms = SmotifCS::GeometricalCalculations::find_rmsd(scalar(@c1),\@c1,\@c2);
	return $rms;
}

=head2 rmsd_anchor_order

	Returns the RMSD between the anchor points (a-carbons of the first and last residues 
	of all the secondary structures) of test and test2 structures, where the order of points 
	in test structure are given by the array @order. 

	An example of @order would be (0 1 2 3 5 4), where the third secondary structure is 
	oriented in the reverse direction in test as opposed to test2
	
	rmsd=test->rmsd_anchor_order(test2,@order)

=cut

sub rmsd_anchor_order {
        my ($self,$other,@order)=@_;
        #gather anchor point coordinates
        my @p1;
        my @p2;
        my @type1;
        my @type2;
        for (my $aa=0;$aa<$self->num_motifs;$aa++) {
                my @lm=$self->one_landmark($aa);
                push(@p1,$self->get_coords('ca',$lm[0],$lm[0]),$self->get_coords('ca',$lm[1]-1,$lm[1]-1));
                my $type=${$self->{type}}[$aa];
                $type =~ tr/AJR/E/;
                push(@type1,substr($type,0,1),substr($type,0,1));

        }
        for (my $aa=0;$aa<$other->num_motifs;$aa++) {
                my @lm=$other->one_landmark($aa);
                push(@p2,$other->get_coords('ca',$lm[0],$lm[0]),$other->get_coords('ca',$lm[1]-1,$lm[1]-1));
                my $type=${$other->{type}}[$aa];
                $type =~ tr/AJR/E/;
                push(@type2,substr($type,0,1),substr($type,0,1));
        }
        my @lm=$self->one_landmark(-1);
        push(@p1,$self->get_coords('ca',$lm[2],$lm[2]),$self->get_coords('ca',$lm[3]-1,$lm[3]-1));
        my $type=${$self->{type}}[-1];
        $type =~ tr/AJR/E/;
        push(@type1,substr($type,1,1),substr($type,1,1));
        @lm=$other->one_landmark(-1);
        push(@p2,$other->get_coords('ca',$lm[2],$lm[2]),$other->get_coords('ca',$lm[3]-1,$lm[3]-1));
        $type=${$other->{type}}[-1];
        $type =~ tr/AJR/E/;
        push(@type2,substr($type,1,1),substr($type,1,1));
	#rearrange the points in test1, as specified by the @order array
        my @temppts;
        foreach my $aa (@order) {
                push(@temppts,$p1[$aa]);
        }
        my $rmsd = SmotifCS::GeometricalCalculations::find_rmsd(scalar(@p2),\@p2,\@temppts);
        return $rmsd;
}

=head2 rmsd_ss_order

	Returns the RMSD between the secondary structure backbone atoms (C, N, CA) of test and test2 structures, 
	rmsd=test->rmsd_ss_order(test2,@order)

=cut

sub rmsd_ss_order {
	my ($self,$other,@order)=@_;
	#gather 


}


=head2 radius_of_gyration

	Calculates the radius of gyration of a structure using the backbone CA, C, and N atoms
	rad=test->radius_of_gyration()

=cut

sub radius_of_gyration {
	my ($self) = @_;
	my $last = $self->num_res;
	
    my @c1 = (
        $self->get_coords('ca',0,$last-1),
        $self->get_coords('c',0,$last-1),
        $self->get_coords('n',0,$last-1)
    );
	
    my @com = SmotifCS::GeometricalCalculations::COM2(0,3*$last,\@c1);
	my $rad = 0;
	foreach (@c1) {
		my @pt=@{$_};
		$rad += ( SmotifCS::GeometricalCalculations::norm(
                    SmotifCS::GeometricalCalculations::vecadd(-1,@pt,@com)
                    )
                )**2;
	}
	$rad /= (3*$last);
	return sqrt($rad);
}


=head2 superpose

	Optimally superposes structure test onto structure test2, using the backbone CA, C, and N atoms,
	and returns the rmsd of the best superposition.
	rmsd=test->superpose(test2) 

	NOTE: function fails if test2 has fewer residues than test1

=cut

sub superpose {
	my ($self, $other) = @_;
	my $last = $self->num_res;
	my @sc = (
        $self->get_coords('ca',0,$last-1),
        $self->get_coords('c',0,$last-1),
        $self->get_coords('n',0,$last-1)
    );
	my @oc = (
        $other->get_coords('ca',0,$last-1),
        $other->get_coords('c',0,$last-1),
        $other->get_coords('n',0,$last-1)
    );
	my  @extra = (
        $self->get_coords('cb',0,$last-1),
        $self->get_coords('o',0,$last-1)
    );
	my $rms = SmotifCS::GeometricalCalculations::superpose(3*$last,\@oc,\@sc,\@extra);
	for (my $aa = 0;$aa < $last; $aa++ ) {
		$self->change_pt('ca',$aa,@{$sc[$aa]});
		$self->change_pt('c',$aa,@{$sc[$aa+$last]});
		$self->change_pt('n',$aa,@{$sc[$aa+$last*2]});
		$self->change_pt('cb',$aa,@{$extra[$aa]});
		$self->change_pt('o',$aa,@{$extra[$aa+$last]});
	}
	return $rms;
}

=head2 superpose_anchors

	Optimally superposes the anchor points (c-alpha coordinates for the start and end residues of
	all secondary structures) of test2 onto the anchor points of test, where the order of points 
	in test structure are given by the array @order. 
	
	An example of @order would be (0 1 2 3 5 4), where the third secondary structure is oriented 
	in the reverse direction in test as opposed to test2.

	rms=test->superpose_anchors(test2)

=cut

sub superpose_anchors {
	my ($self,$other,@order) = @_;
	#get coordinates of anchor points
	my @p1;
	my @p2;
	for (my $aa = 0; $aa < $self->num_motifs; $aa++) {
		my @lm = $self->one_landmark($aa);
		push( @p1, $self->get_coords('ca',$lm[0],$lm[0]),$self->get_coords('ca',$lm[1]-1,$lm[1]-1));
	}
	for (my $aa=0;$aa<$other->num_motifs;$aa++) {
		my @lm=$other->one_landmark($aa);
		push(@p2,$other->get_coords('ca',$lm[0],$lm[0]),$other->get_coords('ca',$lm[1]-1,$lm[1]-1));
	}
	my @lm=$self->one_landmark(-1);
	push(@p1,$self->get_coords('ca',$lm[2],$lm[2]),$self->get_coords('ca',$lm[3]-1,$lm[3]-1));
	@lm=$other->one_landmark(-1);
	push(@p2,$other->get_coords('ca',$lm[2],$lm[2]),$other->get_coords('ca',$lm[3]-1,$lm[3]-1));

	#rearrange the anchor points of $self, according to the array @order
	my @pnew;
	foreach (@order) {push(@pnew,$p1[$_])};
	
    my $last  = $other->num_res;
	my @extra = (
        $other->get_coords('ca',0,$last-1),
        $other->get_coords('c',0,$last-1),
        $other->get_coords('n',0,$last-1),
        $other->get_coords('cb',0,$last-1),
        $other->get_coords('o',0,$last-1)
    );
	
    # superpose the two sets of anchor points
	my $rms = SmotifCS::GeometricalCalculations::superpose(scalar(@p2),\@pnew,\@p2,\@extra);	
	#assign the new coordinates to $other
	for (my $aa=0;$aa<$last;$aa++) {
		$other->change_pt('ca',$aa,@{$extra[$aa]});
		$other->change_pt('c',$aa,@{$extra[$aa+$last]});
		$other->change_pt('n',$aa,@{$extra[$aa+$last*2]});
		$other->change_pt('cb',$aa,@{$extra[$aa+$last*3]});
		$other->change_pt('o',$aa,@{$extra[$aa+$last*4]});
	}
	return $rms;
}

=head2 decompose_landmarks

	Decomposes the structure into sets of residue numbers representing the start and end of each
	secondary structure (indexed from 0 to num_motifs*2-1), and then generates all possible 
	(original and re-wired) smotif start and end points.

	test->decompose_landmarks(outfilename)

	The output file, written to outfilename, contains lines with the following information:
	start anchor value of first ss, end anchor value of first ss, start anchor value of second ss, 
	end anchor value of second ss, smotif type, ss1 length, ss2 length. 

=cut

sub decompose_landmarks {
	my ($self,$outfile) = @_;
	my @pt1;
	my @vec1;
	my @type;
	my @lens;
	#for each ss, find point 1, point 2, @vec1, @vec2
	for (my $aa=0;$aa<$self->num_motifs;$aa++) {
		my @lm=$self->one_landmark($aa);
		my $type=${$self->{type}}[$aa];
		push(@pt1,$lm[0],$lm[1]-1);
		push(@type,substr($type,0,1),substr($type,0,1));
		push(@lens,$lm[1]-$lm[0],$lm[1]-$lm[0]);
	}
	my @lm=$self->one_landmark(-1);
	my $type=${$self->{type}}[-1];
	push(@pt1,$lm[2],$lm[3]-1);
	push(@type,substr($type,1,1),substr($type,1,1));
	push(@lens,$lm[3]-$lm[2],$lm[3]-$lm[2]);
	foreach (@type) {if ($_ ne 'H') {$_='E'}};
	open(OUTFILE,">$outfile");
	#explore every possible motif
	for (my $aa=0;$aa<scalar(@pt1);$aa++) {
		my $vala=$aa;
		if ($aa%2==0) {$vala=$aa+1} else {$vala=$aa-1}
		LOOP1:	for (my $bb=0;$bb<scalar(@pt1);$bb++) {
			if (($bb==$aa) or (($bb%2==0) and ($bb==$aa-1)) or (($bb%2==1) and ($bb==$aa+1))) {next LOOP1}
			my $valb=$bb;
			if ($bb%2==0) {$valb=$bb+1} else {$valb=$bb-1};
				my @newpt2=$pt1[$vala];
				my @newpt3=$pt1[$bb];
				my @newpt1=$pt1[$aa];
				my @newpt4=$pt1[$valb];
				print OUTFILE "$aa\t$bb\t@newpt1\t@newpt2\t@newpt3\t@newpt4\t$type[$vala]$type[$bb]\t$lens[$vala]\t$lens[$bb]\n";
				
		}
	}
	close(OUTFILE);
}			

=head2 lazaridis_memb

	Calculate the membrane-based Lazaridis implicit solvation potential
	test->lazaridis_memb()

=cut

sub lazaridis_memb {
	my ($self)=@_;
	#index order: AG|C|DEKNPQRST|FILMVWY|H|AlphaC|Nitrogen|Carbonyl|Oxygen
	my $num=$self->num_res;
	my @g=(1..5*$num);
	my @lam=(1..5*$num);
	my @v=(1..5*$num);
	my @r=(1..5*$num);
	my %beta;
	$beta{'A'}=[0.13,3.5,90.1];
	$beta{'C'}=[-2.52,3.5,103.5];
	$beta{'D'}=[-2.23,6,117.1];
	$beta{'E'}=[-3.43,6,140.8];
	$beta{'F'}=[-3.74,3.5,193.5];
	$beta{'G'}=[1.45,3.5,90.1];
	$beta{'H'}=[-5.61,6,159.3];
	$beta{'I'}=[-2.77,3.5,164.6];
	$beta{'K'}=[-3.97,6,170.0];
	$beta{'L'}=[-2.64,3.5,164.9];
	$beta{'M'}=[-3.83,3.5,167.7];
	$beta{'N'}=[-3.04,3.5,127.5];
	$beta{'P'}=[0,3.5,123.1];
	$beta{'Q'}=[-3.84,3.5,149.4];
	$beta{'R'}=[-5.00,6,192.8];
	$beta{'S'}=[-1.66,3.5,94.2];
	$beta{'T'}=[-2.31,3.5,126.0];
	$beta{'V'}=[-2.05,3.5,139.1];
	$beta{'W'}=[-8.21,3.5,231.7];
	$beta{'Y'}=[-5.97,3.5,197.1]; 
	#rescaled
	my $sc=0;
	for my $key (keys %beta) {
		$sc += ${$beta{$key}}[0];
	}
	$sc /= 20;
	#$sc=0;
	#for (my $aa=0;$aa<$self->num_res;$aa++) {
	#	$sc += $beta{$self->get_seq($aa,1)}[0];
	#}
	#$sc /= $self->num_res;
	for my $key (keys %beta) {$beta{$key}[0] -= $sc};
	for (my $aa=0;$aa<$num;$aa++) {
		#beta carbons/residues
		my $resid=$self->get_seq($aa,1);
		$g[$aa]=$beta{$resid}[0];
		$lam[$aa]=$beta{$resid}[1];
		$v[$aa]=$beta{$resid}[2];
		$r[$aa]=((0.75*$v[$aa]/3.1416)**(1/3));
		#alpha carbons
		$g[$aa+$num]=-0.645-$sc;
		$lam[$aa+$num]=3.5;
		$v[$aa+$num]=23.7;
		$r[$aa+$num]=2;
		#nitrogen
		$g[$aa+2*$num]=-1.145-$sc;
		$lam[$aa+2*$num]=3.5;
		$v[$aa+2*$num]=4.4;
		$r[$aa+2*$num]=1.75;
		#carbonyl
		$g[$aa+3*$num]=-1.35-$sc;
		$lam[$aa+3*$num]=3.5;
		$v[$aa+3*$num]=14.7;
		$r[$aa+3*$num]=2;
		#oxygen
		$g[$aa+4*$num]=-1.27-$sc;
		$lam[$aa+4*$num]=3.5;
		$v[$aa+4*$num]=10.8;
		$r[$aa+4*$num]=1.55;
	}
	
    my @coords = (
        $self->get_coords('cb',0,$num-1),
        $self->get_coords('ca',0,$num-1),
        $self->get_coords('n',0,$num-1),
        $self->get_coords('c',0,$num-1),
        $self->get_coords('o',0,$num-1)
    );
	my $gtot = 0;
	my $fac  = 0.5/(3.1416**(1.5));
	for (my $aa = 0; $aa < $num-1; $aa++ ) {
		for (my $bb = $aa+1; $bb < $num; $bb++ ) {
			 my $r2 = SmotifCS::GeometricalCalculations::norm2(
                        SmotifCS::GeometricalCalculations::vecadd(
                            -1,
                            @{$coords[$aa]},
                            @{$coords[$bb]}
                        )
             );
			my $r1  = sqrt($r2);
			my $rij = ($r[$aa]+$r[$bb])**2;
			my $ta  = $g[$aa]*(exp(-((($r1-$r[$aa])/$lam[$aa])**2)))*$v[$bb]/$lam[$aa];
			my $tb  = $g[$bb]*(exp(-((($r1-$r[$bb])/$lam[$bb])**2)))*$v[$aa]/$lam[$bb];
			#my $temp = $fac*($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print "$aa\t$bb\t", -($ta+$tb)/$rij,"\t",$self->get_seq($aa,1),"\t",$self->get_seq($bb,1),"\t",$gtot,"\t";
			#}
			$gtot -= ($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print $gtot,"\n";
			#}

		}
	}
	#print "$gtot\n";
	return $gtot*$fac/($num);
}

=head2 lazaridis_hybrid

        Calculate the hybrid membrane/globular Lazaridis implicit solvation potential

=cut

sub lazaridis_hybrid {
	my ($self, @membtype) = @_;
	
    my $num = $self->num_res;
	my @g =  (1..5*$num);
	my @lam = (1..5*$num);
	my @v = (1..5*$num);
	my @r = (1..5*$num);
	my %betah;
	my %betam;
	$betah{'A'}=[2.178,3.5,90.1];
	$betah{'C'}=[-0.961,3.5,103.5];
	$betah{'D'}=[-18.911,6,117.1];
	$betah{'E'}=[-18.539,6,140.8];
	$betah{'F'}=[0.484,3.5,193.5];
	$betah{'G'}=[1.089,3.5,90.1];
	$betah{'H'}=[-9.457,6,159.3];
	$betah{'I'}=[2.922,3.5,164.6];
	$betah{'K'}=[-17.795,6,170.0];
	$betah{'L'}=[3.08,3.5,164.9];
	$betah{'M'}=[-0.69,3.5,167.7];
	$betah{'N'}=[-14.361,3.5,127.5];
	$betah{'P'}=[0,3.5,123.1];
	$betah{'Q'}=[-13.989,3.5,149.4];
	$betah{'R'}=[-5.007,6,192.8];
	$betah{'S'}=[-4.831,3.5,94.2];
	$betah{'T'}=[-4.099,3.5,126.0];
	$betah{'V'}=[2.55,3.5,139.1];
	$betah{'W'}=[-7.246,3.5,231.7];
	$betah{'Y'}=[-6.326,3.5,197.1]; 
	my $sc=0;
	for my $key (keys %betah) {
		$sc += ${$betah{$key}}[0];
	}
	$sc /= 20;
	for my $key (keys %betah) {$betah{$key}[0] -= $sc};
	$betam{'A'}=[0.13,3.5,90.1];
	$betam{'C'}=[-2.52,3.5,103.5];
	$betam{'D'}=[-2.23,6,117.1];
	$betam{'E'}=[-3.43,6,140.8];
	$betam{'F'}=[-3.74,3.5,193.5];
	$betam{'G'}=[1.45,3.5,90.1];
	$betam{'H'}=[-5.61,6,159.3];
	$betam{'I'}=[-2.77,3.5,164.6];
	$betam{'K'}=[-3.97,6,170.0];
	$betam{'L'}=[-2.64,3.5,164.9];
	$betam{'M'}=[-3.83,3.5,167.7];
	$betam{'N'}=[-3.04,3.5,127.5];
	$betam{'P'}=[0,3.5,123.1];
	$betam{'Q'}=[-3.84,3.5,149.4];
	$betam{'R'}=[-5.00,6,192.8];
	$betam{'S'}=[-1.66,3.5,94.2];
	$betam{'T'}=[-2.31,3.5,126.0];
	$betam{'V'}=[-2.05,3.5,139.1];
	$betam{'W'}=[-8.21,3.5,231.7];
	$betam{'Y'}=[-5.97,3.5,197.1]; 
	#rescaled
	my $sc2=0;
	for my $key (keys %betam) {
		$sc2 += ${$betam{$key}}[0];
	}
	$sc2 /= 20;
	for my $key (keys %betam) {$betam{$key}[0] -= $sc2};
	for (my $aa=0;$aa<$num;$aa++) {
		#beta carbons/residues
		my $resid=$self->get_seq($aa,1);
		if ($membtype[$aa]==0) {$g[$aa]=$betah{$resid}[0];} else {$g[$aa]=$betam{$resid}[0];}
		$lam[$aa]=$betah{$resid}[1];
		$v[$aa]=$betah{$resid}[2];
		$r[$aa]=((0.75*$v[$aa]/3.1416)**(1/3));
		#alpha carbons
		if ($membtype[$aa]==0) {$g[$aa+$num]=-0.187-$sc;} else {$g[$aa+$num]=-0.645-$sc2}
		$lam[$aa+$num]=3.5;
		$v[$aa+$num]=23.7;
		$r[$aa+$num]=2;
		#nitrogen
		if ($membtype[$aa]==0) {$g[$aa+2*$num]=-5.45-$sc;} else {$g[$aa+2*$num]=-1.145-$sc2}
		$lam[$aa+2*$num]=3.5;
		$v[$aa+2*$num]=4.4;
		$r[$aa+2*$num]=1.75;
		#carbonyl
		if ($membtype[$aa]==0) {$g[$aa+3*$num]=-0.89-$sc} else {$g[$aa+3*$num]=-1.35-$sc2};
		$lam[$aa+3*$num]=3.5;
		$v[$aa+3*$num]=14.7;
		$r[$aa+3*$num]=2;
		#oxygen
		if ($membtype[$aa]==0) {$g[$aa+4*$num]=-5.33-$sc} else {$g[$aa+4*$num]=-1.27-$sc2};
		$lam[$aa+4*$num]=3.5;
		$v[$aa+4*$num]=10.8;
		$r[$aa+4*$num]=1.55;
	}
	my @coords = (
        $self->get_coords('cb',0,$num-1),
        $self->get_coords('ca',0,$num-1),
        $self->get_coords('n',0,$num-1),
        $self->get_coords('c',0,$num-1),
        $self->get_coords('o',0,$num-1)
    );
	my $gtot = 0;
	my $fac=0.5/(3.1416**(1.5));
	for (my $aa=0;$aa<$num-1;$aa++) {
		for (my $bb = $aa+1; $bb < $num; $bb++ ) {
			my $r2 = SmotifCS::GeometricalCalculations::norm2(
                SmotifCS::GeometricalCalculations::vecadd(-1,@{$coords[$aa]},@{$coords[$bb]})
            );
			my $r1 = sqrt($r2);
			my $rij= ($r[$aa]+$r[$bb])**2;
			my $ta = $g[$aa]*(exp(-((($r1-$r[$aa])/$lam[$aa])**2)))*$v[$bb]/$lam[$aa];
			my $tb = $g[$bb]*(exp(-((($r1-$r[$bb])/$lam[$bb])**2)))*$v[$aa]/$lam[$bb];
			#my $temp = $fac*($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print "$aa\t$bb\t", -($ta+$tb)/$rij,"\t",$self->get_seq($aa,1),"\t",$self->get_seq($bb,1),"\t",$gtot,"\t";
			#}
			$gtot -= ($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print $gtot,"\n";
			#}

		}
	}
	#print "$gtot\n";
	return $gtot*$fac/($num);
}

=head2 lazaridis

	This routine is OBSOLETE
        Calculate the Lazaridis implicit solvation potential
        test->lazaridis()

=cut

sub lazaridis {
	my ($self)=@_;
	#index order: AG|C|DEKNPQRST|FILMVWY|H|AlphaC|Nitrogen|Carbonyl|Oxygen
	my $num=$self->num_res;
	my @g=(1..5*$num);
	my @lam=(1..5*$num);
	my @v=(1..5*$num);
	my @r=(1..5*$num);
	my %beta;
	$beta{'A'}=[3.72,3.5,90.1];
	$beta{'C'}=[-8.65,3.5,103.5];
	$beta{'D'}=[-30.96,6,117.1];
	$beta{'E'}=[-30.21,6,140.8];
	$beta{'F'}=[-6.83,3.5,193.5];
	$beta{'G'}=[3.72,3.5,90.1];
	$beta{'H'}=[-47.58,6,159.3];
	$beta{'I'}=[6.57,3.5,164.6];
	$beta{'K'}=[-21.39,6,170.0];
	$beta{'L'}=[6.57,3.5,164.9];
	$beta{'M'}=[-9.19,3.5,167.7];
	$beta{'N'}=[-46.02,3.5,127.5];
	$beta{'P'}=[2.25,3.5,123.1];
	$beta{'Q'}=[-45.27,3.5,149.4];
	$beta{'R'}=[-68.80,6,192.8];
	$beta{'S'}=[-24.87,3.5,94.2];
	$beta{'T'}=[-23.52,3.5,126.0];
	$beta{'V'}=[5.82,3.5,139.1];
	$beta{'W'}=[-41.73,3.5,231.7];
	$beta{'Y'}=[-36.43,3.5,197.1]; 
	#rescaled
	my $sc = -48.87;
	#$sc=0;
	#for (my $aa=0;$aa<$self->num_res;$aa++) {
	#	$sc += $beta{$self->get_seq($aa,1)}[0];
	#}
	#$sc /= $self->num_res;
	for my $key (keys %beta) {$beta{$key}[0] -= $sc};
	for (my $aa=0;$aa<$num;$aa++) {
		#beta carbons/residues
		my $resid=$self->get_seq($aa,1);
		$g[$aa]=$beta{$resid}[0];
		$lam[$aa]=$beta{$resid}[1];
		$v[$aa]=$beta{$resid}[2];
		$r[$aa]=((0.75*$v[$aa]/3.1416)**(1/3));
		#alpha carbons
		$g[$aa+$num]=4.18;
		$lam[$aa+$num]=3.5;
		$v[$aa+$num]=23.7;
		$r[$aa+$num]=2;
		#nitrogen
		$g[$aa+2*$num]=-5.0;
		$lam[$aa+2*$num]=3.5;
		$v[$aa+2*$num]=4.4;
		$r[$aa+2*$num]=1.75;
		#carbonyl
		$g[$aa+3*$num]=4.18;
		$lam[$aa+3*$num]=3.5;
		$v[$aa+3*$num]=14.7;
		$r[$aa+3*$num]=2;
		#oxygen
		$g[$aa+4*$num]=-5.0;
		$lam[$aa+4*$num]=3.5;
		$v[$aa+4*$num]=10.8;
		$r[$aa+4*$num]=1.55;
	}
	
    my @coords = (
        $self->get_coords('cb',0,$num-1),
        $self->get_coords('ca',0,$num-1),
        $self->get_coords('n',0,$num-1),
        $self->get_coords('c',0,$num-1),
        $self->get_coords('o',0,$num-1)
    );
	
    my $gtot = 0;
	my $fac = 0.5/(3.1416**(1.5));
	for (my $aa = 0;$aa < $num-1; $aa++ ) {
		for (my $bb=$aa+1;$bb<$num;$bb++) {
			my $r2 = SmotifCS::GeometricalCalculations::norm2(
                SmotifCS::GeometricalCalculations::vecadd(-1,@{$coords[$aa]},@{$coords[$bb]})
            );
			my $r1=sqrt($r2);
			my $rij=($r[$aa]+$r[$bb])**2;
			my $ta=$g[$aa]*(exp(-((($r1-$r[$aa])/$lam[$aa])**2)))*$v[$bb]/$lam[$aa];
			my $tb=$g[$bb]*(exp(-((($r1-$r[$bb])/$lam[$bb])**2)))*$v[$aa]/$lam[$bb];
			#my $temp = $fac*($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print "$aa\t$bb\t", -($ta+$tb)/$rij,"\t",$self->get_seq($aa,1),"\t",$self->get_seq($bb,1),"\t",$gtot,"\t";
			#}
			$gtot -= ($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print $gtot,"\n";
			#}

		}
	}
	#print "$gtot\n";
	return $gtot*$fac/($num);
}

=head2 lazaridis_new

        Calculate the globular Lazaridis implicit solvation potential
        test->lazaridis_new()

=cut

sub lazaridis_new {
	my ($self)=@_;
	#index order: AG|C|DEKNPQRST|FILMVWY|H|AlphaC|Nitrogen|Carbonyl|Oxygen
	my $num=$self->num_res;
	my @g=(1..5*$num);
	my @lam=(1..5*$num);
	my @v=(1..5*$num);
	my @r=(1..5*$num);
	my %beta;
=for
	$beta{'A'}=[3.72,3.5,90.1];
	$beta{'C'}=[-8.65,3.5,103.5];
	$beta{'D'}=[-30.96,6,117.1];
	$beta{'E'}=[-30.21,6,140.8];
	$beta{'F'}=[-6.83,3.5,193.5];
	$beta{'G'}=[3.72,3.5,90.1];
	$beta{'H'}=[-47.58,6,159.3];
	$beta{'I'}=[6.57,3.5,164.6];
	$beta{'K'}=[-21.39,6,170.0];
	$beta{'L'}=[6.57,3.5,164.9];
	$beta{'M'}=[-9.19,3.5,167.7];
	$beta{'N'}=[-46.02,3.5,127.5];
	$beta{'P'}=[2.25,3.5,123.1];
	$beta{'Q'}=[-45.27,3.5,149.4];
	$beta{'R'}=[-68.80,6,192.8];
	$beta{'S'}=[-24.87,3.5,94.2];
	$beta{'T'}=[-23.52,3.5,126.0];
	$beta{'V'}=[5.82,3.5,139.1];
	$beta{'W'}=[-41.73,3.5,231.7];
	$beta{'Y'}=[-36.43,3.5,197.1]; 
	#rescaled
	my $sc = -48.87;
=cut
	$beta{'A'}=[2.178,3.5,90.1];
	$beta{'C'}=[-0.961,3.5,103.5];
	$beta{'D'}=[-18.911,6,117.1];
	$beta{'E'}=[-18.539,6,140.8];
	$beta{'F'}=[0.484,3.5,193.5];
	$beta{'G'}=[1.089,3.5,90.1];
	$beta{'H'}=[-9.457,6,159.3];
	$beta{'I'}=[2.922,3.5,164.6];
	$beta{'K'}=[-17.795,6,170.0];
	$beta{'L'}=[3.08,3.5,164.9];
	$beta{'M'}=[-0.69,3.5,167.7];
	$beta{'N'}=[-14.361,3.5,127.5];
	$beta{'P'}=[0,3.5,123.1];
	$beta{'Q'}=[-13.989,3.5,149.4];
	$beta{'R'}=[-5.007,6,192.8];
	$beta{'S'}=[-4.831,3.5,94.2];
	$beta{'T'}=[-4.099,3.5,126.0];
	$beta{'V'}=[2.55,3.5,139.1];
	$beta{'W'}=[-7.246,3.5,231.7];
	$beta{'Y'}=[-6.326,3.5,197.1]; 
	my $sc=0;
	for my $key (keys %beta) {
		$sc += ${$beta{$key}}[0];
	}
	$sc /= 20;
	#$sc=0;
	#for (my $aa=0;$aa<$self->num_res;$aa++) {
	#	$sc += $beta{$self->get_seq($aa,1)}[0];
	#}
	#$sc /= $self->num_res;
	for my $key (keys %beta) {$beta{$key}[0] -= $sc};
	for (my $aa=0;$aa<$num;$aa++) {
		#beta carbons/residues
		my $resid=$self->get_seq($aa,1);
		$g[$aa]=$beta{$resid}[0];
		$lam[$aa]=$beta{$resid}[1];
		$v[$aa]=$beta{$resid}[2];
		$r[$aa]=((0.75*$v[$aa]/3.1416)**(1/3));
		#alpha carbons
		$g[$aa+$num]=-0.187-$sc;
		$lam[$aa+$num]=3.5;
		$v[$aa+$num]=23.7;
		$r[$aa+$num]=2;
		#nitrogen
		$g[$aa+2*$num]=-5.450-$sc;
		$lam[$aa+2*$num]=3.5;
		$v[$aa+2*$num]=4.4;
		$r[$aa+2*$num]=1.75;
		#carbonyl
		$g[$aa+3*$num]=-0.89-$sc;
		$lam[$aa+3*$num]=3.5;
		$v[$aa+3*$num]=14.7;
		$r[$aa+3*$num]=2;
		#oxygen
		$g[$aa+4*$num]=-5.33-$sc;
		$lam[$aa+4*$num]=3.5;
		$v[$aa+4*$num]=10.8;
		$r[$aa+4*$num]=1.55;
	}
	
    my @coords = (
        $self->get_coords('cb',0,$num-1),
        $self->get_coords('ca',0,$num-1),
        $self->get_coords('n',0,$num-1),
        $self->get_coords('c',0,$num-1),
        $self->get_coords('o',0,$num-1)
    );
	my $gtot=0;
	my $fac=0.5/(3.1416**(1.5));
	for (my $aa=0;$aa<$num-1;$aa++) {
		for (my $bb = $aa+1;$bb < $num; $bb++ ) {
			my $r2 = SmotifCS::GeometricalCalculations::norm2(
                SmotifCS::GeometricalCalculations::vecadd(-1,@{$coords[$aa]},@{$coords[$bb]})
            );
			my $r1 =sqrt($r2);
			my $rij=($r[$aa]+$r[$bb])**2;
			my $ta=$g[$aa]*(exp(-((($r1-$r[$aa])/$lam[$aa])**2)))*$v[$bb]/$lam[$aa];
			my $tb=$g[$bb]*(exp(-((($r1-$r[$bb])/$lam[$bb])**2)))*$v[$aa]/$lam[$bb];
			#my $temp = $fac*($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print "$aa\t$bb\t", -($ta+$tb)/$rij,"\t",$self->get_seq($aa,1),"\t",$self->get_seq($bb,1),"\t",$gtot,"\t";
			#}
			$gtot -= ($ta+$tb)/($rij);
			#if (($aa<$num) and ($bb<$num)) {
			#	print $gtot,"\n";
			#}

		}
	}
	#print "$gtot\n";
	return $gtot*$fac/($num);
}

=head2 add_amide_hydrogens

	Generate amide hydrogens along the backbone, to be used to determine long-range hydrogen bonds
	Ideal amide hydrogen bond lies along the bisector of the C->N and N->Ca bonds
	test->add_amide_hydrogens()

=cut

sub add_amide_hydrogens {
	my ($self)=@_;
	my $NHbondlength=1;
	#skip first N-H bond
	push(@{$self->{h}},[0,0,0]);
	#start with N2
	for (my $aa = 1;$aa < $self->num_res; $aa++ ) {
		my @n = @{$self->get_coords('n',$aa,$aa)};
		my @c = @{$self->get_coords('c',$aa-1,$aa-1)};
		my @ca= @{$self->get_coords('ca',$aa,$aa)};
		my @c_to_n  = SmotifCS::GeometricalCalculations::unit( 
            SmotifCS::GeometricalCalculations::vecadd(-1,@n,@c) 
        );
		my @ca_to_n = SmotifCS::GeometricalCalculations::unit( 
            SmotifCS::GeometricalCalculations::vecadd(-1,@n,@ca) 
        );
		my @bisect  = SmotifCS::GeometricalCalculations::unit( 
            SmotifCS::GeometricalCalculations::vecadd(1,@c_to_n,@ca_to_n) 
        );
		my @hcoord  = SmotifCS::GeometricalCalculations::vecadd($NHbondlength,@n,@bisect);
		push(@{$self->{h}},[@hcoord]);
	}
}

=head2 calc_long_range_h_bonds

	Calculate the long-range knowledge-based H-bond potential based on Kortemme, Mezerov, and Baker paper	
	test->calc_long_range_h_bonds()
=cut

sub calc_long_range_h_bonds {
	my ($self)=@_;
	#identify potential hydrogen-oxygen pairs by distance
	my @pairs;
	my $dlimit=2.6;
	my $thetalimit=100;
	my $score=0;
	$self->hbond_scores() unless (scalar(keys %{$self->{hb_d}})>0);
	for (my $mc = 0; $mc < $self->num_motifs(); $mc++ ) {
		my @lm = $self->one_landmark($mc);
		for (my $res1 = $lm[0]; $res1 < $lm[1]; $res1++) {
			for (my $res2 = $lm[1]; $res2<$self->num_res; $res2++) {
				my ($d,$theta,$psi) = $self->calc_d_theta_psi($res2,$res1);
				if ($d ne -1) {
					my $dbin = SmotifCS::GeometricalCalculations::angbin($d,0.05);
					my $tbin = SmotifCS::GeometricalCalculations::angbin($theta,5);
					my $pbin = SmotifCS::GeometricalCalculations::angbin($psi,5);
					$score += $self->{hb_d}->{$dbin};
					$score += $self->{hb_t}->{$tbin};
					$score += $self->{hb_p}->{$pbin};
					#print "$res2\t$res1\t$d\t$theta\t$psi\t$self->{hb_d}->{$dbin}\t$self->{hb_t}->{$tbin}\t$self->{hb_p}->{$pbin}\t$score\n";
				}
				if ($res1>0) {
					($d,$theta,$psi) = $self->calc_d_theta_psi($res1,$res2);
					if ($d ne -1) {
						my $dbin = SmotifCS::GeometricalCalculations::angbin($d,0.05);
						my $tbin = SmotifCS::GeometricalCalculations::angbin($theta,5);
						my $pbin = SmotifCS::GeometricalCalculations::angbin($psi,5);
						$score += $self->{hb_d}->{$dbin};
						$score += $self->{hb_t}->{$tbin};
						$score += $self->{hb_p}->{$pbin};
						#print "$res1\t$res2\t$d\t$theta\t$psi\t$self->{hb_d}->{$dbin}\t$self->{hb_t}->{$tbin}\t$self->{hb_p}->{$pbin}\t$score\n";
					}
				}
			}
		}
	}
	return $score/$self->num_res();
}

=head2 calc_d_theta_psi

	Calculate the distance and angle parameters for H-bond potential calculation
        test->calc_d_theta_psi()

=cut

sub calc_d_theta_psi {
	my ($self,$hcount,$ocount)=@_;
	
    my $pi = Math::Trig::pi;
	my @h = @{$self->get_coords('h',$hcount,$hcount)};
	my @o = @{$self->get_coords('o',$ocount,$ocount)};
	
    my @h_to_o = SmotifCS::GeometricalCalculations::vecadd(-1,@o,@h);
	my $d      = SmotifCS::GeometricalCalculations::norm(@h_to_o);	#distance between h and o atoms
	@h_to_o    = SmotifCS::GeometricalCalculations::unit(@h_to_o);
	
    if (($d > 2.6) or ($d < 1.7)) {return (-1,-1,-1)};
	
    my @n = @{$self->get_coords('n',$hcount,$hcount)};
	
    my @h_to_n = SmotifCS::GeometricalCalculations::unit(
        SmotifCS::GeometricalCalculations::vecadd(-1,@n,@h)
    );
	
    my $theta = Math::Trig::acos( SmotifCS::GeometricalCalculations::dot(@h_to_n,@h_to_o) )*180/$pi;	#angle between n-h---o
	if ($theta<105) {return (-1,-1,-1)};

	my @c = @{ $self->get_coords('c',$ocount,$ocount) };
	
    my @c_to_o = SmotifCS::GeometricalCalculations::unit(SmotifCS::GeometricalCalculations::vecadd(-1,@o,@c));
	my $psi    = Math::Trig::acos( SmotifCS::GeometricalCalculations::dot(@h_to_o,@c_to_o) )*180/$pi;	#angle between c=o---h
	if ($psi<85) {return (-1,-1,-1)};
	
	return ($d,$theta,$psi);
}

=head2 hbond_scores

	Set up the knowledge-based H-bond potential values
        test->hbond_scores()

=cut

sub hbond_scores {
	my ($self)=@_;
	my $dlow=1.75;
	my $dbin=0.05;
	my @ds=(50,250,300,625,825,900,1050,750,500,500,410,390,240,190,200,190,210,150);
	my $total=0;
	my %temp;
	foreach (@ds) {$total += $_};
	$total /= scalar(@ds);
	for (my $aa=0;$aa<scalar(@ds);$aa++) {
		$temp{$dlow+$aa*$dbin} = SmotifCS::GeometricalCalculations::min(-log($ds[$aa]/$total),0);
	}
	%{$self->{hb_d}}=%temp;
	my $tlow=110;
	my $tbin=5;
	my @ts=(300,600,1000,1300,1800,2000,3000,4000,6000,9600,15500,19000,17500,14500,14500);
	$total=0;
	foreach (@ts) {$total += $_};
	
    $total /= scalar(@ts);
	my %temp2;
	for (my $aa = 0;$aa < scalar(@ts); $aa++) {
		$temp2{$tlow+$aa*$tbin} = SmotifCS::GeometricalCalculations::min(-log($ts[$aa]/$total),0);
	}
	%{$self->{hb_t}}=%temp2;
	my $plow = 90;
	my $pbin = 5;
	my @ps = (200,600,1100,1800,2400,2700,2600,2500,2300,2400,3600,4900,6400,7500,6800,5300,3900,3000,3000);
	$total = 0;
	foreach (@ps) {$total += $_};
	
    $total /= scalar(@ps);
	my %temp3;
	for (my $aa=0;$aa<scalar(@ps);$aa++) {
		$temp3{$plow+$aa*$pbin} = SmotifCS::GeometricalCalculations::min(-log($ps[$aa]/$total),0);
	}
	%{ $self->{hb_p} } = %temp3;
}

=head2 stat_table

	Load Rykunov's statistical potential values
        test->stat_table()

=cut

sub stat_table {
	my ($self) = @_;
	%{ $self->{statpot} } = SmotifCS::StatisticalPotential::potential_hash();
	#hash contains parallel/antiparallel, distance(A), aa1, aa2
}

=head2 torsion

	Calculate phi/psi/omega angles for every residue within a range
        $tor=torsion($test,$start,$end);

	Inputs: 
	Start and end residues of protein in "test" for torsion calculation

=cut

sub torsion {
    my ($self,$start,$end) = @_;
    
    my @angs;
    for (my $aa=$start;$aa<$end;$aa++) {
        my @c0;
        my @n1;
        my @ca1;
        my @c1;
        my @n2;
        my @ca2;
        my $phi1  = -9999;
        my $psi1  = -9999;
        my $omega1= -9999;
        
        @n1  = @{ $self->get_coords('n',$aa,$aa) };
        @ca1 = @{ $self->get_coords('ca',$aa,$aa)};
        @c1  = @{ $self->get_coords('c',$aa,$aa) };
        if ($aa>0) {	#can calculate phi
            @c0  = @{ $self->get_coords('c',$aa-1,$aa-1) };	
            $phi1= SmotifCS::GeometricalCalculations::dihedral(\@c0,\@n1,\@ca1,\@c1);
        }
        if ($aa<$self->num_res()-1) { #can calculate psi and omega
            @n2    = @{ $self->get_coords('n',$aa+1,$aa+1) };
            @ca2   = @{ $self->get_coords('ca',$aa+1,$aa+1) };
            $psi1  = SmotifCS::GeometricalCalculations::dihedral(\@n1,\@ca1,\@c1,\@n2);
            $omega1= SmotifCS::GeometricalCalculations::dihedral(\@ca1,\@c1,\@n2,\@ca2);
        }
        push(@angs, [($phi1,$psi1,$omega1)]);
    }
    return @angs;
}

=head2 change_torsion

	Change the phi or psi angle of a single residue

	Inputs:
	Residue number, phi or psi - which angle to rotate, and the amount of rotation to be carried out. 

=cut

sub change_torsion {
	my ($self,$resnum,$phipsi,$amount)=@_;
	#get the vector around which to rotate: if phi angle, vector between N and Calpha, if psi, vector between Calpha and C
	my @axisvec;
	my @basept;
	if ($phipsi==1) {	#phi vector
		my @pt1=@{$self->get_coords('n',$resnum,$resnum)};
		my @pt2=@{$self->get_coords('ca',$resnum,$resnum)};
		@axisvec=GeometricalCalculations::unit(GeometricalCalculations::vecadd(-1,@pt2,@pt1));		
		@basept=@pt2;
	} else {		#psi vector
		my @pt1=@{$self->get_coords('ca',$resnum,$resnum)};
		my @pt2=@{$self->get_coords('c',$resnum,$resnum)};
		@axisvec=GeometricalCalculations::unit(GeometricalCalculations::vecadd(-1,@pt2,@pt1));
		@basept=@pt2;
	}
	
    # rotate all subsequent points around the axis by the specified angle
	if ($phipsi==1) {
		my @point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('c',$resnum,$resnum)},@basept);
		my @tmp   = @{$self->get_coords('c',$resnum,$resnum)};
		$self->change_pt(
            'c',
            $resnum,
            SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                @basept
            )
        );
		@tmp  = @{ $self->get_coords('c',$resnum,$resnum) };
		@point= SmotifCS::GeometricalCalculations::vecadd(
                -1,
                @{$self->get_coords('o',$resnum,$resnum)},
                @basept
        );	
		
        $self->change_pt(
                'o',
                $resnum,
                SmotifCS::GeometricalCalculations::vecadd(
                    1,
                    SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                    @basept
                )
        );
	}
	
    my $hydrogens_exist = 0;
	if (scalar(@{$self->{h}})>0) {$hydrogens_exist=1}
	
    for (my $aa = $resnum+1; $aa < $self->num_res(); $aa++) {
		
        my @point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('n',$aa,$aa)},@basept);
		$self->change_pt(
                'n',
                $aa,
                SmotifCS::GeometricalCalculations::vecadd(
                        1,
                        SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),@basept)
                );
		
        @point = SmotifCS::GeometricalCalculations::vecadd(
                -1,
                @{$self->get_coords('ca',$aa,$aa)},
                @basept
        );
		
        $self->change_pt(
                'ca',
                $aa,
                SmotifCS::GeometricalCalculations::vecadd(
                        1,
                        SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                        @basept
                 )
        );
		@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('cb',$aa,$aa)},@basept);
		
        $self->change_pt(
                'cb',
                $aa,
                SmotifCS::GeometricalCalculations::vecadd(
                        1,
                        SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                        @basept
                )
        );
		@point = GeometricalCalculations::vecadd(-1,@{$self->get_coords('c',$aa,$aa)},@basept);
		
        $self->change_pt(
                'c',
                $aa,
                SmotifCS::GeometricalCalculations::vecadd(
                        1,
                        SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                        @basept
                )
        );
		
        @point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('o',$aa,$aa)},@basept);
		$self->change_pt(
                'o',
                $aa,
                SmotifCS::GeometricalCalculations::vecadd(
                        1,
                        SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                        @basept
                )
         );
		 
         if ($hydrogens_exist==1) {
			@point = SmotifCS::GeometricalCalculations::vecadd(-1,@{$self->get_coords('h',$aa,$aa)},@basept);
			$self->change_pt(
                    'h',
                    $aa,
                    SmotifCS::GeometricalCalculations::vecadd(
                            1,
                            SmotifCS::GeometricalCalculations::rotateaxis(\@point,\@axisvec,\$amount),
                            @basept
                    )
            );
		}
	}				
}

=head2 coords_from_torsion

	Calculate coordinates, given a set of phi/psi angles
	
	Inputs:
	Array containing phi and psi angles

=cut

sub coords_from_torsion {
	my ($self,@angs)=@_;
	my @n;
	my @ca;
	my @c;
	my @cb;
	my @o;
	#bond lengths and angles
	my $pi=Math::Trig::pi;
	my $n_to_ca=1.46;
	my $n_ang=$pi-Math::Trig::deg2rad(121.9);
	my $ca_to_c=1.53;
	my $ca_ang=$pi-Math::Trig::deg2rad(109.5);
	my $c_to_n=1.33;
	my $c_ang=$pi-Math::Trig::deg2rad(115.6);
	my $c_to_o=1.23;
	my $o_ang=$pi-Math::Trig::deg2rad(122);
	#find first three points
	push(@n,[0,0,0]);
	push(@ca,[$n_to_ca,0,0]);
	push(@c,[$n_to_ca+$ca_to_c*cos($ca_ang),-$ca_to_c*sin($ca_ang),0]);
	push(@cb,[ SmotifCS::GeometricalCalculations::findcb($ca[-1],$c[-1],$n[-1]) ] );
	#add additional points
	for (my $aa = 0;$aa < scalar(@angs)-1; $aa++ ) {
		my $phi  = Math::Trig::deg2rad($angs[$aa+1][0]);
		my $psi  = Math::Trig::deg2rad($angs[$aa][1]);
		my $omega= Math::Trig::deg2rad(-177);
		if (exists($angs[$aa][2])) {$omega=Math::Trig::deg2rad($angs[$aa][2])};
		
        # add nitrogen atom first
		my @ab    = SmotifCS::GeometricalCalculations::vecadd(-1,@{$ca[-1]},@{$n[-1]});		#n-ca
		my @bc    = GeometricalCalculations::unit( SmotifCS::GeometricalCalculations::vecadd(-1,@{$c[-1]},@{$ca[-1]}) );	#ca-c
		my @temp  = GeometricalCalculations::cross(@ab,@bc);	
		my @normal= GeometricalCalculations::unit(@temp);
		my @n_x_bc= GeometricalCalculations::cross(@normal,@bc);
		my @d2    = (
                $c_to_n*cos($c_ang),
                $c_to_n*cos($psi)*sin($c_ang),
                $c_to_n*sin($psi)*sin($c_ang)
        );	#dummy point
		
        my @m_matrix = ( [$bc[0],$n_x_bc[0],$normal[0]],[$bc[1],$n_x_bc[1],$normal[1]],[$bc[2],$n_x_bc[2],$normal[2]] );
		my @d        = SmotifCS::GeometricalCalculations::vecadd(
                            1,
                            SmotifCS::GeometricalCalculations::matvec(\@m_matrix,\@d2,3,3),
                            @{$c[-1]}
                      );		#adjusted point
		
        push( @n,[@d] );
		push( @o,[ SmotifCS::GeometricalCalculations::findo($ca[-1],$c[-1],$n[-1]) ]);	
		
        # add c-alpha atom
		@ab    = SmotifCS::GeometricalCalculations::vecadd(-1,@{$c[-1]},@{$ca[-1]});		#ca-c
		@bc    = SmotifCS::GeometricalCalculations::unit(GeometricalCalculations::vecadd(-1,@{$n[-1]},@{$c[-1]}));	#c-n
		@temp  = SmotifCS::GeometricalCalculations::cross(@ab,@bc);	
		@normal= SmotifCS::GeometricalCalculations::unit(@temp);
		@n_x_bc= SmotifCS::GeometricalCalculations::cross(@normal,@bc);
		@d2    = (  $n_to_ca*cos($n_ang),
                    $n_to_ca*cos($omega)*sin($n_ang),
                    $n_to_ca*sin($omega)*sin($n_ang)
        );	#dummy point
		
        @m_matrix = ([$bc[0],$n_x_bc[0],$normal[0]],[$bc[1],$n_x_bc[1],$normal[1]],[$bc[2],$n_x_bc[2],$normal[2]]);
		@d = SmotifCS::GeometricalCalculations::vecadd(
                1,
                SmotifCS::GeometricalCalculations::matvec(\@m_matrix,\@d2,3,3),
                @{$n[-1]}
            );		#adjusted point
		push(@ca,[@d]);
		
        # add c atom
		@ab   = SmotifCS::GeometricalCalculations::vecadd(-1,@{$n[-1]},@{$c[-1]});		#c-n
		@bc   = SmotifCS::GeometricalCalculations::unit( SmotifCS::GeometricalCalculations::vecadd(-1,@{$ca[-1]},@{$n[-1]}) );	#n-ca
		@temp  = SmotifCS::GeometricalCalculations::cross(@ab,@bc);	
		@normal= SmotifCS::GeometricalCalculations::unit(@temp);
		@n_x_bc= SmotifCS::GeometricalCalculations::cross(@normal,@bc);
		
        @d2=($ca_to_c*cos($ca_ang),$ca_to_c*cos($phi)*sin($ca_ang),$ca_to_c*sin($phi)*sin($ca_ang));	#dummy point
		@m_matrix=([$bc[0],$n_x_bc[0],$normal[0]],[$bc[1],$n_x_bc[1],$normal[1]],[$bc[2],$n_x_bc[2],$normal[2]]);
		
        @d = SmotifCS::GeometricalCalculations::vecadd(
            1,
            SmotifCS::GeometricalCalculations::matvec(\@m_matrix,\@d2,3,3),
            @{$ca[-1]}
        );		#adjusted point
		push(@c,[@d]);
		#add cbeta atom
		push(@cb,[ SmotifCS::GeometricalCalculations::findcb($ca[-1],$c[-1],$n[-1]) ]);
	}
	for (my $aa=0;$aa<scalar(@n);$aa++) {
		$self->change_pt('n',$aa,@{$n[$aa]});
		$self->change_pt('ca',$aa,@{$ca[$aa]});
		$self->change_pt('c',$aa,@{$c[$aa]});
		$self->change_pt('cb',$aa,@{$cb[$aa]});
		if ($aa<scalar(@n)-1) {$self->change_pt('o',$aa,@{$o[$aa]});}
		$self->get_seq($aa,1,'A');
	}
	my @lm=(0,0,scalar(@n),scalar(@n));
	$self->one_landmark(0,@lm);
}


=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Protein


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


=head1 ACKNOWLEDGEMENTS


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
