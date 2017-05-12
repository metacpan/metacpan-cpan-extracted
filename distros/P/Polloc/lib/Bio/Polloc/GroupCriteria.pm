=head1 NAME

Bio::Polloc::GroupCriteria - Rules to group loci

=head1 DESCRIPTION

Takes loci and returns groups of loci based on certain
rules.  If created via .bme (.cfg) files, it is defined
in the C<[ RuleGroup ]> and C<[ GroupExtension ]>
namespaces.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 LICENSE

This package is licensed under the Artistic License - see LICENSE.txt

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=back

=cut

package Bio::Polloc::GroupCriteria;
use strict;
use base qw(Bio::Polloc::Polloc::Root);
use List::Util qw(min max first);
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::LociGroup;
use Bio::Polloc::GroupCriteria::operator;
use Bio::Polloc::GroupCriteria::operator::cons;
use Bio::Seq;
use Error qw(:try);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


#

=head1 APPENDIX - Methods

Methods provided by the package

=cut

=head2 new

=over

=item 

Generic initialization method

=item Arguments

=over

=item -souce I<str>

See L<source>

=item -target I<str>

See L<target>

=item -features I<Bio::Polloc::LociGroup>

Alias of C<-loci>

=item -loci I<Bio::Polloc::LociGroup>

See L<locigroup>

=back

=item Returns

The C<Bio::Polloc::GroupCriteria> object

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 source

=over

=item 

