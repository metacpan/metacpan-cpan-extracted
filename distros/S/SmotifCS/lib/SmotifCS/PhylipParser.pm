package SmotifCS::PhylipParser;

use 5.10.1 ;
use strict;
use warnings;
use Data::Dumper;
use Carp;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.05";

    #$AUTHOR  = "Eduardo Fajardo(eduardo\@fiserlab.org )";
    @ISA = qw(Exporter);

    #Name of the functions to export
    @EXPORT = qw(
	findClusters
    );

    #Name of the functions to export on request
    @EXPORT_OK = qw(
	readTree
	getFinalNodes
	findSubtree
	withinSphere
	getDistance
	getResNumber
    );
}

use constant DEBUG => 0;
our @EXPORT;
our @EXPORT_OK;

=head1 NAME

PhylipParser

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

This module parses phylip output to generate the clusters

    use PhylipParser;

    PhylipParser::findClusters($treeFile, $matrixFile, $threshold);

=head1 EXPORT

=head1 SUBROUTINES

findClusters
readTree
getFinalNodes
findSubtree
withinSphere
getDistance
getResNumber

=head2 findClusters

Takes a file with the output of kitsch or neighbor (a tree, this
is automatically called "outfile" by Phylip) and the distance 
file used as input to make the tree.  Outputs clusters of leaves 
that lie within the supplied threshold distance.
usage: findClusters <dendogram file, output of kitsch or neighbor>
		    >distance file, input to kitsch or neighbor> 
		    <threshold distance>

=cut

sub findClusters {

my ($treeFile, $matrixFile, $threshold) = @_;

croak "Tree file is required\n" unless $treeFile;
croak "Matrix file is required\n" unless $matrixFile;
croak "Threshold is required\n" unless $threshold;

my $output = "motifclusters";

my %treeOf = (); # Holds references to the cluster tree.
my $root = readTree($treeFile, \%treeOf);

my %codeOf = (); # Holds references to the matrix residues.
my $row = 0;
my @distance = ();
my $line = "";

open MATRX, $matrixFile or croak "Cannot open $matrixFile"; # file with distance matrix

#first line of the distance matrix (header line. not matrix yet)
$line = <MATRX>;
chomp $line;
$line =~ s/^\s*//; # get rid of any leading spaces
my ($number) = split(/\s+/, $line); # number of leaves in tree

#parse matrix
while($line = <MATRX>){
  chomp $line;
  my @vals = split(/\s+/,$line);
  my $name = $vals[0]; # Gets the name of the leaf
  $row++;
  
  if($#vals != $number){ 
    print "warning: number of columns in distance file row $row ($#vals) is not the same as number of leaves in tree ($number).  Check file!!\n";
	print STDERR "warning: number of columns in distance file row $row ($#vals) is not the same as number of leaves in tree ($number).  Check file!!\n";
  }

  $codeOf{$name} = $row; 
  for(my $column = 1; $column < @vals; $column++){
    if($row <= $column){ 
      $distance[$row][$column] = $vals[$column];
    }
    else{
      $distance[$column][$row] = $vals[$column];
    }
  }  
}

close MATRX;

#print Dumper (\%codeOf);

if($row != $number){
  print "warning: number of rows in distance file ($row) is not the same as the number of leaves in tree ($number).  Check file!!\n";
  print STDERR "warning: number of rows in distance file ($row) is not the same as the number of leaves in tree ($number).  Check file!!\n";
}

my @finalNodes = ();  # list of nodes where cluster subtrees are rooted
getFinalNodes($root, \@finalNodes, $threshold, \@distance, \%codeOf, %treeOf);
#print Dumper (\@finalNodes);

open OUT, ">$output" or croak "cannot open $output";

my $numOfClust = @finalNodes;
#print OUT "Number of Clusters at $threshold distance: $numOfClust\n";
#print "$threshold\t$numOfClust\n";

my $clusternum=0;
for(my $k = 0; $k < @finalNodes; $k++) { # Goes through every final node.
    my $node = $finalNodes[$k];
    my @leaves = ();
    findSubtree($node, \@leaves, %treeOf); # Gets this node's subtree.

	$clusternum++;
	my $clusID = 'Cluster'.$clusternum;
    print OUT "$clusID: ";
    for(my $l = 0; $l < @leaves; $l++) { # Goes through every residue in the list.
	my $residue = $leaves[$l]; 
	#my $residue = getResNumber($leaves[$l]); # Gets the residue number.
	print OUT "$residue "; # Prints each residue to the output file.
    }
    print OUT "\n";
}

close OUT;

}

=head2 readTree

Subroutine to read phylip tree output

=cut

