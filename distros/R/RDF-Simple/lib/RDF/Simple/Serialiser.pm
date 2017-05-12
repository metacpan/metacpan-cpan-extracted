
# $Id: Serialiser.pm,v 1.12 2009-07-04 14:55:24 Martin Exp $

package RDF::Simple::Serialiser;

use strict;

use constant DEBUG => 0;

=head1 NAME

RDF::Simple::Serialiser - convert a list of triples to RDF

=head1 DESCRIPTION

A simple RDF serialiser.
Accepts an array of triples, returns a serialised RDF document.

=head1 SYNOPSIS

  my $ser = RDF::Simple::Serialiser->new(
    # OPTIONAL: Supply your own bNode id prefix:
    nodeid_prefix => 'a:',
    );
  # OPTIONAL: Add your namespaces:
  $ser->addns(
              foaf => 'http://xmlns.com/foaf/0.1/',
             );
  my $node1 = $ser->genid;
  my $node2 = $ser->genid;
  my @triples = (
                 ['http://example.com/url#', 'dc:creator', 'zool@example.com'],
                 ['http://example.com/url#', 'foaf:Topic', '_id:1234'],
                 ['_id:1234','http://www.w3.org/2003/01/geo/wgs84_pos#lat','51.334422']
                 [$node1, 'foaf:name', 'Jo Walsh'],
                 [$node1, 'foaf:knows', $node2],
                 [$node2, 'foaf:name', 'Robin Berjon'],
                 [$node1, 'rdf:type', 'foaf:Person'],
                 [$node2, 'rdf:type','http://xmlns.com/foaf/0.1/Person']
                 [$node2, 'foaf:url', \'http://server.com/NOT/an/rdf/uri.html'],
                );
  my $rdf = $ser->serialise(@triples);

  ## Round-trip example:
  my $parser = RDF::Simple::Parser->new();
  my $rdf = LWP::Simple::get('http://www.zooleika.org.uk/foaf.rdf');
  my @triples = $parser->parse_rdf($rdf);
  my $new_rdf = $serialiser->serialise(@triples);


=head1 METHODS

=over

=cut

use Data::Dumper;
use RDF::Simple::NS;
use Regexp::Common qw(URI);
use Class::MakeMethods::Standard::Hash (
                                        new => 'new',
                                        scalar => [ qw( baseuri path nodeid_prefix qqq ) ],
                                       );

our
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=item new()

=item new(nodeid_prefix => 'prefix')

=cut

=item serialise( @triples )

Accepts a 'bucket of triples'
(an array of array references which are [subject, predicate, object] statements)
and returns a serialised RDF document.

If 'rdf:type' is not provided for a subject,
the generic node type 'rdf:Description' is used.

=cut

sub serialise
  {
  my ($self,@triples) = @_;
  my %object_ids;
  foreach (@triples)
    {
    push @{$object_ids{$_->[0]}}, $_;
    } # foreach
  my @objects;
  foreach my $k (keys %object_ids)
    {
    push @objects, $self->_make_object(@{$object_ids{$k}});
    } # foreach
  my %ns_lookup = $self->_ns->lookup;
  my %ns = ();
  my $used = $self->_used;
  foreach (keys %$used)
    {
    $ns{$_} = $ns_lookup{$_};
    } # foreach
  my $xml = $self->render(\@objects, \%ns);
  return $xml;
  } # serialise


=item serialize

A synonym for serialise() for American users.

=cut

sub serialize
  {
  my $self = shift;
  return $self->serialise(@_);
  } # serialize

# _make_object() is called on each subset of triples that have the
# same subject.

