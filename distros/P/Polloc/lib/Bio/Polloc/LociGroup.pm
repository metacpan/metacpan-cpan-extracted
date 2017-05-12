=head1 NAME

Bio::Polloc::LociGroup - A group of loci

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=back

=cut

package Bio::Polloc::LociGroup;
use strict;
use base qw(Bio::Polloc::Polloc::Root);
use Bio::Polloc::Polloc::IO;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 add_locus

Alias of C<add_loci()>

=cut

sub add_locus { return shift->add_loci(@_) }

=head2 add_loci

Adds loci to the collection on the specified
genome's space

B<Throws>

A L<Bio::Polloc::Polloc::Error> if an argument is not
a L<Bio::Polloc::LocusI> object.

B<Arguments>

The first argument B<can> be the identifier of
the genome's space (int).  All the following are
expected to be L<Bio::Polloc::LocusI> objects.

=cut

sub add_loci {
   my ($self,@l) = @_;
   my $space;
   if(defined $l[0] and not ref $l[0]){
      $space = 0 + shift @l;
   }
   $self->{'_loci'} = [] unless defined $self->{'_loci'};
   for my $locus (@l){
      $self->debug("Saving locus (".($#l+1)." loci, cur:".($#{$self->{'_loci'}}+1).")");
      $self->throw('Expecting a Bio::Polloc::LocusI object', $locus)
      	unless UNIVERSAL::can($locus, 'isa') and $locus->isa('Bio::Polloc::LocusI');
      $locus->genome($self->genomes->[$space]) if defined $space;
      push @{ $self->{'_loci'} }, $locus;
   }
}

=head2 loci

Gets the loci

=cut

sub loci {
   my $self = shift;
   $self->{'_loci'} = [] unless defined $self->{'_loci'};
   return $self->{'_loci'};
}

=head2 structured_loci

Returns a two-dimensional array where the first key corresponds
to the number of the genome space and the second key is an
incremental for each locus.

B<Note>

This function is provided for convenience in some output formating,
but its use should be avoided as it causes a huge processing time
penalty.

B<Warning>

Loci without defined genome will not be included in the output.

=cut

sub structured_loci {
   my $self = shift;
   return unless defined $self->genomes;
   my $struct = [];
   for my $locus (@{$self->loci}){
      next unless defined $locus->genome;
      my $space = 0;
      for my $genome (@{$self->genomes}){
	 $struct->[$space] = [] unless defined $struct->[$space];
	 if($genome->name eq $locus->genome->name){
	    push @{ $struct->[$space] }, $locus;
	 }
         $space++;
      }
   }
   return $struct;
}

=head2 locus

Get a locus by ID

B<Arguments>

The ID of the locus (str).

=cut

sub locus {
   my ($self, $id) = @_;
   for my $locus (@{$self->loci}){ return $locus if $locus->id eq $id }
   return;
}

=head2 name

Gets/sets the name of the group.  This is supposed
to be unique!

B<Note>

Future implementations could assume unique naming
for getting/setting/initializing groups of loci
by name.

=cut

sub name {
   my ($self, $value) = @_;
   $self->{'_name'} = $value if defined $value;
   return $self->{'_name'};
}

=head2 genomes

Gets/sets the genomes to be used as analysis base.

B<Arguments>

A reference to an array of L<Bio::Polloc::Genome> objects.

=cut

sub genomes {
   my($self, $value) = @_;
   $self->{'_genomes'} = $value if defined $value;
   return unless defined $self->{'_genomes'};
   $self->throw("Unexpected type of genomes collection", $self->{'_genomes'})
   	unless ref($self->{'_genomes'}) and ref($self->{'_genomes'})=~m/ARRAY/i;
   return $self->{'_genomes'};
}


=head2 featurename

Gets/Sets the name of the feature common to all the
loci in the group.

=cut

sub featurename {
   my ($self, $value) = @_;
   $self->{'_featurename'} = $value if defined $value;
   return $self->{'_featurename'};
}

=head2 avg_length

Gets the average length of the stored loci.

B<Returns>

The average length (float) or an array containing the
average length (float) and the standard deviation (float),
depending on the expected output.

B<Syntax>

    my $len = $locigroup->length;

Or,

    my($len, $sd) = $locigroup->length;

=cut

sub avg_length {
   my $self = shift;
   my $len_avg = 0;
   my $len_sd = 0;
   if($#{$self->loci} >= 1){
      # AVG
      $len_avg+= abs($_->from - $_->to) for @{$self->loci};
      $len_avg = $len_avg/($#{$self->loci}+1);
      return $len_avg unless wantarray;
      # SD
      $len_sd+= (abs($_->from - $_->to) - $len_avg)**2 for @{$self->loci};
      $len_sd = sqrt($len_sd/$#{$self->loci}); # n-1, not n (unbiased SD)
   }elsif($#{$self->loci}==0){
      $len_avg = abs($self->loci->[0]->from - $self->loci->[0]->to);
   }
   return wantarray ? ($len_avg, $len_sd) : $len_avg;
}

=head2 align_context

B<Arguments>

Arguments work in the same way L<Bio::Polloc::LocusI-E<gt>context_seq()>
arguments do.

=over

=item 1

Ref: Int, reference position.

=item 2

From: Int, the I<from> position.

=item 3

To: Int, the I<to> position.

=back

=cut

sub align_context {
   my ($self, $ref, $from, $to) = @_;
   $from+=0; $to+=0; $ref+=0;
   return if $from == $to and $ref!=0;
   
   my $factory = Bio::Tools::Run::Alignment::Muscle->new();
   $factory->quiet(1);
   my @seqs = ();
   LOCUS: for my $locus (@{$self->loci}){
      # Get the sequence
      my $seq = $locus->context_seq($ref, $from, $to);
      next LOCUS unless defined $seq;
      $seq->display_id($locus->id) if defined $locus->id;
      push @seqs, $seq;
   } #LOCUS
   return unless $#seqs>-1; # Impossible without sequences
   # small trick to build an alignment, even if there is only one sequence:
   push @seqs, Bio::Seq->new(-seq=>$seqs[0]->seq, -id=>'dup-seq') unless $#seqs>0;
   $self->debug("Aligning context sequences");
   return $factory->align(\@seqs);
}

=head2 fix_strands

Fixes the strand of the loci based on the flanking regions, to have all the
loci in the group with the same orientation.

B<Arguments>

=over

=item -size I<int>

Context size (500 by default)

=item -force I<bool (int)>

Force the detection, even if it was previously detected.

=back

=cut

sub fix_strands {
   my ($self, @args) = @_;
   my ($size, $force) = $self->_rearrange([qw(SIZE FORCE)], @args);
   return if not $force and defined $self->{'_fixed_strands'} and $self->{'_fixed_strands'} == $#{$self->loci};
   $self->{'_fixed_strands'} = $#{$self->loci};
   $self->_load_module('Bio::Polloc::GroupCriteria');
   $self->_load_module('Bio::Tools::Run::Alignment::Muscle');
   return unless $#{$self->loci}>0; # No need to check
   $size ||= 500;
   
   my $factory = Bio::Tools::Run::Alignment::Muscle->new();
   $factory->quiet(1);
   
   # Find a suitable reference
   my $ref = [undef, undef];
   LOCUS: for my $lk (1 .. $#{$self->loci}){
      my $ref_test = [
      		Bio::Polloc::GroupCriteria->_build_subseq(
				$self->loci->[$lk]->seq,
				$self->loci->[$lk]->from - $size,
				$self->loci->[$lk]->from),
      		Bio::Polloc::GroupCriteria->_build_subseq(
				$self->loci->[$lk]->seq,
				$self->loci->[$lk]->to,
				$self->loci->[$lk]->to + $size)
		];
      if(defined $ref->[0] and defined $ref->[1]){
         # Longer pair:
	 $ref = $ref_test
	 	if  defined $ref_test->[0] and defined $ref_test->[1]
		and $ref_test->[0]->length >= $ref->[0]->length
		and $ref_test->[1]->length >= $ref->[1]->length;
      }elsif(defined $ref->[0] or defined $ref->[1]){
         # Both sequences defined:
	 $ref = $ref_test if defined $ref_test->[0] and defined $ref_test->[1];
      }else{
         # At least one sequence defined:
	 $ref = $ref_test if defined $ref_test->[0] or defined $ref_test->[1];
      }
   }
   unless(defined $ref->[0] or defined $ref->[1]){
      $self->debug('Impossible to find a suitable reference');
      return;
   }
   $ref = defined $ref->[0] ?
   		( defined $ref->[1] ?
			Bio::Seq->new(-seq=>$ref->[0]->seq . ("N"x20) . $ref->[1]->seq)
			: $ref->[0]
		) : $ref->[1];
   
   $ref->id('ref');
   $self->loci->[0]->strand('+');
   
   # Compare
   LOCUS: for my $k (0 .. $#{$self->loci}){
      my $tgt = Bio::Polloc::GroupCriteria->_build_subseq(
      		$self->loci->[$k]->seq,
		$self->loci->[$k]->from-$size,
		$self->loci->[$k]->to+$size);
      next LOCUS unless $tgt; # <- This may be way too paranoic!
      $tgt->id('tgt');
      my $tgtrc = $tgt->revcom;
      $self->debug("Setting strand for ".$self->loci->[$k]->id) if defined $self->loci->[$k]->id;
      my $eval_fun = 'average_percentage_identity';
      #$eval_fun = 'overall_percentage_identity';
      if($factory->align([$ref, $tgt])->$eval_fun
      		< $factory->align([$ref,$tgtrc])->$eval_fun){
         $self->debug("Assuming negative strand, setting locus orientation");
	 $self->loci->[$k]->strand('-');
      }else{
         $self->debug("Assuming positive strand, setting locus orientation");
         $self->loci->[$k]->strand('+');
      }
   } # LOCUS
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my ($self, @args) = @_;
   my($name, $featurename, $genomes) = $self->_rearrange([qw(NAME FEATURENAME GENOMES)], @args);
   $self->name($name);
   $self->featurename($featurename);
   $self->genomes($genomes);
}

1;