sub readTree {
    my ($file, $treeRef) = @_;
    open IN, $file or croak "cannot open $file";

    my $minTime = 1000; # Sets an arbitrary minimum to compare with.
    my $root = "";
    my $line = "";
    my $prog = "N"; # assume that neighbor was used for clustering (could be kitsch)

	while($line = <IN>) { #skip the header info
	     chomp $line;
		 if($line =~ /^From\s+To/ and $prog eq "N"){
		      <IN>; #skip one line
			  last;
		 }elsif($line =~ /^From\s+To/ and $prog eq "K"){
		      <IN>; <IN>; #skip two lines
			  last;
		 }
	}

	while($line = <IN>) {
	     chomp $line;

		 $line = " " . $line; 
		 my @fields = split(/\s+/,$line); # [1]=parent, [2]=child, [4]=time(time only in kitsch)
		 unless ( scalar(@fields) ){ #ends if the expected line is not found (blank is end of file)
		      last;
		 }
		 
		 if(!$root){ # in neighbor, root is always in first line
			  $root = $fields[1];
			  $minTime = $fields[4];
		 } # end if no root has been assigned
		 
		 if($prog ne "N" && $fields[4] < $minTime) { # A new minimum time is found.
		      $root = $fields[1];
			  $minTime = $fields[4];
		 }
		 
		 if( !exists($treeRef->{$fields[1]}) ) { # Node does not already exist.
		      my @array = (); # Creates an array.
			  push(@array,$fields[2]); # Adds this child to the array.
			  $treeRef->{$fields[1]} = \@array; # Creates the node and adds a child.
		 }else { # Node exists, but this line has the second child.
		      my $ref = $treeRef->{$fields[1]}; # Creates a reference.
			  push(@$ref, $fields[2]); # Adds the second child.
		 }
    }
    close IN;

    return $root;
}

=head2 getFinalNodes

=cut

sub getFinalNodes {
    my ($node, $finalArrayRef, $threshold, $distance, $codeOf, %treeOf) = @_;
    my @nodeLeaves = ();
    findSubtree($node, \@nodeLeaves, %treeOf); # Gets the subtree rooted at that node.

    if(withinSphere(\@nodeLeaves, $threshold, $distance, $codeOf)) { # All this node's residues fall within a cluster.
#	print "tree rooted at $node is within sphere [@nodeLeaves]\n";
	push(@$finalArrayRef, $node); # Adds this node to the final list.
    }
    else { # Further clustering is needed.
#	print "tree rooted at $node is not within threshold distance\n";
	getFinalNodes($treeOf{$node}[0], $finalArrayRef, $threshold, $distance, $codeOf, %treeOf); # Goes left to find final nodes.
	getFinalNodes($treeOf{$node}[1], $finalArrayRef, $threshold, $distance, $codeOf, %treeOf); # Goes right to find final nodes.
    }
}

=head2 findSubtree

Subroutine to find the Subtree

=cut

sub findSubtree {
    my ($node, $arrayRef, %treeOf) = @_;
   
    if($treeOf{$node}) { # Tree exists, so node is not a leaf.
		 findSubtree($treeOf{$node}[0], $arrayRef, %treeOf); # Goes to the left.
		 findSubtree($treeOf{$node}[1], $arrayRef, %treeOf); # Goes to the right.
    }else { # This node is really a leaf.
	     push(@$arrayRef, $node);
    }
}

=head2 withinSphere
	
=cut

sub withinSphere {
	my ($subtreeRef, $threshold, $distance, $codeOf) = @_;
	#my $subtreeRef = $_[0];
	#my $threshold  = $_[1];
	my $answer = 1;
    my $length = @$subtreeRef;
    
	for(my $j = 0; $j < $length; $j++) { 
	for(my $k = $j + 1; $k < $length; $k++) { 
		# Goes through every possible combination of residues.
	    my $new_distance = getDistance($$codeOf{$subtreeRef->[$j]}, $$codeOf{$subtreeRef->[$k]}, $distance);
	    if($new_distance > $threshold) {
		$answer = 0; # Returns 0 if not all fall within the sphere.
		return $answer;
		#last;
	    }
	}
    }

    return $answer; # Returns 1 if all fall within sphere.
}    

=head2 getDistance 

=cut
	  
sub getDistance {
    my ($res1,$res2,$distance) = @_;
    my $result = 0;

    if($res1 <= $res2){
      $result = $$distance[$res1][$res2];
    }
    else{
      $result = $$distance[$res2][$res1];
    }

    return $result;
}

=head2 getResNumber

=cut

sub getResNumber {
    my $name = $_[0];

    my @fields1 = split(/_/,$name); # Splits the name by underscore.
    my $number = pop(@fields1); # Gets the last value of the array.

    return $number;
}
    

=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PhylipParser


You can also look for information at:

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

1; # End of PhylipParser
