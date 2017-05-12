package NLP::GATE::Annotation;

use warnings;
use strict;
use Carp;

=head1 NAME

NLP::GATE::Annotation - A class for representing GATE-like annotations

=head1 VERSION

Version 0.6

=cut

our $VERSION = '0.6';

=head1 SYNOPSIS

  use NLP::GATE::Annotation;
  my $ann = NLP::GATE::Annotation->new($type,$fromOffset,$toOffset);
  my $copy = $ann->clone();
  $ann->setFromTo($fromOffset,$toOffset);
  $ann->setType($type);
  $ann->setFeature($name,$value);
  $ann->setFeatureType($name,$type);
  $value = $ann->getFeature($name);
  $type = $ann->getFeatureType($name);
  $from = $ann->getFrom();
  $to = $ann->getTo();

=head1 DESCRIPTION

This is a simple class representing a GATE-like annotation for
document text. The annotation knows about the text offsets from
start (first character has offset 0) to end (the offset of the
byte following the annotation).
Zero length annotations should be avoided as gate cannot handle
them properly.

All functions that set values return the original
annotation object.

This library does not attempt to mirror the Java API or the way how
annotations are represented and handled in the original GATE API.

A major difference to the GATE API is that annotations can live
completely independent from annotation sets or documents and have their
own constructor. An annotation is simply a range that is assiciated
with a type and a map of features.

Another difference to the GATE API is that feature maps are NOT
seperately modeled.


=head1 METHODS

=head2 new()

Create a new annotation.

=cut

sub new {
  my $class = shift;
  my $type = shift;
  if(!defined($type)) {
    croak "Must specify a type when creating an annotation";
  }
  my $fromOffset = shift;
  if(!defined($fromOffset)) {
    croak "Must specify from offset when creating an annotation";
  }
  my $toOffset = shift;
  if(!defined($toOffset)) {
    croak "Must specify to offset when creating an annotation";
  }
  my $featurehashref = shift;
  my $self = bless {
    type => $type,
    fromOffset => $fromOffset,
    toOffset => $toOffset,
    features => {},
    featuretypes => {},
    }, ref($class) || $class;
  foreach my $key ( keys %$featurehashref) {
    $self->setFeature($key,$featurehashref->{$key});
  }
  return $self;
}


=head2 clone()

Create a deep copy of an annotation, creating a new annotation object
that has the same values as the old one, but contains no references to
data contained in the old one.

=cut

sub clone {
  my $self = shift;
  my $new = NLP::GATE::Annotation->new($self->getType(),$self->getFrom(),$self->getTo());
  foreach my $name ( keys %{$self->{features}} ) {
    $new->setFeature($name,$self->{features}->{$name});
    $new->setFeatureType($name,$self->{featuretypes}->{$name} || "java.lang.String");
  }
  return $new;
}

=head2 setType($type)

Set a new annotation type. Must be a string and a valid type name.

=cut

sub setType {
  my $self = shift;
  my $type = shift;
  $self->{type} = $type;
  return $self;
}

=head2 getType()

Return the current annotation type.

=cut

sub getType {
  my $self = shift;
  return $self->{type};
}

=head2 setFromTo($fromOffset,$toOffset)

Set the text range of the annotation.

=cut

sub setFromTo {
  my $self = shift;
  my $from= shift;
  my $to = shift;
  $self->{fromOffset} = $from;
  $self->{toOffset} = $to;
  return $self;
}



=head2 setFeature($name,$value)

Add or replace the feature of the given name with the new
value.

=cut

sub setFeature {
  my $self = shift;
  my $name = shift;
  # TODO: check that name is a valid string: what is a valid name string?
  my $value = shift;
  my $new = 1 if(!defined($self->{features}->{$name}));
  $self->{features}->{$name} = $value;
  $self->setFeatureType($name,"java.lang.String") if($new);
  return $self;
}


=head2 setFeatureType($name,$type)

Add or replace the Java type associated with the feature.
If this method is never used, the default for a feature is java.lang.String.

=cut

sub setFeatureType {
  my $self = shift;
  my $name = shift;
  my $type = shift;
  croak "Cannot set a type for a nonexisting feature" if(!defined($self->{features}->{$name}));
  $self->{featuretypes}->{$name} = $type;
}


=head2 getFeatureType($name)

Return the Java type associated with the feature.
If the type was never set, "java.lang.String" is returned.
If no value is set for the feature, undef is returned.

=cut

sub getFeatureType {
  my $self = shift;
  my $name = shift;
  return undef unless $self->{features}->{$name};
  return $self->{featuretypes}->{$name} || "java.lang.String";
}


=head2 getFeatureNames()

Return an array of feature names for this annotation.
The order of feature names in the array is random and may change between
successive calls.

=cut
sub getFeatureNames() {
  my $self = shift;
  return keys %{$self->{features}};
}


=head2 setFeatures($hashref)

Add or replace all the features with the keys in the hash reference with
the corresponding values in the hash reference.

=cut

sub setFeatures {
  my $self = shift;
  my $features = shift;
  foreach my $k (keys %$features) {
    $self->setFeature($k,$features->{$k});
  }
  return $self;
}


=head2 getFeature($name)

Returns the value of the feature.

=cut

sub getFeature {
  my $self = shift;
  my $name = shift;
  return $self->{features}->{$name};
}

=head2 getFrom()

Returns the from offset.

=cut

sub getFrom {
  my $self = shift;
  return $self->{fromOffset};
}

=head2 getTo()

Returns the to offset.

=cut

sub getTo {
  my $self = shift;
  return $self->{toOffset};
}



sub _getFeatures {
  my $self = shift;
  return $self->{features};
}

sub _getFeatureTypes {
  my $self = shift;
  return $self->{featuretypes};
}

sub _getFeaturesString {
  my $self = shift;
  my $f = $self->_getFeatures();
  my @tmp = map { $_."=".$f->{$_}  } keys %{$f};
  return join(", ",@tmp);
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
1; # End of NLP::GATE::Annotation
