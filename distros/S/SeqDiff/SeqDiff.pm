=head1 NAME

SeqDiff - A tool to find the differences between two Seq objects.

=head1 SYNOPSIS

  # use the package
	use SeqDiff;
	
  # get some SeqI objects from somewhere (GenBank/RefSeq/...)
	my $old_seq;        # a Bio::SeqI implementing object
	my $new_seq;        # a Bio::SeqI implementing object
	
  # get a new instance
	my $seqdiff = SeqDiff->new(
		-old 	=> $old_seq,
		-new 	=> $new_seq,
	);
	
  # match the features
	$seqdiff->match_features();	
	
  # loop through the pairs of matching features and compare
	while ( my $diff = $seqdiff->next() ) {
		next unless ref $diff;
		# do something with $diff
	}
	
  # get whatever features were 'lost' or 'gained
    my @lost      = $seqdiff->get_lost_features();
    my @gained    = $sefdiff->get_gained_features();

	

=head1 DESCRIPTION

The SeqDiff tool presented here will compare two Bio::Seq objects. 
It first looks through both objects and matches their features 
based on some criteria. It then recursively compares each pair of
features and returns the comparison. 

Originally the package calculated the differences for all the
features instantly (in memory.) This caused a problem for Seq objects
that have large numbers of features. Now the SeqDiff object has a 
method called I<next()> that should be used to iterate through the
comparisons.
	
This package was developed specifically for comparing the file-
histories of GenBank/RefSeq files....what changed from one version
to the next?

=head1 CONSTRUCTORS
SeqDiff-E<gt>new()

The new() method constructs a new SeqDiff object. The returned
object can be used to retreive differences between the two SeqI
objects given to it. 

=over 5

=item -old

A Bio::SeqI implementing object. This is considered to be a 
representation of the data that existed earlier in time.

=item -new

Another Bio::SeqI implementing object. This is the data that
is more recent relative to the other object.

=item -include_all

This boolean flag tells SeqDiff to return the entire comparison, 
not just the differences between the two features. It will return a hash
consisting of the keys:

    'old'           # the feature from the "old" obj
    'new'           # the feature from the "new" obj
    'comparison'    # the complete comparison

=item -verbose

This boolean flag will print nice messages about what is going on.
Pretty much useless.

=back

=head1 OBJECT METHODS

See below for more detailed summaries. The main methods are:

=head2 $seqdiff-E<gt>match_features()

    Match the two objects' features to each other. ("Line 'em up.")

=head2 $seqdiff-E<gt>next()

    Return the result of the comparison between the next two matching
    features from the stream, or nothing if no more. ("Knock 'em down.")

=head2 $seqdiff-E<gt>get_lost_features()

    Returns an array of the features that were not matched from the 
    "old" seq object. (i.e. They were 'lost' from older to newer.)
    
=head2 $seqdiff-E<gt>get_gained_features()

    Returns an array of the features that were not matched from the 
    "new" seq object. (i.e. They were 'gained' from older to newer.)    

=head1 AUTHOR

Lance Ferguson E<lt>lancer92385@neo.tamu.edu<gt>

Daniel Renfro E<lt>bluecurio@gmail.com<gt>

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceeded by an
underscore "_". 

=cut 

# code starts here...

package SeqDiff;

use strict;
use Carp;
use English;
use base qw/ Bio::Root::Root /;

my ($_old_seq, $_new_seq);						# holds the Seq objects
my (@_matched, @_gained, @_lost);				# holds things after trying to match them

my %_differences;								# where to hold the differences
my $_pair_index = 0;							# an int holding the index of the pair we're comparing
my $_total_num_attempted_matches;

my $_is_verbose;								# should we output nice messages?
my $_is_debug = 0;								# debug on/off - prints (maybe) useful info
my $_include_all;								# include non-differences in $_differences?
 
my @_dbxref_prefix_whitelist 	= qw/ GI GeneID taxon /;
my @_primary_tag_whitelist 		= qw/ gene CDS mRNA source /;

