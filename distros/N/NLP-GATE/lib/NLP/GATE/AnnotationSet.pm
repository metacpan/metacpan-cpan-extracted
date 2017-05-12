package NLP::GATE::AnnotationSet;

use warnings;
use strict;
use Carp;

#use Tree::RB;

=head1 NAME

NLP::GATE::AnnotationSet - A class for representing GATE-like annotation sets

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

  use NLP::GATE::AnnotationSet;
  my $annset = NLP::GATE::AnnotationSet->new();
  $annset->add($annotation);
  $newannset = $annset->get($type[,$featuremap]);
  $arrayref = $annset->getAsArrayRef();
  $ann = $annset->getByIndex();
  $ann = $annset->size();

=head1 DESCRIPTION

This is a simple class representing a annotation set for documents
in the format the GATE software (http://gate.ac.uk/) uses.

An annotation set can contain any number of NLP::GATE::Annotation objects.
Currently, there is no code to make sure that annotations are only added
once.

Annotation sets behave a bit like arrays in that each annotation can be
addressed by an index and each set always contains a known number of
annotations.

TODO: use the offset indices in method getByOffset()

=head1 METHODS

=head2 new()

Create a new annotation set. The name of the annotationset is not a property of the
set, instead, each set is associated with a name when stored with a NLP::GATE::Document
object using the setAnnotationSet() method.

=cut

sub new {
  my $class = shift;
  my $self = bless {
    anns => [],
    index_offset_from => undef,
    }, ref($class) || $class;
  return $self;
}



=head2 add($annotation)

Add an annotation object to the annotation set.

=cut

sub add {
  my $self = shift;
  my $ann = shift;
  croak "Expected a NLP::GATE::Annotation for add, got a ",(ref $ann)  unless(ref $ann eq "NLP::GATE::Annotation");
  push @{$self->{anns}},$ann;
  return $self;
}

=head2 getByIndex($n)

Return the annotation for index $n or signal an error.

=cut

sub getByIndex {
  my $self = shift;
  my $n = shift;
  my $s =  scalar @{$self->{anns}};
  carp "Need an index for getByIndex!" unless defined($n);
  carp "Index not within range (0-$s)!" if($n < 0 || $n >= $s);
  return $self->{anns}->[$n];
}

=head2 get($type[,$featureset[,$matchtype]])

Return a new annotation set containing all the annotations from this set
that match the given type, and if specified, all the feature/value pairs given
in the $featureset hash map reference.
If no annotations match, an empty annotation set will be returned.

The parameter $matchtype specifies how features are matched: "exact" will
do an exact string comparison, "nocase" will compare after converting both
strings to lower case using perl's lc function, and "regexp" will interpret
the string given in the parameter as a regular expression. Default is "exact".

If some feature is specified in the featureset it MUST occur in the feature
set of the annotation AND satisfy the testing matchtype method of testing for
equality.

The annotations in the new set will be the same as in the original set,
so changing the annotation objects will change them in both sets!

=cut

sub get {
  my $self = shift;
  my $type = shift;
  my $features = shift;
  my $matchtype = lc(shift||"") || "exact";
  my $newset = NLP::GATE::AnnotationSet->new();
  # $type is undef, do not check type,
  # if $features is undef, do not check features
  # if both are undef, this will a new annotation set with all the
  # annotations of the original set
  foreach my $ann (@{$self->{anns}}) {
    my $cond1 = 0;
    my $cond2 = 0;
    if(!defined($type)) {
      $cond1 = 1;
    } elsif($ann->getType() eq $type) {
      $cond1 = 1;
    }
    if(!defined($features)) {
      $cond2 = 1;
    } else {
      # if we have a feature map, all features in the feature map
      # must have the same value as in the annotation
      # In other words, if one feature has a different value, the condition fails
      $cond2 = 1;
      foreach my $k (keys %$features) {
        if($matchtype eq "exact" &&
           $ann->getFeature($k) ne $features->{$k}) {
          $cond2 = 0;
          last;
        } elsif($matchtype eq "nocase" &&
                lc($ann->getFeature($k)) ne lc($features->{$k})) {
          $cond2 = 0;
          last;
        } elsif($matchtype eq "regexp" &&
                defined($ann->getFeature($k)) &&
                $ann->getFeature($k) !~ /$features->{$k}/) {
          $cond2 = 0;
          last;
        }
      }
    }
    if($cond1 && $cond2) {
      $newset->add($ann);
    }
  }
  return $newset;
}

=head2  getByOffset(from,to,type,featureset,$featurematchtype,$rangematchtype)

Return all the annotations that span the given offset range, optionally
filtering in addition by type and features.
This method requires an offset range and in addition filters annotation
as the get method does.

If from one of the parameters is undef, any value is allowed for the match
to be successful.

The parameter $featurematchtype specifies how features are matched: "exact" will
do an exact string comparison, "nocase" will compare after converting both
strings to lower case using perl's lc function, and "regexp" will interpret
the string given in the parameter as a regular expression. Default is "exact".

The $rangematchtype argument specifies how offsets will be compared, if
they are specified (case does not matter):
  "COVER" - any annotation with a from less than or equal than $from and a
     to greater than or equal than $to: annotations that contain this range
  "EXACT" - any annotation with from and to offsets exactly as specified.
     This is the default: annotations that are co-extensive with this range
  "WITHIN" - any annotation that lies fully within the range
  "OVERLAP" - any annotation that overlaps with the given range

For example to find an annotation that fully contains the text from offset
12 to offset 17, use getByOffset(12,17,undef,undef,"cover").

=cut
sub getByOffset {
  my $self = shift;
  my $from = shift;
  my $to = shift;
  my $type = shift;
  my $features = shift;
  my $featurematchtype = shift || "exact";
  $featurematchtype = lc($featurematchtype);
  my $rangematchtype = shift || "exact";
  $rangematchtype = lc($rangematchtype);
  my $newset = NLP::GATE::AnnotationSet->new();
  #print STDERR "Looking for annotation in range $from to $to\n";
  foreach my $ann (@{$self->{anns}}) {
    my $cond1 = 0;
    my $cond2 = 0;
    my $cond3 = 0;
    my $cond4 = 0;
    #print STDERR "Checking annotation ",$ann->getType(),"/",$ann->getFrom(),"/",$ann->getTo(),"\n";
    if(!defined($type)) {
      $cond1 = 1;
    } elsif($ann->getType() eq $type) {
      $cond1 = 1;
    }
    if(!defined($features)) {
      $cond2 = 1;
    } else {
      # if we have a feature map, all features in the feature map
      # must have the same value as in the annotation
      # In other words, if one feature has a different value, the condition fails
      $cond2 = 1;
      foreach my $k (keys %$features) {
        if($featurematchtype eq "exact" &&
           $ann->getFeature($k) ne $features->{$k}) {
          $cond2 = 0;
          last;
        } elsif($featurematchtype eq "nocase" &&
                lc($ann->getFeature($k)) ne lc($features->{$k})) {
          $cond2 = 0;
          last;
        } elsif($featurematchtype eq "regexp" &&
                $ann->getFeature($k) =~ /$features->{$k}/) {
          $cond2 = 0;
          last;
        }
      }
    }
    if(!defined($from)) {
      $cond3 = 1;
    } elsif($rangematchtype eq "exact" && $ann->getFrom() == $from) {
      $cond3 = 1;
    } elsif($rangematchtype eq "cover" && $ann->getFrom() <= $from) {
      $cond3 = 1;
    } elsif($rangematchtype eq "within" && $ann->getFrom() >= $from) {
      #print STDERR "From matches for ",$ann->getType(),"/",$ann->getFrom(),"/",$ann->getTo(),"\n";
      $cond3 = 1;
    }
    if(!defined($to)) {
      $cond4 = 1;
    } elsif($rangematchtype eq "exact" && $ann->getTo() == $to) {
      $cond4 = 1;
    } elsif($rangematchtype eq "cover" && $ann->getTo() >= $to) {
      $cond4 = 1;
    } elsif($rangematchtype eq "within" && $ann->getTo() <= $to) {
      #print STDERR "To matches for ",$ann->getType(),"/",$ann->getFrom(),"/",$ann->getTo(),"\n";
      $cond4 = 1;
    }
    # overlap is successful if either with have both to and from and
    # either to or from or both of the annotation are  within the given
    # range, or one of to or from is undefined
    if($rangematchtype eq "overlap" & defined($from) && defined($to)) {
      if(($ann->getTo() >= $from && $ann->getTo() <= $to) ||
         ($ann->getFrom() >= $from && $ann->getFrom() <= $to)) {
        $cond3 = 1;
        $cond4 = 1;
      }
    } elsif($rangematchtype eq "overlap" && (!defined($from) || !defined($to))) {
      $cond3 = 1;
      $cond4 = 1;
    }
    if($cond1 && $cond2 && $cond3 && $cond4) {
      $newset->add($ann);
    }
  }
  return $newset;
}


=head2 getAsArrayRef()

Return an array reference whose elements are the Annotation objects in this
set.

=cut

sub getAsArrayRef {
  my $self = shift;
  my @arr;
  foreach my $a ( @{$self->{anns}}) {
    push @arr,$a;
  }
  return \@arr;
}


=head2 getAsArray()

Return an array  whose elements are the Annotation objects in this
set.

=cut

sub getAsArray {
  my $self = shift;
  my @arr = ();
  foreach my $a ( @{$self->{anns}}) {
    push @arr,$a;
  }
  return @arr;
}


=head2 size()

Return the number of annotations in the set

=cut
sub size {
  my $self = shift;
  return scalar @{$self->{anns}};
}


=head2 getTypes()

Return an array of all different types in the set.

NOTE: this will currently go through all annotations in the set and collect the types.
No caching of type names is done in this function or during creation of the set.

=cut
sub getTypes() {
  my $self = shift;
  my $types = {};
  foreach my $ann ( $self->getAsArray() ) {
    $types->{$ann->getType()} = 1;
  }
  return keys %$types;
}

=head2 indexByOffsetFrom ()

Creates an index for the set that will speed up the retrieval of annotations
by offset or offset interval.
Unlike in GATE, this is not called automatically but must be explicitly
requested before doing the retrieval.

If an index already exist it is discarded and a new index is built.

=cut
sub indexByOffsetFrom {
  my $self = shift;
  my $indexfrom = Tree::RB->new(sub {$_[0] <=> $_[1]});
  my $indexto   = Tree::RB->new(sub {$_[0] <=> $_[1]});
  my $i = 0;
  foreach my $ann ( $self->getAsArray() ) {
    $indexfrom->put($ann->getFrom(),$i);
    $indexto->put($ann->getTo(),$i++);
  }
  $self->{index_offset_from} = $indexfrom;
  $self->{index_offset_to} = $indexto;
}


### This is only for efficiency when direct access to the internal
### representation is needed for read access only
sub _getArrayRef {
  my $self = shift;
  return $self->{anns};
}


=head1 AUTHOR

Johann Petrak, C<< <firstname.lastname-at-jpetrak-dot-com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gate-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NLP::GATE>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc NLP::GATE

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/~JOHANNP/NLP-GATE/>

=item * CPAN Ratings

L<http://cpanratings.perl.org/rate/?distribution=NLP-GATE>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=NLP-GATE>

=item * Search CPAN

L<http://search.cpan.org/~johannp/NLP-GATE/>

=back


=cut
1; # End of NLP::GATE::AnnotationSet