sub _make_object
  {
  my $self = shift;
  # Make a copy of our array-ref arguments, so we can modify them
  # locally:
  my @triples;
  foreach my $ra (@_)
    {
    push @triples, [@$ra];
    } # foreach
  # DEBUG && print STDERR " DDD in _make_object(), triples is ", Dumper(\@triples);
  my $object;
  my $rdf = $self->_ns;
  # Convert the predicate of each triple into a legal qname:
  @triples = map {$_->[1] = $rdf->qname($_->[1]); $_} @triples;
  # Find the type declaration of this subject (assume there is only one):
  my ($class) = grep {$_->[1] eq 'rdf:type'} @triples;
  # DEBUG && print STDERR " DDD in _make_object(), class is ", Dumper($class);
  foreach my $t (@triples)
    {
    # Register the namespace of (all) the predicates:
    $self->_used($t->[1]);
    my $qn = $rdf->qname($t->[0]);
    if ($qn ne $t->[0])
      {
      # Register the namespace of (all) the subject(s):
      $self->_used($qn);
      } # if
    } # foreach
  # $self->_used('rdf:Description');
  if ($class)
    {
    # This bag of triples has a Class explicitly declared:
    $object->{Class} = $rdf->qname($class->[2]);
    }
  else
    {
    # This bag of triples needs a generic Description Class:
    $object->{Class} = 'rdf:Description';
    }
  # Register the namespace of this subject's Class:
  $self->_used($object->{Class});
  # Assign identifier as an arbitrary (but resolving) uri:
  my $id = $triples[0]->[0];
  if (
      $self->_looks_like_uri($id)
      ||
      $self->_looks_like_legal_id($id)
      ||
      (($id =~ m/^[#:]/) && $self->_looks_like_legal_id(substr($id,1)))
     )
    {
    $object->{Uri} = $id;
    } # if
  else
    {
    # Delete non-alphanumeric characters:
    $id =~ s/\W//g;
    $object->{NodeId} = $id;
    }
  my $pref = $self->nodeid_prefix || '_id:';
 STATEMENT:
  foreach my $statement (@triples)
    {
    next if $statement->[1] eq 'rdf:type';
    my $obj = $statement->[2];
    DEBUG && print STDERR " DDD   start processing object($obj)\n";
    if (ref $obj)
      {
      # Special case: insert this value as a string, no matter what it
      # looks like:
      push @{ $object->{literal}->{$statement->[1]} }, ${$obj};
      }
    elsif ($obj =~ m/^$pref/)
      {
      $statement->[2] =~ s/\A[^a-zA-Z]/a/;
      $statement->[2] =~ s/\W//g;
      push @{ $object->{nodeid}->{$statement->[1]} }, $obj;
      } # if
    elsif (
           $self->_looks_like_uri($obj)
           ||
           $self->_looks_like_legal_id($obj)
           ||
           (
            ($obj =~ m/^[#:]/)
            &&
            $self->_looks_like_legal_id(substr($obj, 1))
           )
          )
      {
      push @{ $object->{resource}->{$statement->[1]} }, $obj;
      }
    else
      {
      push @{ $object->{literal}->{$statement->[1]} }, $obj;
      }
    } # foreach
  return $object;
  } # _make_object


sub _looks_like_uri
  {
  my $self = shift;
  my $s = shift || '';
  return (
          ($s =~ m/$RE{URI}/)
          &&
          # The URI we're interested in are specifically those URI
          # that can refer to an element of an ontology; these always
          # look like namespace#name
          ($s =~ m/.#./)
         );
  } # _looks_like_uri

sub _looks_like_legal_id
  {
  my $self = shift;
  my $s = shift || '';
  return (
          # Starts with alphanumeric:
          ($s =~ m/\A\w/)
          &&
          # Only consists of alphanumerics plus a few punctuations.
          # I'm not sure what the correct set of characters is, even
          # after reading the RDF specification (it only refers to
          # full URIs):
          ($s =~ m/\A[-:_a-z0-9]+\z/)
         );
  } # _looks_like_legal_id


=item addns( qname  => 'http://example.com/rdf/vocabulary#',
             qname2 => 'http://yetanother.org/vocabulary/' )


Use this method to add new namespaces to the RDF document.
The RDF::Simple::NS module
provides the following vocabularies by default
(you can override them if you wish):

  foaf    => 'http://xmlns.com/foaf/0.1/',
  dc      => 'http://purl.org/dc/elements/1.1/',
  rdfs    => 'http://www.w3.org/2000/01/rdf-schema#',
  daml    => 'http://www.w3.org/2001/10/daml+oil#',
  space   => 'http://frot.org/space/0.1/',
  geo     => 'http://www.w3.org/2003/01/geo/wgs84_pos#',
  rdf     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  owl     => 'http://www.w3.org/2002/07/owl#',
  ical    => 'http://www.w3.org/2002/12/cal/ical#',
  dcterms => 'http://purl.org/dc/terms/',
  wiki    => 'http://purl.org/rss/1.0/modules/wiki/',
  chefmoz => 'http://chefmoz.org/rdf/elements/1.0/',

=cut

sub addns
  {
  my $self = shift;
  my %p;
  if (ref $_[0] eq 'HASH')
    {
    %p = %{$_[0]};
    }
  else
    {
    %p = @_;
    }
  return $self->_ns->lookup(%p);
  } # addns


=item genid( )

generates a random identifier for use as a bNode
(anonymous node) nodeID.
if nodeid_prefix is set, the generated id uses the prefix,
followed by 8 random numbers.

=cut

sub genid
  {
  my $self = shift;
  my $prefix = $self->nodeid_prefix || '_id:';
  my @num = (0..9);
  my $string = join '', (map { @num[rand @num] } 0..7);
  return $prefix.$string;
  } # genid

sub _ns
  {
  my $self = shift;
  return $self->{_rdfns} if $self->{_rdfns};
  $self->{_rdfns} = RDF::Simple::NS->new;
  } # _ns

sub _used
  {
  my ($self, $uri) = @_;
  if (defined $uri and ($uri !~ m/^http/)) {	
    my $pref = $self->_ns->prefix($uri);
    $self->{_used_entities}->{ $pref } = 1 if $pref;
    }
  return $self->{_used_entities};
  } # _used


=item render

Does the heavy lifting of converting the "objects" to a string.
Users of this module should call serialize();
Subclassers of this module will probably rewrite render().

=cut

sub render
  {
  my ($self, $objects, $ns) = @_;
  my $xml = "<rdf:RDF\n";
 NS:
  foreach my $n (keys %$ns)
    {
    $xml .= 'xmlns:'.$n.'="'.$ns->{$n}."\"\n";
    } # foreach NS
  $xml .= ">\n";
 OBJECT:
  foreach my $object (@$objects)
    {
    $xml .= '<'.$object->{Class};
    if ($object->{Uri})
      {
      $xml .= ' rdf:about="'.$object->{Uri}.'"';
      }	# if
    else
      {
      $xml .= ' rdf:nodeID="'.$object->{NodeId}.'"';
      }
    $xml .= ">\n";
 LITERAL:
    foreach my $l (keys %{$object->{literal}})
      {
 LITERAL_PROP:
      foreach my $prop (@{$object->{literal}->{$l}})
        {
        $prop = _xml_escape($prop);
        $xml .= qq{<$l>$prop</$l>\n};
        } # foreach LITERAL_PROP
      } # foreach LITERAL
 RESOURCE:
    foreach my $l (keys %{$object->{resource}})
      {
 RESOURCE_PROP:
      foreach my $prop (@{$object->{resource}->{$l}})
        {
        $xml .= qq{<$l rdf:resource="$prop"/>\n};
        } # foreach RESOURCE_PROP
      } # foreach RESOURCE
 NODEID:
    foreach my $l (keys %{$object->{nodeid}})
      {
 NODEID_PROP:
      foreach my $prop (@{$object->{nodeid}->{$l}})
        {
        $xml .= qq{<$l rdf:nodeID="$prop"/>\n};
        } # foreach NODEID_PROP
      } # foreach NODEID
    $xml .= '</'. $object->{Class} .">\n";
    } # foreach OBJECT
  $xml .= "</rdf:RDF>\n";
  return $xml;
  } # render


sub _xml_escape
  {
  my $s = shift || '';
  # Make safe for XML:
  my %escape = (
                q'<' => q'&lt;',
                q'>' => q'&gt;',
                q'&' => q'&amp;', # ', # Emacs bug
                q'"' => q'&quot;',
               );
  my $escape_re  = join(q'|', keys %escape);
  $s =~ s/($escape_re)/$escape{$1}/g;
  return $s;
  } # _xml_escape

=back

=head1 BUGS

Please report bugs via the RT web site L<http://rt.cpan.org/Ticket/Create.html?Queue=RDF-Simple>

=head1 NOTES

The original author was British, so this is a Serialiser.
For American programmers,
RDF::Simple::Serializer will work as an alias to the module,
and serialize() does the same as serialise().

The distinction between a URI and a literal string
in the "object" (third element) of each triple
is made as follows:
if the object is a reference, it is output as a literal;
if the object "looks like" a URI
(according to Regexp::Common::URI),
it is output as a URI.


=head1 THANKS

Thanks particularly to Tom Hukins, and also to Paul Mison, for providing patches.

=head1 AUTHOR

Originally written by Jo Walsh (formerly <jo@london.pm.org>).
Currently maintained by Martin Thurn <mthurn@cpan.org>.

=head1 LICENSE

This module is available under the same terms as perl itself.

=cut

1;

__END__