my %_specific_bp_callbacks		= (
	'Bio::PrimarySeqI'		=> \&_bp_specific_handler_Bio_PrimarySeqI,
	'Bio::LocationI' 		=> \&_bp_specific_handler_Bio_LocationI,
);



=head2 new

 Title   : new
 Usage   : $seqdiff = SeqDiff->new( %options );
 Function: Returns a new instance of this class.
 Returns : An object
 Args    : Named parameters:
            -old    		=> SeqI object of the older data
            -new   			=> SeqI object of the newer data
            -include_all	=> include all features, not just the comparison
            -verbose		=> print (possible) helpful messages
            
=cut

sub new {
	my ($caller, @args) = @_;
	my $class = ref($caller) || $caller;
		
	## TODO: check if we want to call SUPER on an object if $caller is an object
	my %param = @args;
	@param{ map { lc $_ } keys %param } = values %param;  # lowercase key
	
	if ( !defined($param{'-old'}) || !defined($param{'-new'}) ) {
		$class->throw( 'Not enough parameters given. Please make sure both -old and -new are specified.');
	}
	# if old and new are not SeqI objects, throw
	if ( !ref($param{'-old'}) && !$param{'-old'}->isa('Bio::SeqI') ) {
		$class->throw('-old requires a Bio::SeqI implementing object.');
	}
	# if old and new are not SeqI objects, throw
	if ( !ref($param{'-new'}) && !$param{'-new'}->isa('Bio::SeqI') ) {
		$class->throw('-new requires a Bio::SeqI implementing object.');
	}	
	if ( defined($param{'-verbose'}) ) {
		$_is_verbose = $param{'-verbose'};
	}
	if ( defined($param{'-debug'}) && $param{'-debug'}) {
		$_is_debug = $param{'-debug'};
	}	
	if ( defined($param{'-include_all'}) && $param{'-include_all'}) {
		$_include_all = $param{'-include_all'};
	}	
	# assign the two SeqI objects to our member variables
	$_old_seq = $param{-old};
	$_new_seq = $param{-new};
	
	# return the object
	bless \%param, $class;		# implicit return of blessed hash
}


=head2 old_seq

 Title   : old_seq
 Usage   : $seqdiff->old_seq( $seq );
 Function: If a parameter is given to this method it will set the "old" Seq object.
           This is purely convention (based on what is called "lost" or "gained.")
           If a parameter is not given, it will return the object that is currently set
           to the "old" object.
 Returns : a SeqI implementing object.
 Args    : new value (optional)
 
=cut

sub old_seq {
	my $self = shift;
	
	if (scalar(@_)) {
		$_old_seq = shift;
		return $_old_seq;
	}
	else {
		return $_old_seq;
	}
}


=head2 new_seq

 Title   : new_seq
 Usage   : $seqdiff->new_seq( $seq );
 Function: If a parameter is given to this method it will set the "new" Seq object.
           This is purely convention (based on what is called "lost" or "gained.")
           If a parameter is not given, it will return the object that is currently set
           to the "new" object.
 Returns : a SeqI implementing object.
 Args    : new value (optional)
 
=cut

sub new_seq {
	my $self = shift;
	
	if (scalar(@_)) {
		$_new_seq = shift;
		return $_new_seq;
	}
	else {
		return $_new_seq;
	}
}


=head2 match_features

 Title   : match_features
 Usage   : $seqdiff->match_features();
 Function: First loops through the features and determines which ones are available to match, 
           based on the criteria set forth in SeqDiff::_feature_pair_matches(). These features get
           grouped into three categories:
             1. matched   - features that matched
             2. lost      - features in the "old" object that are not in the "new"
             3. gained    - features in the "new" object that are not in the "old"
           Then the method compares each set of matching features using the method
           SeqDiff::_compare_features().       
 Returns : null
 Args    : none (Uses member variables.)
 
=cut

