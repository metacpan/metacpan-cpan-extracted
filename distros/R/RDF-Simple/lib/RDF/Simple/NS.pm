package RDF::Simple::NS;

use strict;

our
$VERSION = 1.41;

sub new {
        my $class = shift;
        my %p = @_;
        return bless \%p, ref $class || $class;
}

sub baseuri {
        my $self = shift;
        my $baseuri = shift;
        $self->{baseuri} ||= $baseuri;
        return $self->{baseuri};
}

sub from_qname {
    my ($self,$name) = @_;
    my $ns;
    if (($name =~ m/\:/) and ($name !~ m/^http/))  {
        my ($space,$n) = split(/:/,$name);
        $ns = $self->entity_to_namespace($space);
        $name = $n;
    }
    $ns ||= $self->baseuri;
    return $ns.$name;
}

sub qname {
    my ($self,$thing) = @_;
    my ($ns,$part) = $thing =~ /(.+[\/|\#])(.+)/;

    my $entity = $self->namespace_to_entity($ns);
    $thing = $entity.':'.$part if $entity;
    return $thing;
}

# Retrieve or add to the entity to namespace lookup hash
sub lookup
  {
  my $self = shift;
  my %add;
  if (ref $_[0] eq 'HASH')
    {
    %add = %{$_[0]};
    }
  else
    {
    %add = @_;
    }
  $self->{_lookup} ||=
    {
     foaf => 'http://xmlns.com/foaf/0.1/',
     dc => 'http://purl.org/dc/elements/1.1/',
     rdfs => "http://www.w3.org/2000/01/rdf-schema#",
     daml => 'http://www.w3.org/2001/10/daml+oil#',
     space => 'http://frot.org/space/0.1/',
     geo => 'http://www.w3.org/2003/01/geo/wgs84_pos#',
     rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
     owl => 'http://www.w3.org/2002/07/owl#',
     ical => 'http://www.w3.org/2002/12/cal/ical#',
     dcterms=>"http://purl.org/dc/terms/",
     wiki=>"http://purl.org/rss/1.0/modules/wiki/",
     chefmoz=>"http://chefmoz.org/rdf/elements/1.0/",
     wot => "http://xmlns.com/wot/0.1/",
     cng => 'http://iconocla.st/cng#',
     status => 'http://www.w3.org/2003/06/sw-vocab-status/ns#',
    };
  foreach (keys %add)
    {
    $self->{_lookup}->{$_} = $add{$_};
    } # foreach
  return %{$self->{_lookup}};
  } # lookup

sub entity_to_namespace {
    my ($self,$entity) = @_;
    my %lookup = $self->lookup;
    my $e = $lookup{$entity};
    return $e;
}

sub uri {
    my ($self,$entity) = @_;
    if ($entity =~ m/\:/) {
        return $self->from_qname($entity);
    }
    else {
        return $self->entity_to_namespace($entity);
    }
}

sub namespace_to_entity {
    my ($self,$ns) = @_;
    #$ns =~ s/\#//g;
    my %look = reverse $self->lookup;
    return $look{$ns} if $ns and (exists $look{$ns});
}

sub prefix {
    my ($self,$string) = @_;
    if ($string) {
    	$string =~ s/:.+//;
    	return $string if $string;
    }
    return undef;
} # prefix

1;

=head1 RDF::Simple::NS

=head1 DESCRIPTION

A utility class to help deal with RDF namespaces
(converting between short (qualified) names
and full URLs for XML namespaces.

=head1 SYNOPSIS

	my $ns = RDF::Simple::NS->new;
	$ns->lookup('foaf'=>'http://xmlns.com/foaf/0.1/');

=head2 METHODS

=head3 from_qname

=head3 qname

=head3 lookup

  $ns->lookup('short name'=>'http://full.path.to/namespace#');

Add an alias for a namespace (this will be used in the serialisation)

=head3 entity_to_namespace

=head3 uri

=head3 namespace_to_entity

=head3 prefix
