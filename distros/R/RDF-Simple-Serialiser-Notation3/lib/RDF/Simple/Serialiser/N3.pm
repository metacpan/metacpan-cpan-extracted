
# $Id: N3.pm,v 1.17 2009-07-04 14:28:18 Martin Exp $

=head1 NAME

RDF::Simple::Serialiser::N3 - Output RDF triples in Notation3 format

=head1 SYNOPSIS

Same as L<RDF::Simple::Serialiser>,
except when you call serialise(),
you get back a string in Notation3 format.

=head1 PRIVATE METHODS

=over

=cut

package RDF::Simple::Serialiser::N3;

use strict;
use warnings;

use Data::Dumper;  # for debugging only
use Regexp::Common;
# We need the version with the new render() method:
use RDF::Simple::Serialiser 1.007;

use base 'RDF::Simple::Serialiser';

our
$VERSION = do { my @r = (q$Revision: 1.17 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use constant DEBUG => 0;

=item render

This method does all the Notation3 formatting.
You should not be calling this method,
you should be calling the serialise() method.

=cut

sub render
  {
  my $self = shift;
  # Required arg1 = arrayref:
  my $raObjects = shift;
  # Required arg2 = hashref of namespaces:
  my $rhNS = shift;
  my $sRet = q{};
  foreach my $sNS (keys %$rhNS)
    {
    if (defined $rhNS->{$sNS} && ($rhNS->{$sNS}ne q{}))
      {
      $sRet .= qq"\@prefix $sNS: <$rhNS->{$sNS}> .\n";
      $self->{_iTriples_}++;
      } # if
    } # foreach
  $sRet .= qq{\n};
  my %hsClassPrinted;
 OBJECT:
  foreach my $object (@$raObjects)
    {
    DEBUG && print STDERR " DDD   in render(), object is ", Dumper($object);
    # We delete elements as we process them, so that during debugging
    # we can see what's leftover:
    my $sId = delete $object->{NodeId} || q{};
    if ($sId ne q{})
      {
      $sId = qq{:$sId};
      }
    else
      {
      $sId = delete $object->{Uri};
      }
    my $sClass = delete $object->{Class};
    if (! $sClass)
      {
      print STDERR " EEE object has no Class: ", Dumper($object);
      next OBJECT;
      } # if
    if ($sClass !~ m/[^:]+:[^:]+/)
      {
      # Class is not explicitly qualified with a "prefix:", ergo now
      # explicitly qualify in the default namespace:
      $sClass = qq{:$sClass};
      if (! $hsClassPrinted{$sClass})
        {
        $sRet .= qq{$sClass a owl:Class .\n\n};
        $self->{_iTriples_}++;
        $hsClassPrinted{$sClass}++;
        } # if
      } # if
    $sRet .= qq{$sId a $sClass .\n};
    $self->{_iTriples_}++;
    if ($object->{Uri})
      {
      $sRet .= qq{$sId rdf:about <$object->{Uri}> .\n};
      $self->{_iTriples_}++;
      delete $object->{Uri};
      } # if
  LITERAL:
    foreach my $sProp (keys %{$object->{literal}})
      {
    LITERAL_PROPERTY:
      foreach my $sVal (@{$object->{literal}->{$sProp}})
        {
        if ($sVal !~ m/\A$RE{num}{decimal}\z/)
          {
          # Value is non-numeric; assume it's a string and put quotes
          # around it:
          $sVal = qq{"$sVal"};
          } # if
        $sRet .= qq{$sId $sProp $sVal .\n};
        $self->{_iTriples_}++;
        } # foreach LITERAL_PROPERTY
      } # foreach LITERAL
    delete $object->{literal};
  NODEID:
    foreach my $sProp (keys %{$object->{nodeid}})
      {
    NODEID_PROPERTY:
      foreach my $sVal (@{$object->{nodeid}->{$sProp}})
        {
        $sRet .= qq{$sId $sProp :$sVal .\n};
        $self->{_iTriples_}++;
        } # foreach NODEID_PROPERTY
      } # foreach NODEID
    delete $object->{nodeid};
  RESOURCE:
    foreach my $sProp (keys %{$object->{resource}})
      {
    RESOURCE_PROPERTY:
      foreach my $sVal (@{$object->{resource}->{$sProp}})
        {
        if ($self->_looks_like_uri($sVal))
          {
          $sVal = qq{<$sVal>};
          } # if
        $sRet .= qq{$sId $sProp $sVal .\n};
        $self->{_iTriples_}++;
        } # foreach RESOURCE_PROPERTY
      } # foreach RESOURCE
    delete $object->{resource};
    print STDERR Dumper($object) if keys %$object;
    $sRet .= qq{\n};
    } # foreach OBJECT
  return $sRet;
  } # render


=back

=head1 PUBLIC METHODS

=over

=item get_triple_count

Returns the number of triples created since the last call to
reset_triple_count().

=cut

sub get_triple_count
  {
  my $self = shift;
  return $self->{_iTriples_};
  } # get_triple_count


=item reset_triple_count

Resets the internal counter of triples to zero.

=cut

sub reset_triple_count
  {
  my $self = shift;
  $self->{_iTriples_} = 0;
  } # get_triple_count

1;

__END__

=back

=head1 NOTES

This module tries to automatically detect when the value of a property is a string
(as opposed to numeric)
and add double-quotes around it.
This is probably not perfect, so please contact the author if you find a bug,
or if you need a smarter way of handling value types.

Sorry, there is no Notation3 parser for RDF::Simple.
Not yet, anyway.

=cut

=head1 BUGS

Please use the website 
L<http://rt.cpan.org|http://rt.cpan.org/Ticket/Create.html?Queue=RDF-Simple-Serialiser-Notation3>
to report bugs and request new features.

=head1 AUTHOR

Martin Thurn <mthurn@cpan.org>

=head1 LICENSE

This software is released under the same license as Perl itself.

=cut