sub match_features {
	my $self = shift;

	if ($_is_verbose || $_is_debug) {
		print STDERR "calculating differences...\n";
	}

	my @features_to_match_old;
	my @features_to_match_new;
	
	@features_to_match_old = $_old_seq->get_SeqFeatures();
	@features_to_match_new = $_new_seq->get_SeqFeatures();

	if ($_is_verbose || $_is_debug) {
		print STDERR "Total number of features from OLD: " . scalar(@features_to_match_old) . "\n";
		print STDERR "Total number of features from NEW: " . scalar(@features_to_match_new) . "\n";
	}

	# go through and match the features based on some criteria
	if ($_is_verbose || $_is_debug) {
		print STDERR "matching features...\n";
	}
	
	my $i = 0;
	my $j = 0;
	MATCH: while ($features_to_match_old[$i]) {
		while ($features_to_match_new[$j]) {
			#print "Trying to match A" . $self->_f_info($features_to_match_old[$i]) . " with B" . $self->_f_info($features_to_match_new[$j]) . ". (\$i=$i, \$j=$j)\n" if ($_is_debug);
			if ( $self->_feature_pair_matches($features_to_match_old[$i], $features_to_match_new[$j]) ) {
				#print "\t--Matched--\n" if ($_is_debug);
				# push the matched pair onto a stack...
				push @_matched, [ $features_to_match_old[$i], $features_to_match_new[$j] ];
				# ...and remove them from their respective arrays
				splice @features_to_match_old, $i, 1;
				splice @features_to_match_new, $j, 1;
				$j = 0;
				next MATCH;
			}
			#print "\t--No Match--\n" if ($_is_debug);
			$j++;
		}
		$i++;
		$j = 0;
	}
	
	$_differences{'matched_features'} = [];
	$_differences{'lost_features'} = \@features_to_match_old;
	$_differences{'gained_features'} = \@features_to_match_new;
	
	if ($_is_debug) {
		print STDERR "number of lost features:    " . scalar( @{$_differences{'lost_features'}} ) . "\n";
		print STDERR "number of gained features:  " . scalar( @{$_differences{'gained_features'}} ) . "\n";
		print STDERR "comparing " . scalar(@_matched) . " pairs of matched features...\n";
	}

}

=head2 get_lost_features

 Title   : get_lost_features
 Usage   : $seqdiff->get_lost_features();
 Function: Returns an array of the features that failed to match
           from the "old" seq object...based on the given criteria. 
 Returns : an array
 Args    : none
 
=cut

sub get_lost_features {
	return $_differences{'lost_features'};
}

=head2 get_gained_features

 Title   : get_gained_features
 Usage   : $seqdiff->get_gained_features();
 Function: Returns an array of the features that failed to match
           from the "new" seq object...based on the given criteria. 
 Returns : an array
 Args    : none
 
=cut

sub get_gained_features {
	return $_differences{'gained_features'};
}



=head2 next

 Title   : next
 Usage   : $seqdiff->next();
 Function: Calculates the difference between the next two matching 
           features from the stream and returns it.
 Returns : A hash of the differences, true if there are no differences,
           or false if there is nothing else to compare
 Args    : none
 
=cut

sub next {
	my $self = shift;
	
	# return undef if there aren't any more pairs to compare
	return undef unless defined $_matched[$_pair_index];
	
	# get the pair to compare and increment the counter
	my ($fA, $fB) = @{$_matched[$_pair_index]};
	$_pair_index++;
		
	# do the comparison
	my %comparison_results;
	my $result = $self->_compare_features( $fA, $fB );
	
	# conditional return
	if ( $result ) {
		$comparison_results{'old'} = $fA;
		$comparison_results{'new'} = $fB;
		$comparison_results{'comparison'} = $result;
		return \%comparison_results;
	}
	return 1;
}

=head2 primary_tag_whitelist

 Title   : primary_tag_whitelist
 Usage   : $seqdiff->primary_tag_whitelist( @list );
 Function: Sets or gets the array of whitelisted primary_tags to use for
           matching the features in _feature_pair_matches.
           
           Currently unused.
           
 Returns : an array
 Args    : an array or nothing
 