Sets/gets the type of source loci (see L<Bio::Polloc::LocusI-E<gt>family>

=back

=cut

sub source {
   my($self, $value) = @_;
   $self->{'_source'} = $value if defined $value;
   return $self->{'_source'};
}

=head2 target

=over

=item 

Sets/gets the type of target loci (see L<Bio::Polloc::LocusI-E<gt>family>

=back

=cut

sub target {
   my($self, $value) = @_;
   $self->{'_target'} = $value if defined $value;
   return $self->{'_target'};
}

=head2 locigroup

=over

=item 

Gets/sets the input L<Bio::Polloc::LociGroup> object containing
all the loci to evaluate.

=back

=cut

sub locigroup {
   my($self, $value) = @_;
   if(defined $value){
      $self->{'_locigroup'} = $value;
      $self->{'_reorder'} = 1;
   }
   return $self->{'_locigroup'};
}

=head2 condition

=over

=item 

Sets/gets the conditions set to evaluate.

=back

=cut

sub condition {
   my($self, $value) = @_;
   if(defined $value){
      $self->throw('Unexpected type of condition', $value)
      		unless UNIVERSAL::can($value, 'isa') and $value->isa('Bio::Polloc::GroupCriteria::operator');
      $self->{'_condition'} = $value;
   }
   return $self->{'_condition'};
}

=head2 evaluate

=over

=item 

Compares two loci based on the defined conditions

=item Arguments

=over

=item *

The first locus (a L<Bio::Polloc::LocusI> object)

=item *

The second locus (a L<Bio::Polloc::LocusI> object)

=back

=item Returns

Boolean

=item Throws

L<Bio::Polloc::Polloc::Error> if unexpected input or undefined condition, source or
target

=back

=cut

sub evaluate {
   my($self, $feat1, $feat2) = @_;
   # Test the input
   $feat1->isa('Bio::Polloc::LocusI') or
   	$self->throw("First feature of illegal class", $feat1);
   
   $feat2->isa('Bio::Polloc::LocusI') or
   	$self->throw("Second feature of illegal class", $feat2);
   
   defined $self->condition or
   	$self->throw("Undefined condition, impossible to group");
   
   $self->condition->type eq 'bool' or
   	$self->throw("Unexpected type of condition", $self->condition);
   
   $self->throw("Undefined source features") unless defined $self->source;
   $self->throw("Undefined target features") unless defined $self->target;
   
   # Run
   return 0 unless $feat1->family eq $self->source;
   return 0 unless $feat2->family eq $self->target;
   $Bio::Polloc::GroupCriteria::operator::cons::OP_CONS->{'FEAT1'} = $feat1;
   $Bio::Polloc::GroupCriteria::operator::cons::OP_CONS->{'FEAT2'} = $feat2;
   my $o = $self->condition->operate;
   $Bio::Polloc::GroupCriteria::operator::cons::OP_CONS->{'FEAT1'} = undef;
   $Bio::Polloc::GroupCriteria::operator::cons::OP_CONS->{'FEAT2'} = undef;
   return $o;
}

=head2 get_loci

=over

=item 

Gets the stored loci

=item Note

The stored loci can also be obtained with C<$object-E<gt>locigroup-E<gt>loci>,
but this function ensures a consistent order in the loci for its evaluation.

=back

=cut

sub get_loci {
   my($self,@args) = @_;
   $self->{'_features'} = $self->locigroup->loci
   	if defined $self->locigroup and not defined $self->{'_features'};
   $self->{'_features'} = [] unless defined $self->{'_features'};
   if($self->{'_reorder'} && $self->source ne $self->target){
      my @src = ();
      my @tgt = ();
      my @oth = ();
      for my $ft (@{$self->locigroup->loci}){
      	    if($ft->family eq $self->source){ push (@src, $ft) }
	 elsif($ft->family eq $self->target){ push (@tgt, $ft) }
	 else{ push @oth, $ft }
      }
      $self->{'_features'} = [];
      push @{$self->{'_features'}}, @tgt, @src, @oth;
      $self->{'_reorder'} = 0;
   }
   return $self->{'_features'};
}


=head2 get_locus

=over

=item 

Get the locus with the specified index.

=item Arguments

The index (int, mandatory).

=item Returns

A L<Bio::Polloc::LocusI> object or undef.

=item Note

This is a lazzy method, and should be used B<ONLY> after C<get_loci()>
were called at least once.  Otherwise, the order might not be the expected,
and weird results would appear.

=back

=cut

sub get_locus {
   my($self, $index) = @_;
   return unless defined $index;
   return unless defined $self->{'_features'};
   return $self->{'_features'}->[$index];
}

=head2 extension

=over

=item 

Sets the conditions for group extensions.

=item Arguments

Array, hash or string with C<-key =E<gt> value> pairs.  Supported values are:

=over

=item -function I<str>

=over

=item C<context>

Searches the flanking regions in the target sequence.

=back

=item -upstream I<int>

Extension in number of residues upstream the feature.

=item -downstream I<int>

Extension in number of residues downstream the feature.

=item -detectstrand I<bool (int)>

Should I detect the proper strand?  Otherwise, the stored strand
is trusted.  This is useful for non-directed features like repeats,
which context is actually directed.

=item -alldetected I<bool (int)>

Include all detected features (even these overlapping with input features).

=item -feature I<bool (int)>

Should I include the feature region in the search? 0 by default.

=item -lensd I<float>

Number of Standar Deviations (SD) tolerated as half of the range of lengths
for a feature.  The average (Avg) and the standard deviation of the length
are calculated based on all the stored features, and the Avg+(SD*lensd) is
considered as the largest possible new feature.  No minimum length constraint
is given, unless explicitly set with -minlen.  This argument is ignored if
C<-maxlen> is explicitly set.  Default is 1.5.

=item -maxlen I<int>

Maximum length of a new feature in number of residues.  If zero (0) evaluates
C<-lensd> instead.  Default is 0.

=item -minlen I<int>

Minimum length of a new feature in number of residues.  Default is 0.

=item -similarity I<float>

Minimum fraction of similarity to include a found region. 0.8 by default.

=item -oneside I<bool (int)>

Should I consider features with only one of the sides?  Takes effect only if
both -upstream and -downstream are defined. 0 by default.

=item -algorithm I<str>

=over

=item C<blast>

Use BLAST to search (after multiple alignment and consensus calculation of
queries).  Default algorithm.

=item C<hmmer>

Use HMMer to search (after multiple alignment and C<hmmbuild> of query
sequences).

=back

=item -score I<int>

Minimum score for either algorithms B<blast> and B<hmmer>. 20 by default.

=item -consensusperc I<float>

Minimum percentage a residue must appear in order to include it in the
consensus used as query.  60 by default.  Only if -algorithm blast.

=item -e I<float>

If C<-algorithm> B<blast>, maximum e-value.  0.1 by default.

=item -p I<str>

If C<-algorithm> B<blast>, program used (C<[t]blast[npx]>).  B<blastn> by
default.

=back

=item Throws

L<Bio::Polloc::Polloc::Error> if unexpected input,

=back

=cut

sub extension {
   my ($self, @args) = @_;
   return $self->{'_groupextension'} unless $#args>=0;
   @args = split /\s+/, $args[0] if $#args == 0;
   $self->throw("Odd number of elements, impossible to build key-value pairs", \@args)
   	unless $#args%2;
   my %f = @args;
   $f{'-function'} ||= 'context';
   $f{'-algorithm'} ||= 'blast';
   ($f{'-feature'} ||= 0) += 0;
   ($f{'-downstream'} ||= 0) += 0;
   ($f{'-upstream'} ||= 0) += 0;
   ($f{'-detectstrand'} ||= 0) += 0;
   ($f{'-alldetected'} ||= 0) += 0;
   ($f{'-oneside'} ||= 0) += 0;
   $f{'-lensd'} = defined $f{'-lensd'} ? $f{'-lensd'}+0 : 1.5;
   $f{'-maxlen'} = defined $f{'-maxlen'} ? $f{'-maxlen'}+0 : 0;
   $f{'-minlen'} = defined $f{'-minlen'} ? $f{'-minlen'}+0 : 0;
   $f{'-similarity'} = defined $f{'-similarity'} ? $f{'-similarity'}+0 : 0.8;
   $f{'-score'} = defined $f{'-score'} ? $f{'-score'}+0 : 20;
   $f{'-consensusperc'} = defined $f{'-consensusperc'} ? $f{'-consensusperc'}+0 : 60;
   $f{'-e'} = defined $f{'-e'} ? $f{'-e'}+0 : 0.1;
   $f{'-p'} = 'blastn' unless defined $f{'-p'};
   $self->{'_groupextension'} = \%f;
   return $self->{'_groupextension'};
}


=head2 extend

=over

=item 

Extends a group based on the arguments provided by L<Bio::Polloc::GroupCriteria->extension>.

=item Arguments

=over

=item -loci I<Bio::Polloc::LociGroup>

The L<Bio::Polloc::LociGroup> containing the loci in the group to extend.

=back

=item Returns

A L<Bio::Polloc::LociGroup> object containing the updated group, i.e. the
original group PLUS the extended features.

=item Throws

L<Bio::Polloc::Polloc::Error> if unexpected input or weird extension definition.

=back

=cut

sub extend {
   my ($self, @args) = @_;
   my ($loci) = $self->_rearrange([qw(LOCI)], @args);
   # Check input
   my $ext = $self->{'_groupextension'};
   return unless defined $ext;
   $self->throw("The loci are not into an object", $loci)
   	unless defined $loci and ref($loci) and UNIVERSAL::can($loci,'isa');
   $self->throw("Unexpected type for the group of loci", $loci)
   	unless $loci->isa('Bio::Polloc::LociGroup');
   return unless $#{$loci->loci}>=0;
   # Set ID base
   my $group_id = $self->_next_group_id;
   # Run
   my @new = ();
   $self->debug("--- Extending group (based on ".($#{$loci->loci}+1)." loci) ---");
   if(lc($ext->{'-function'}) eq 'context'){
      my ($up_pos, $down_pos, $in_pos);
      $loci->fix_strands(max($ext->{'-downstream'}, $ext->{'-upstream'}))
      	if $ext->{'-detectstrand'} and ($ext->{'-upstream'} or $ext->{'-downstream'});
      # Search
      my $eval_feature = $ext->{'-feature'} ? 1 : 0;
      $up_pos = $self->_search_aln_seqs($loci->align_context(-1, $ext->{'-upstream'}, 0))
      	if $ext->{'-upstream'};
      $down_pos = $self->_search_aln_seqs($loci->align_context(1, $ext->{'-downstream'},0))
      	if $ext->{'-downstream'};
      $in_pos = $self->_search_aln_seqs($loci->align_context(0, 0, 0)) if $ext->{'-feature'};
      # Determine maximum size
      my $max_len = $ext->{'-maxlen'};
      unless($max_len){
	 my($len_avg, $len_sd) = $self->locigroup->avg_length;
	 $self->warn("Building size constrains based in one sequence only")
	 	if $#{$self->locigroup->loci}<1;
	 $max_len = $len_avg + $len_sd*$ext->{'-lensd'};
      }
      $self->debug("Comparing results with maximum feature's length of $max_len");
      # Evaluate/pair
      if($ext->{'-upstream'} and $ext->{'-downstream'}){
	 # Detect border pairs
	 push @new, $self->_detect_border_pairs($up_pos, $down_pos, $max_len);
	 if($eval_feature){
	    $self->debug("Filtering results with in-feature sequences");
	    my @prefilter = @new;
	    @new = ();
	    BORDER: for my $br (@prefilter){
	       push @new,
		  first { $br->[0] ne $_->[0] # != ctg
		     and $br->[3] == $_->[3] # upstream's strand
		     and $br->[3]*$_->[1] < $br->[3]*$br->[2] # no overlap
		     and $br->[3]*$_->[2] > $br->[3]*$br->[1] # no overlap
		  } @$in_pos;
	       #WITHIN: for my $in (@$in_pos){
	#	  $self->throw("Unexpected array structure (in-feature)", $in)
	#	  		unless defined $in->[0] and defined $in->[4];
	#	  next WITHIN	if $br->[0] eq $in->[0] # == ctg
	#	  		or $br->[3] != $in->[3] # upstream's strand
#				or $br->[3]*$in->[1] >= $br->[3]*$br->[2] # overlap
#				or $br->[3]*$in->[2] <= $br->[3]*$br->[1]; # overlap
#		  # Good!
#		  $br->[4] = (2*$br->[4] + $in->[4])/3;
#		  push @new, $br;
#		  next BORDER;
	      # }
	    }
	 }
      }elsif($eval_feature){ @new = @$in_pos }else{
	 $self->throw('Nothing to evaluate!  '.
	 		'I need either the two borders or the middle sequence (or both)');
      }
   }else{
      $self->throw('Unsupported function for group extension', $ext->{'-function'});
   }

   # And finally, create the detected features, discarding loci overlapping input loci
   $self->debug("Found ".($#new+1)." loci, creating extend features");
   my $comments = "Based on group $group_id: ";
   for my $locus (@{$loci->loci}) { $comments.= $locus->id . ", " if defined $locus->id }
   $comments = substr $comments, 0, -2;
   
   my $newloci = Bio::Polloc::LociGroup->new();
   $newloci->name($loci->name."-ext") if defined $loci->name;
   $newloci->featurename($loci->featurename) if defined $loci->featurename;
   $newloci->genomes($loci->genomes) if defined $loci->genomes;
   NEW: for my $itemk (0 .. $#new){
      my $item = $new[$itemk];
      ($item->[1], $item->[2]) = (min($item->[1], $item->[2]), max($item->[1], $item->[2]));
      unless($ext->{'-alldetected'}){
         OLD: for my $locus (@{$loci->loci}){
	    # Not new! :
	    next NEW if $item->[1]<$locus->to and $item->[2]>$locus->from;
	 }
      }
      my $seq;
      my($Gk, $acc) = split /:/, $item->[0], 2;
      $Gk+=0;
      for my $ck (0 .. $#{$self->genomes->[$Gk]->get_sequences}){
         my $id = $self->genomes->[$Gk]->get_sequences->[$ck]->display_id;
	 if($id eq $acc or $id =~ m/\|$acc(\.\d+)?(\||\s*$)/){
	    $seq = [$Gk,$ck]; last;
	 }
      }
      $self->warn('I can not find the sequence', $acc) unless defined $seq;
      $self->throw('Undefined genome-contig pair', $acc, 'UnexpectedException')
      		unless defined $self->genomes->[$seq->[0]]->get_sequences->[$seq->[1]];
      my $id = $self->source . "-ext:".($Gk+1).".$group_id.".($#{$newloci->loci}+2);
      $newloci->add_loci(Bio::Polloc::LocusI->new(
      		-type=>'extend',
		-from=>$item->[1],
		-to=>$item->[2],
		-id=>(defined $id ? $id : ''),
		-strand=>($item->[3]==-1 ? '+' : '-'),
		#		       Gk:Genome	 	   ck:Contig
		-seq=>$self->genomes->[$seq->[0]]->get_sequences->[$seq->[1]],
		-score=>$item->[4],
		-basefeature=>$loci->loci->[0],
		-comments=>$comments,
		-genome=>$self->genomes->[$Gk]
      ));
   }
   return $newloci;
}

=head2 build_bin

=over

=item 

Compares all the included loci and returns the identity matrix

=item Arguments

=over

=item -complete I<bool (int)>

If true, calculates the complete matrix instead of only the bottom-left triangle.

=back

=item Returns

A reference to a boolean 2-dimensional array (only left-down triangle)

=item Note

B<WARNING!>  The order of the output is not allways the same of the input.
Please use C<get_loci()> instead, as source features B<MUST> be after
target features in the array.  Otherwise, it is not possible to have the
full picture without building the full matrix (instead of half).

=back

=cut

sub build_bin {
   my($self,@args) = @_;
   my $bin = [];
   my($complete) = $self->_rearrange([qw(COMPLETE)], @args);
   for my $i (0 .. $#{$self->get_loci}){
      $bin->[$i] = [];
      my $lim = $complete ? $#{$self->get_loci} : $i;
      for my $j (0 .. $lim){
	 $bin->[$i]->[$j] = $self->evaluate(
	 	$self->get_loci->[$i],
		$self->get_loci->[$j]
	 );
      }
   }
   return $bin;
}


=head2 bin_build_groups

=over

=item 

Builds groups of loci based on a binary matrix

=item Arguments

A matrix as returned by L<Bio::Polloc::GroupCriteria-E<gt>build_bin>

=item Returns

A 2-D arrayref.

=item Note

This method is intended to build groups providing information on all-vs-all
comparisons.  If you do not need this information, use the much more
efficient L<Bio::Polloc::GroupCriteria-E<gt>build_groups> method, that relies on
transitive property of groups to avoid unnecessary comparisons.  Please note
that this function also relies on transitivity, but gives you the option to
examine all the paired comparisons and even write your own grouping function.

=back

=cut

sub bin_build_groups {
   my($self,$bin) = @_;
   my $groups = [];
   FEAT: for my $f (0 .. $#{$self->get_loci}){
      GROUP: for my $g (0 .. $#{$groups}){
         MEMBER: for my $m (0 .. $#{$groups->[$g]}){
	    if($bin->[$f]->[$groups->[$g]->[$m]] ){
	       push @{$groups->[$g]}, $f;
	       next FEAT;
	    }
	 }
      }
      push @{$groups}, [$f]; # If not found in previous groups
   }
   # Change indexes by Bio::Polloc::LocusI objects
   return $self->_feat_index2obj($groups);
}


=head2 build_groups

=over

=item 

This is the main method, creates groups of loci.

=item Arguments

=over

=item -cpus I<int>

If defined, attempts to distribute the work among the specified number of
cores. B<Warning>: This parameter is experimental, and relies on
C<Parallel::ForkManager>.  It can be used in production with certain
confidence, but it is highly probable to B<NOT> work in parallel (to avoid
errors, this method ignores the command at ANY possible error).

B<Unimplemented>: This argument is currently ignored. Some algorithmic
considerations must be addressed before using it. B<TODO>.

=item -advance I<coderef>

A reference to a function to call at every new pair.  The function is called
with three arguments, the first is the index of the first locus, the second
is the index of the second locus and the third is the total number of loci.
Note that this function is called B<BEFORE> running the comparison.

=back

=item Returns

An arrayref of L<Bio::Polloc::LociGroup> objects, each containing one consistent
group of loci.

=item Note

This method is faster than combining C<build_bin()> and C<build_groups_bin()>,
and it should be used whenever transitivity can be freely assumed and you do
not need the all-vs-all matrix for further evaluation (for example, manual
inspection).

=back

=cut

sub build_groups {
   my($self,@args) = @_;
   my ($cpus, $advance) = $self->_rearrange([qw(CPUS ADVANCE)], @args);
   
   my $groups = [[0]]; #<- this is bcs first feature is ignored in FEAT1
   my $loci = $self->get_loci;
   my $l_max = $#$loci;
   $self->debug("Building groups for ".($l_max+1)." loci");
   $self->warn('Nothing to do, any stored loci') unless $l_max>=0;
   FEAT1: for my $i (1 .. $l_max){
      FEAT2: for my $j (0 .. $i-1){
         $self->debug("Evaluate [$i vs $j]");
	 &$advance($i, $j, $l_max+1) if defined $advance;
         next FEAT2 unless $self->evaluate(
	 	$loci->[$i],
		$loci->[$j]
	 );
	 # --> If I am here, FEAT1 ~ FEAT2 <--
	 GROUP: for my $g (0 .. $#{$groups}){
	    MEMBER: for my $m (0 .. $#{$groups->[$g]}){
	       if($j == $groups->[$g]->[$m]){
	          # I.e., if FEAT2 is member of GROUP
		  push @{$groups->[$g]}, $i;
		  next FEAT1; #<- This is why the current method is way more efficient
	       }
	    }#MEMBER
	 }#GROUP
      }#FEAT2
      # --> If I am here, FEAT1 belongs to a new group <--
      push @{$groups}, [$i];
   }#FEAT1
   my $out = [];
   for my $gk (0 .. $#$groups){
      my $group = Bio::Polloc::LociGroup->new(-name=>sprintf("%04s", $gk+1)); #+++ ToDo: Is ID ok?
      $group->genomes($self->genomes);
      for my $lk (0 .. $#{$groups->[$gk]}){
         my $locus = $loci->[ $groups->[$gk]->[$lk] ];
	 # Paranoid bugbuster:
	 $self->throw('Impossible to gather the locus back:'.
	 	' $groups->['.$gk.']->['.$lk.']: '.$groups->[$gk]->[$lk],
	 	$loci, 'Bio::Polloc::Polloc::UnexpectedException')
		unless defined $locus;
         $group->add_loci($locus);
      }
      push @$out, $group;
   }
   return $out;
}

=head2 genomes

=over

=item 

Gets the genomes of the base group of loci.  This function is similar
to calling C<locigroup()-E<gt>genomes()>, but is read-only.

=back

=cut

sub genomes {
   my ($self, $value) = @_;
   $self->warn("Attempting to set the genomes from a read-only function")
   	if defined $value;
   return unless defined $self->locigroup;
   return $self->locigroup->genomes;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _detect_border_pairs

=cut

sub _detect_border_pairs {
   my($self, $up_pos, $down_pos, $max_len) = @_;
   return unless $up_pos and $down_pos;
   my $ext = $self->{'_groupextension'};
   my @out = ();
   US: for my $us (@$up_pos){
      $self->throw("Unexpected array structure (upstream): ", $us)
		  unless defined $us->[0] and defined $us->[4];
      $self->debug(" US: ", join(':', @$us));
      my $found;
      my $pair = [];
      DS: for my $ds (@$down_pos){
	 $self->throw("Unexpected array structure (downstream): ", $ds)
			  unless defined $ds->[0] and defined $ds->[4];
	 $self->debug("  DS: ", join(':', @$ds));
	 next DS if $us->[0] ne $ds->[0] # != ctg
		 or $us->[3] == $ds->[3] # == strand
		 or abs($ds->[2]-$us->[2]) > $max_len # too large
		 or abs($ds->[2]-$us->[2]) < $ext->{'-minlen'} # too short
		 or defined $found and abs($us->[2]-$ds->[2]) > $found; # prev better
	 # Good!
	 $self->debug("Saving pair ".$us->[1]."..".$us->[2]."/".$ds->[1]."..".$ds->[2]);
	 $found = abs($us->[2]-$ds->[2]);
	 $pair = [$us->[0], $us->[2], $ds->[2], $us->[3], ($us->[4]+$ds->[4])/2];
      }
      push @out, $pair if $#$pair>1;
   }
   return @out;
}

=head2 _next_group_id

=over

=item 

Returns an incremental ID that attempts to identify the group used as basis
of extension.  Please note that this method DOES NOT check if the group's ID
is the right one, and it is basically intended to keep track of how many
times the C<extend> function has been called.

=back

=cut

sub _next_group_id {
   my $self = shift;
   $self->{'_next_group_id'}||= 0;
   return ++$self->{'_next_group_id'};
}

=head2 _build_subseq

=over

=item Arguments

All the following arguments are mandatory and must be passed in that order.
The strand will be determined by the relative position of from/to:

=over

=item *

The sequence (L<Bio::Seq> object).

=item *

The B<from> position (I<int>).

=item *

The B<to> position (I<int>).

=back

=item Returns

A L<Bio::Seq> object.

=item Comments

This method should be located at a higher hierarchy module (Root?).

This method is static.

=back

=cut

sub _build_subseq {
   my($self, $seq, $from, $to) = @_;
   $self->throw("No main sequence", $seq)
   	unless defined $seq and UNIVERSAL::can($seq, 'isa') and $seq->isa('Bio::Seq');
   my ($start, $end) = (min($to, $from), max($to, $from));
   $start = max($start, 1);
   $end = min($end, $seq->length);
   return unless $start != $end;
   my $seqstr = $seq->subseq($start, $end);
   my $cleanstr = $seqstr;
   $cleanstr =~ s/^N*//;
   $cleanstr =~ s/N*$//;
   return unless length $cleanstr > 0; # See issue BME#5
   my $subseq = Bio::Seq->new(-seq=>$seqstr);
   $subseq = $subseq->revcom if $from < $to;
   return $subseq;
}

=head2 _search_aln_seqs

=over

=item 

Uses an alignment to search in the sequences of the collection of genomes

=item Arguments

A Bio::SimpleAlign object

=item Returns

A 2D arrayref, where first key is an incremental and second key preserves the
orrder in the structure: C<["genome-key:acc", from, to, strand, score]>

=back

=cut

sub _search_aln_seqs {
   my ($self, $aln) = @_;
   my $ext = $self->{'_groupextension'};
   return unless defined $ext;
   return unless defined $self->genomes;
   my $pos = [];
   return $pos unless defined $aln; #<- For example, if zero sequences.  To gracefully exit.
   my $alg = lc $ext->{'-algorithm'};
   if($alg eq 'blast' or $alg eq 'hmmer'){ # ------------------------------- BLAST & HMMer
      # -------------------------------------------------------------------- Setup DB
      unless(defined $self->{'_seqsdb'}){
	 $self->{'_seqsdb'} = Bio::Polloc::Polloc::IO->tempdir();
	 $self->debug("Creating DB at ".$self->{'_seqsdb'});
	 for my $genomek (0 .. $#{$self->genomes}){
	    my $file = $self->{'_seqsdb'}."/$genomek";
	    my $fasta = Bio::SeqIO->new(-file=>">$file", -format=>'Fasta');
	    for my $ctg (@{$self->genomes->[$genomek]->get_sequences}){ $fasta->write_seq($ctg) }
	    # BLAST requires a formatdb (not only the fasta)
	    if($alg eq 'blast'){
	       my $run = Bio::Polloc::Polloc::IO->new(-file=>"formatdb -p F -i '$file' 2>&1 |");
	       while($run->_readline) {} # just run ;o)
	       $run->close;
	    }
	 }
      }
      # -------------------------------------------------------------------- Predefine vars
      my $factory;
      my $query;
      if($alg eq 'blast'){
         $self->_load_module('Bio::Tools::Run::StandAloneBlast');
	 my $cons_seq = $aln->consensus_string($ext->{'-consensusperc'});
	 $cons_seq =~ s/\?/N/g;
         $query = Bio::Seq->new(-seq=>$cons_seq);
      }elsif($alg eq 'hmmer'){
	 $self->_load_module('Bio::Tools::Run::Hmmer');
	 my $tmpio = Bio::Polloc::Polloc::IO->new();
	 # The following lines should be addressed with a three-lines code,
	 # but the buggy AUTOLOAD of Bio::Tools::Run::Hmmer let us no option
	 # -lrr
	 $factory = Bio::Tools::Run::Hmmer->new();
	 $factory->hmm($tmpio->tempfile);
	 $factory->program('hmmbuild');
	 $factory->run($aln);
	 #$factory->calibrate();
      }
      # -------------------------------------------------------------------- Search
      $self->debug("Searching... alg:$alg, sim:".$ext->{'-similarity'}." score:".$ext->{'-score'}." e:".$ext->{'-e'});
      GENOME: for my $Gk (0 .. $#{$self->genomes}){
         my $report;
	 if($alg eq 'blast'){
	    next GENOME if ($query->seq =~ tr/N//) > 0.25*$query->length; # issue#14
	    $factory = Bio::Tools::Run::StandAloneBlast->new(
	 	'-e'=>$ext->{'-e'}, '-program'=>$ext->{'-p'},
		'-db'=>$self->{'_seqsdb'}."/$Gk" );
	    # Try to handle issue#14 and possible undocumented related issues:
	    # (still causing some problems in the STDERR output)
	    try { $report = $factory->blastall($query); }
	    catch Error with {
	       $self->debug("Launch BLAST with query: ".$query->seq());
	       $self->warn("BLAST failed, skipping query and attempting to continue");
	       next GENOME;
	    }
	    otherwise {
	       $self->throw("BLAST failed", $_, 'Bio::Polloc::Polloc::UnexpectedException');
	    };
	 }elsif($alg eq 'hmmer'){
	    $factory->program('hmmsearch');
	    $report = $factory->run($self->{'_seqsdb'}."/$Gk");
	 }
	 # ----------------------------------------------------------------- Parse search
	 RESULT: while(my $res = $report->next_result){
	    HIT: while(my $hit = $res->next_hit){
	       HSP: while(my $hsp = $hit->next_hsp){
	          # -------------------------------------------------------- Eval criteria
	          if(	($alg eq 'blast'
				and $hsp->frac_identical('query') >= $ext->{'-similarity'}
				and $hsp->score >= $ext->{'-score'})
		  or
			($alg eq 'hmmer'
				and $hsp->score >= $ext->{'-score'}
				and $hsp->evalue <= $ext->{'-e'})
		  ){
			# -------------------------------------------------- Save result
			$self->debug("Found: sim:".$hsp->frac_identical('query').", score:".
				$hsp->score.", e:".$hsp->evalue);
			my $r_pos = ["$Gk:".$hit->accession,
				$hsp->strand('hit')!=$hsp->strand('query')?
						$hsp->start('hit'):$hsp->end('hit'),
				$hsp->strand('hit')!=$hsp->strand('query')?
						$hsp->end('hit'):$hsp->start('hit'),
				$hsp->strand('hit')!=$hsp->strand('query')?
						-1 : 1,
				$hsp->bits];
			push @$pos, $r_pos;
		  }
	       } # HSP
	    } # HIT
	 } # RESULT
      } # GENOME
   }else{ # ---------------------------------------------------------------- UNSUPPORTED
      $self->throw('Unsupported search algorithm', $ext->{'-algorithm'});
   }
   return $pos;
}

=head2 _feat_index2obj

=over

=item 

Takes an index 2D matrix and returns it as the equivalent L<Bio::Polloc::LocusI> objects

=item Arguments

2D matrix of integers (arrayref)

=item Returns

2D matrix of L<Bio::Polloc::LocusI> objects (ref)

=back

=cut

sub _feat_index2obj{
   my($self,$groups) = @_;
   for my $g (0 .. $#{$groups}){
      for my $m (0 .. $#{$groups->[$g]}){
         $groups->[$g]->[$m] = $self->get_locus($groups->[$g]->[$m]);
      }
   }
   return $groups;
}


=head2 _grouprules_cleanup

=cut

# Issue #7
sub _grouprules_cleanup {
   my $self = shift;
   if(defined $self->{'_seqsdb'}) {
      my $tmp = $self->{'_seqsdb'};
      for my $k (0 .. $#{$self->genomes || []}){
         while(<$tmp/$k.*>){
	    unlink $_ or $self->throw("Impossible to delete '$_'", $!);
	 }
	 unlink "$tmp/$k" or $self->throw("Impossible to delete '$tmp/$k'", $!);
      }
      rmdir $tmp;
   }
}

=head2 _initialize

=cut

sub _initialize {
   my($self, @args) = @_;
   $self->_register_cleanup_method(\&_grouprules_cleanup);
   my($source, $target, $features, $loci) =
   	$self->_rearrange([qw(SOURCE TARGET FEATURES LOCI)], @args);
   # $self->throw('Discouraged use of -features flag, use -loci instead');
   $self->source($source);
   $self->target($target);
   $loci = $features if defined $features and not defined $loci;
   $self->locigroup($loci);
}


1;


