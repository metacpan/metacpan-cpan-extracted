
# $Id: NT.pm,v 1.5 2009-07-04 14:29:29 Martin Exp $

=head1 NAME

RDF::Simple::Serialiser::NT - Output RDF triples in N-Triples format

=head1 SYNOPSIS

Same as L<RDF::Simple::Serialiser>,
except when you call serialise(),
you get back a string in N-Triples format.

=head1 PRIVATE METHODS

=over

=cut

package RDF::Simple::Serialiser::NT;

use strict;
use warnings;

use Data::Dumper;  # for debugging only
use Regexp::Common;
# We need the version with the new render() method:
use RDF::Simple::Serialiser 1.007;

use base 'RDF::Simple::Serialiser';

use constant DEBUG => 0;
use constant DEBUG_URIREF => 0;

our
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=item render

This method does all the N-Triples formatting.
Yes, it is named wrong;
but all other functionality is inherited from RDF::Simple::Serialiser
and that's how the author named the output function.
You won't be calling this method anyway,
you'll be calling the serialise() method, so what do you care!
In fact, I wouldn't even be telling you about it if I weren't playing the CPANTS game...

=cut

sub render
  {
  my $self = shift;
  # Required arg1 = arrayref:
  my $raObjects = shift;
  # Required arg2 = hashref of namespaces:
  my $rhNS = shift;
  my $sRet = q{};
  my %hsClassPrinted;
  my $sISA = $self->_make_uriref('rdf:type', $rhNS);
  my $sAbout = $self->_make_uriref('rdf:about', $rhNS);
 OBJECT:
  foreach my $object (@$raObjects)
    {
    DEBUG && print STDERR " DDD render object ", Dumper($object);
    # We delete elements as we process them, so that during debugging
    # we can see what's leftover:
    my $sId = delete $object->{NodeId} || q{};
    if ($sId eq q{})
      {
      # Item does not have a NodeId, use its Uri instead:
      $sId = delete $object->{Uri};
      } # if
    my $sClass = delete $object->{Class};
    DEBUG && print STDERR " DDD raw sId=$sId, sClass=$sClass\n";
    $sId = $self->_make_nodeid($sId);
    if (! $sClass)
      {
      print STDERR " EEE object has no Class: ", Dumper($object);
      next OBJECT;
      } # if
    $sClass = $self->_make_uriref($sClass, $rhNS);
    DEBUG && print STDERR " DDD cooked sId=$sId, sClass=$sClass\n";
    $sRet .= qq{$sId $sISA $sClass .\n};
    $self->{_iTriples_}++;
    if ($object->{Uri})
      {
      $sRet .= qq{$sId $sAbout <$object->{Uri}> .\n};
      $self->{_iTriples_}++;
      delete $object->{Uri};
      } # if
  LITERAL:
    foreach my $sProp (keys %{$object->{literal}})
      {
    LITERAL_PROPERTY:
      foreach my $sVal (@{$object->{literal}->{$sProp}})
        {
        $sProp = $self->_make_uriref($sProp, $rhNS);
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
        $sProp = $self->_make_uriref($sProp, $rhNS);
        $sVal = $self->_make_nodeid($sVal);
        $sRet .= qq{$sId $sProp $sVal .\n};
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
        else
          {
          $sVal = $self->_make_nodeid($sVal);
          }
        $sProp = $self->_make_uriref($sProp, $rhNS);
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


sub _make_nodeid
  {
  my $self = shift;
  # Required arg1 = an RDF nodeID to be converted:
  my $s = shift || q{};
  if ($s eq q{})
    {
    # Need to create a (random) new ID:
    } # if
  $s =~ s/\A(?!_:)/_:/;
  return $s;
  } # _make_nodeid

sub _make_uriref
  {
  my $self = shift;
  # Required arg1 = an RDF element to be converted:
  my $s = shift || q{};
  DEBUG_URIREF && print STDERR " DDD _make_uriref($s)\n";
  # Required arg2 = hashref of namespaces:
  my $rhNS = shift;
  DEBUG_URIREF && print STDERR " DDD   rhNS is ", Dumper($rhNS);
  my $sClass;
  my $sNS = 'base';
  if ($s =~ m/\A([^:]*):([^:]+)\z/)
    {
    DEBUG_URIREF && print STDERR " DDD   found ns=$1, val=$2\n";
    # Class is explicitly qualified with a "prefix:", ergo now
    # explicitly qualify it in that namespace:
    $sNS = $1 || 'base';
    $sClass = $2;
    } # if
  else
    {
    # Input string does not contain a colon.  What is it?
    return $s;
    }
  $s = qq{<$rhNS->{$sNS}$sClass>};
  return $s;
  } # _make_uriref


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

Sorry, there is no Notation3 parser for RDF::Simple.
Not yet, anyway.

=cut

=head1 AUTHOR

Martin 'Kingpin' Thurn <mthurn@cpan.org>

=head1 LICENSE

This software is released under the same license as Perl itself.

=cut