=cut

sub primary_tag_whitelist {
	my $self = shift;
	
	if (scalar(@_)) {
		@_primary_tag_whitelist = @_;
		return 1;
	}
	else {
		return @_primary_tag_whitelist;
	}
}

=head2 dbxref_prefix_whitelist

 Title   : dbxref_prefix_whitelist
 Usage   : $seqdiff->dbxref_prefix_whitelist( @list );
 Function: Sets or gets the array of whitelisted database cross-
           references to use for matching the features in 
           _feature_pair_matches.           
 Returns : an array
 Args    : an array or nothing
 
=cut

sub dbxref_prefix_whitelist {
	my $self = shift;
	
	if (scalar(@_)) {  		# this is a SET
		@_dbxref_prefix_whitelist = @_;
		return 1;
	}
	else {					# this is a GET
		return @_dbxref_prefix_whitelist;
	}
}


=head2 BioPerl_object_handler

 Title   : BioPerl_object_handler
 Usage   : $seqdiff->BioPerl_object_handler( %list );
 Function: Sets or gets the mapping of object-types to callbacks for
           specific types of (BioPerl) objects. This method simply 
           registers callbacks for a class. _compare_properties 
           uses this hash to look for code to run when it encounters
           an object as a property of a feature. See _compare_properties.
           
           Example:
           
           my %callbacks = (
	          'Bio::PrimarySeqI'    => \&_my_Bio_PrimarySeqI_hander,
	          'Bio::LocationI'      => \&_my_Bio_LocationI_handler,
            );
            $seqdiff->BioPerl_object_handler( %callbacks );
  
 Returns : a hash
 Args    : an hash or nothing
 
=cut

sub BioPerl_object_handler {
	my $self = shift;
	if (scalar(@_)) {
		%_specific_bp_callbacks = @_;
	} else {
		return %_specific_bp_callbacks;
	}
}


=head1 INTERNAL METHODS
   
The methods are listed here for understanding the internals
of the package. Most of the time these methods should not be
called directly. Use at your own risk.


=head2 _feature_pair_matches

 Title   : _feature_pair_matches
 Usage   : $seqdiff->_feature_pair_matches( $fA, $fB );
 Function: This method contains the criteria to match features on. It can be 
           overridden to provide specific criteria.
 Returns : boolean
 Args    : two SeqFeatureI implementing objects, the older one first.
 
=cut

sub _feature_pair_matches {
	my ($self, $fA, $fB) = @_;
		
	$_total_num_attempted_matches++;
	
	if ( !$fA || !$fB ) {
		$self->warn( "There was a problem with a feature.\n  A:\t$fA\n  B:\t$fB\n" );	
		return;
	}
	
	# if one or the other doesn't have a dbxref, return false;
	if ( !$fA->has_tag('db_xref') || !$fB->has_tag('db_xref')) {
		#print "\tone of the features doesn't have any db_xrefs!\n" if ($_is_debug);
		return 0;
	}

	# if the two features don't match on primary_tags, return false;
	if ( $fA->primary_tag() ne $fB->primary_tag() ) {
		#print "\tthe two features have different primary_tags\n" if ($_is_debug);
		return 0;
	}
	#print "\tthey both have the primary_tag \"" . $fA->primary_tag  . "\"\n"  if ($_is_debug);

	# get lists of all the db_xrefs from each feature
	my @fA_dbxrefs = $fA->get_tag_values('db_xref');
	my @fB_dbxrefs = $fB->get_tag_values('db_xref');
	
	# loop through and try and match on whitelisted db_xrefs
	for my $i ( 0..$#fA_dbxrefs ) {
		my ($prefixA, $idA) = split /:/, $fA_dbxrefs[$i];
		#print "\t\"" . $prefixA . "\" from A" if ($_is_debug);
		if ( $self->_in_array(\@_dbxref_prefix_whitelist, $prefixA) ) {
			#print " is in whitelist\n" if ($_is_debug);
			for my $j ( 0..$#fB_dbxrefs ) {
				my ($prefixB, $idB) = split /:/, $fB_dbxrefs[$j];
				#print "\t\"" . $prefixB . "\" from B" if ($_is_debug);
				if ( $self->_in_array(\@_dbxref_prefix_whitelist, $prefixB) ) {
					#print " is in whitelist\n" if ($_is_debug);
					if ($fA_dbxrefs[$i] eq $fB_dbxrefs[$j]) {
						#print "\t" . $fA_dbxrefs[$i] . " MATCHES " .  $fB_dbxrefs[$j] . "\n" if ($_is_debug);
						return 1;
					}
					else {
						#print "\t" . $fA_dbxrefs[$i] . " does not match " .  $fB_dbxrefs[$j] . "\n" if ($_is_debug);
					}
				}
				else {
					#print " is NOT in the whitelist.\n" if ($_is_debug);
				}
			}
		}
		else {
			#print " is NOT in the whitelist.\n" if ($_is_debug);
		}
	}
	return 0;
} 

=head2 _compare_features

 Title   : _compare_features
 Usage   : $seqdiff->_compare_features( $feature_A, $feature_B );
 Function: Typically run by SeqDiff->match_features() and not called directly,
           this method will compare two objects. This is the heart of the SeqDiff 
           package.            
 Returns : This method returns one of two things:
			  1. A reference to a hash; the three keys being 'lost', 'gained', and 'common'.
				 This refers to properties that were either lost, gained, or that both 
				 objects have in common. This hash recurses exhaustively. I suggest using
				 Data::Dumper or YAML to have a look at it.
			  2. False - the two objects are exactly the same and no difference could
						 be found.
 Args    : Two objects in the ambiguous order (old, new);
 
=cut

sub _compare_features {
	my ($self, $fA, $fB) = @_;
	
	# create places to store things
	my %common_properties = ();
	my @gained_properties = ();
	my @lost_properties = ();

	# have we encountered a difference yet?
	my $found_difference = 0;

	
	# loop through A looking for stuff in B
	while ( my ($property, $value) = each %{$fA} ) {
		if ( exists $fB->{$property} ) {
			$common_properties{ $property } = [];
		} 
		else {
			push @lost_properties, $property;
			$found_difference = 1 if ($found_difference == 0);
		}
	}
	
	# loop through B looking for things we haven't previously found in A...?
	while ( my ($property, $value) = each %{$fB} ) {
		if ( exists($fA->{$property})) {
			my @common_properties_so_far = keys %common_properties;
			$common_properties{ $property } = [] if ( !$self->_in_array(\@common_properties_so_far, $property) );
		}
		else {
			push @gained_properties, $property;
			$found_difference = 1 if ($found_difference == 0);
		}
	}
	
	# loop through the common properties and compare them
	my %common_properties_to_return = ();
	foreach my $property (keys %common_properties) {
		my $result = $self->_compare_properties( $fA->{$property}, $fB->{$property}  );
		if ($result) {
			$common_properties_to_return{$property} = $result;
			$found_difference = 1 if ($found_difference == 0);		
		}
		elsif ($_include_all) {
			# no difference found, but want to return the value anyway...use $fA's value
			$common_properties_to_return{$property} = $fA->{$property};
		}
	}

	# construct a hash to return only what's needed
	my %return = ();
	$return{'common'} 	= \%common_properties_to_return if (%common_properties_to_return);
	$return{'lost'} 	= \@lost_properties if (@lost_properties);
	$return{'gained'} 	= \@gained_properties if (@gained_properties);
	
	if ( $found_difference ) {
		return \%return;
	}
	else {
		return 0;
	}
}

=head2 _compare_properties

 Title   : _compare_properties
 Usage   : $seqdiff->_compare_properties( $fA, $fB );
 Function: Compares the internals of the features. Essentially a general 
           object-diffing method. Has code for attaching callbacks for 
           specific types of BioPerl objects (see BioPerl_object_handler.)
 Returns : boolean
 Args    : two SeqFeatureI implementing objects, the older one first.
 
=cut

sub _compare_properties {
	my ($self, $pA, $pB) = @_;

	# get the types of the two properties
	my $prop_A_type = $self->_typeOf( $pA );
	my $prop_B_type = $self->_typeOf( $pB );
	
	# make sure they are the same type, or report if not
	if ( $prop_A_type ne $prop_B_type ) {
		return {
			'from' 	=> $prop_A_type,
			'to'	=> $prop_B_type,
		};		
	}
	
	# now we can assume they are the same type...just use $prop_A_type.
	my $type = $prop_A_type;
	
	# handle the base case where they are both scalars
	if ( $type eq 'STRING' ) {
		if ($pA ne $pB) {
			return {
				'from' 	=> $pA,
				'to'	=> $pB,
			};
		}
	}
	elsif ( $type eq 'INT' || $type eq 'FLOAT' ) {
		if ($pA != $pB) {
			return {
				'from' 	=> $pA,
				'to'	=> $pB,
			};
		}
	}
	
	# handle the more complex cases
	elsif ($type eq 'ARRAY') {
	
		my @common_elements = grep { $self->_in_array($pA, $_); } @{$pB}; 
        my @lost_elements   = grep { !$self->_in_array(\@common_elements, $_); } @{$pA};
        my @gained_elements = grep { !$self->_in_array(\@common_elements, $_); } @{$pB};
        
        # build up a hash to return
        my %return = ();
        $return{'lost'}     = \@lost_elements   if (@lost_elements);
        $return{'gained'}   = \@gained_elements if (@gained_elements);
        
        # loop through the common elements and compare
        my %common_elements_to_return = ();
        for (my $i=0, my $c=scalar(@common_elements); $i<$c; $i++) {
        	my $result = $self->_compare_properties( $pA->[$i], $pB->[$i] );
        	if ( $result ) {
        		$common_elements_to_return{ $common_elements[$i] } = $result;
        	}
        }
        $return{'common'}   = \%common_elements_to_return if (%common_elements_to_return);
 
 
		# return if there are any lost, any gained, or any changes       
		return \%return if (%return);

	} 
	elsif ($type eq 'HASH') {
		return $self->_compare_features( $pA, $pB );
	}
	elsif ($type eq 'OBJ') {
		my $ref_A = ref $pA;
		my $ref_B = ref $pB;
		
		if ($ref_A ne $ref_B) {
			return {
				'from' 	=> $pA,
				'to'	=> $pB
			};
		}
		
		# now we can assume they are the same type of object, just use $ref_A for now
		my $result = $self->_specific_bp_obj_handler( $ref_A, $pA, $pB );
		return $result if ($result || $_include_all);
	} 
	elsif ($type eq 'CODE') {
		# to be filled in later
	} 
	elsif ($type eq 'REF') {
		# to be filled in later
	} 
	elsif ($type eq 'GLOB') {			
		# to be filled in later
	} 
	elsif ($type eq 'LVALUE') {
		# something probably went wrong here. 
	} 
	else {
		# what happened here! 
	}
	
	# no difference!
	return 0;
}


=head2 _get_differences

 Title   : _get_differences
 Usage   : $seqdiff->_get_differences();
 Function: Returns whatever is currently in the $_differences property.
 
           Currently unused.
 
 Returns : a hash
 Args    : none
 
=cut

sub _get_differences {
	return %_differences;
}

=head2 _specific_bp_obj_handler

 Title   : _specific_bp_obj_handler
 Usage   : $seqdiff->_specific_bp_obj_handler( $class, $oA, $oB );
 Function: Internal method that looks through the registered callbacks based
           on the class given. It first looks for any callbacks that match exactly
           to the classname, then checks inheretance in a depth-first manner.
           
           Totally untested! Sounded like a good idea at the time.
           
 Returns : ??
 Args    : string, obj, obj
 
=cut

sub _specific_bp_obj_handler {
	my ($self, $obj_class, $oA, $oB) = @_;
	
	if ( defined($_specific_bp_callbacks{$obj_class}) && exists($_specific_bp_callbacks{$obj_class}) ) {
		# first look for an explicit callback
		return &{ $_specific_bp_callbacks{$obj_class} }($oA, $oB);
	}
	else {
		# then look for anything that is assigned to an ancestor (think inheretance)
		my $return;
		while ( my($class, $callback) = each(%_specific_bp_callbacks) ) {
			if ($oA->isa($class)) { 
				$return = &{$_specific_bp_callbacks{$class}}($oA, $oB);
			}
		}
		return $return if ($return);
	}
}

# default registered handler for Bio::Location::Simple objects 
sub _bp_specific_handler_Bio_LocationI {
	my ($oA, $oB) = @_;
	#print "$oA -vs- $oB\n";
	return 0;
}

# default registered handler for Bio::PrimarySeq objects
sub _bp_specific_handler_Bio_PrimarySeqI {
	my ($oA, $oB) = @_;
	#print "$oA -vs- $oB\n";
	return 0;
}


sub _in_array {
	my ($self, $array, $scalar) = @_;
	foreach my $value (@{$array}) {
		next if (!$value);
		return 1 if $value eq $scalar;
	}
	return 0;
}


# got this from [ http://www.sitepoint.com/forums/showthread.php?t=308897 ]
sub _typeOf {
	my ($self, $val) = @_;

	if ( ! defined $val ) {
		return 'null';
	} elsif ( ! ref($val) ) {
		if ( $val =~ /^-?\d+$/ ) {
			return 'INT';
		} elsif ( $val =~ /^-?\d+(\.\d+)?$/ ) {
			return 'FLOAT';
		} else {
			return 'STRING';
		}
	} else {
		my $type = ref($val);
		if ( $type eq 'HASH' || $type eq 'ARRAY' || $type eq 'CODE' || $type eq 'REF' || $type eq 'GLOB' || $type eq 'LVALUE' ) {
			return $type;
		} else {
			# Object...
			return 'OBJ';
		}
	}
}

sub _f_info {
	my ($self, $f) = @_;
	
	my @db_xrefs = ($f->has_tag('db_xref'))
		? $f->get_tag_values('db_xref')
		: ();
	my ($tag) = ($f->primary_tag)
		? $f->primary_tag
		: "";
	return sprintf("[[%s %s]]", $tag, shift(@db_xrefs));
} 

sub get_total_num_attempted_matches {
	return $_total_num_attempted_matches;
}



# return a true value from this module
1 		


__END__



# default method for displaying the differences
sub _default_display_differences {
	my $self = shift;

	# print the lost features in a format
	format STDOUT_TOP = 
            locus_tag       primary_tag     start    end       dbxrefs
----------------------------------------------------------------------------------------------------
.

	print "========== Lost Features ======================================================\n";
	my $record_num = 1;
	foreach my $f ( @{$_differences{'lost_features'}} ) {
	
		my ($locus_tag) =	($f->has_tag('locus_tag')) 
			? $f->get_tag_values(qw/locus_tag/)
			: ("");
		my $primary_tag = $f->primary_tag;
		my $start 		= $f->start;
		my $end			= $f->end;

		my $db_xref_str = "";
		if ($f->has_tag('db_xref')) {
			my @dbxrefs = $f->get_tag_values('db_xref');
			$db_xref_str = join(', ', @dbxrefs);
		}
		
		format STDOUT = 
@<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<<<< @<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$record_num, $locus_tag,    $primary_tag,   $start,  $end,     $db_xref_str,
                                                               ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ~~ 
                                                               $db_xref_str,
.		
		write STDOUT;
		$FORMAT_LINES_LEFT = 1;			# don't page-inate the results!
		$record_num++;
	}
	print "\n";
}