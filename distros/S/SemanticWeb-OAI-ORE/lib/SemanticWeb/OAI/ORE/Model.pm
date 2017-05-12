package SemanticWeb::OAI::ORE::Model;
#$Id: Model.pm,v 1.16 2010-12-06 14:44:15 simeon Exp $

=head1 NAME

SemanticWeb::OAI::ORE::Model - Module for model component of an OAI-ORE Resource Map

=head1 SYNOPSIS

In essence, the model is simply a set of triples and we thus store them in
a triple store provided by L<RDF::Core::Model>, L<RDF::Core::Storage> etc..

=cut

use strict;
use warnings;
use Carp qw(croak carp);

use SemanticWeb::OAI::ORE::Constant qw(:all);
use SemanticWeb::OAI::ORE::N3;

use RDF::Core::Model;
use RDF::Core::Model::Serializer;
use RDF::Core::Storage;
use RDF::Core::Storage::Memory;
use RDF::Core::Resource;
use RDF::Core::Literal;
use RDF::Core::Statement;
use Class::Accessor;

use base qw(Class::Accessor RDF::Core::Model);
SemanticWeb::OAI::ORE::Model->mk_accessors(qw(die_level));

=head1 METHODS

=head2 CREATION AND MODIFICATION

=head3 SemanticWeb::OAI::ORE::Model->new(%args) or SemanticWeb::OAI::ORE::Model->new($rdf_model)

Create new relationships object as part of a resource map.

If supplied with a single argument that is a L<RDF::Core::Model> then that
object is blessed into this class an returned. Otherwise a new  
L<RDF::Core::Model> object is created and any %args are passed to the 
creator.

=cut

sub new {
  my $class=shift;
  my $self;
  if (ref($_[0]) and $_[0]->isa('RDF::Core::Model')) {
    $self=$_[0];
  } else {
    $self=RDF::Core::Model->new(Storage=>RDF::Core::Storage::Memory->new(),@_);
  }
  bless $self, $class;
  $self->die_level(FATAL);
  return($self);
}


=head3 $model->add($model_or_statement)

Add either another model object or a single statement to this $model.
Returns the number of statements added.

=cut

sub add {
  my $self=shift;
  my $count=0;
  foreach my $to_add (@_) {
    if ($to_add->isa('RDF::Core::Model')) {
      my $enum=$to_add->getStmts(undef,undef,undef);
      my $statement=$enum->getFirst();
      while ($statement) {
        $self->addStmt($statement);
        $count++;
        $statement=$enum->getNext();
      }
      $enum->close();
    } elsif ($to_add->isa('RDF::Core::Statement')) {
      $self->addStmt($to_add);
      $count++;
    } else {
      die "Don't know how to add a ".ref($to_add)." to the Model";
    }
  }
  return($count);
}


=head3 $model->add_rel_to_resource($subject,$predicate,$object)

Add relationship where the object is a resource (URI).

=cut

sub add_rel_to_resource {
  my $self=shift;
  my ($subject,$predicate,$object)=@_;
  $subject=RDF::Core::Resource->new($subject);
  $predicate=RDF::Core::Resource->new($predicate);
  $object=RDF::Core::Resource->new($object);
  $self->addStmt(RDF::Core::Statement->new($subject,$predicate,$object));
}


=head3 $model->add_rel_to_literal($subject,$predicate,$object)

Add relationship where the object is a literal.

=cut

sub add_rel_to_literal {
  my $self=shift;
  my ($subject,$predicate,$object)=@_;
  $subject=RDF::Core::Resource->new($subject);
  $predicate=RDF::Core::Resource->new($predicate);
  $object=RDF::Core::Literal->new($object);
  $self->addStmt(RDF::Core::Statement->new($subject,$predicate,$object));
}


=head3 $model->count()

Returns the number of statements or relationships.

=cut

sub count {
  my $self=shift;
  return($self->countStmts(undef,undef,undef));
}


=head3 $model->as_array()

Return an array reference to all triples each as a four element array with
[subject, predicate, object, object_is_literal] for each statement.

FIXME - should perhaps implement iterator or similar...

=cut

sub as_array {
  my $self=shift;
  my $enum=$self->getStmts(undef,undef,undef);
  my $statement=$enum->getFirst();
  my @triples=();
  while ($statement) {
    push(@triples,[$statement->getSubject()->getLabel(),
                   $statement->getPredicate()->getLabel(),
                   $statement->getObject()->getLabel(),
                   $statement->getObject()->isLiteral()]);
    $statement=$enum->getNext();
  }
  return(\@triples);
}


=head3 $model->objects_matching($subject,$predicate,$only)

Return an array of objects from triples where the subject and predicate 
are as specified. Will return an empty array if there are no matches.

If $only is not specified then the objects matching will be returned.

If $only is RESOURCE then only resource labels will be included, if 
LITERAL then only literal labels will be returned.

=cut

sub objects_matching {
  my $self=shift;
  my ($subject,$predicate,$only)=@_;

  if (not defined($subject)) {
    #empty list
    return([]);
  } elsif (not ref($subject)) {
    $subject=RDF::Core::Resource->new($subject);
  }
  if (not defined($predicate)) {
    #leave undef so we match any
  } elsif (not ref($predicate)) {
    $predicate=expand_qname($predicate);
    $predicate=RDF::Core::Resource->new($predicate);
  }

  my $enum=$self->getStmts($subject,$predicate,undef);
  my $statement=$enum->getFirst();
  my @matching=();
  while ($statement) {
    my $obj=$statement->getObject();
    if ($only) {
      if ($only==RESOURCE) {
        next if ($obj->isLiteral());
      } elsif ($only==LITERAL) {
        next if (not $obj->isLiteral());
      } 
      push(@matching,$obj->getLabel());
    } else {
      push(@matching,$obj);
    }
    $statement=$enum->getNext();
  }
  return(@matching);
}



=head3 $model->literal_matching($subject,$predicate)

Wrapper around objects_matching to get the first literal matching the
specified condition, else retursn undef. Ignores any other matches.

=cut

sub literal_matching {
  my $self=shift;
  my ($subject,$predicate)=@_;
  my @objects=$self->objects_matching($subject,$predicate,LITERAL);
  return(@objects ? $objects[0] : undef );
}



# Return URI or literal based on whether string looks like a URI
#
sub __uri_or_literal {
  my ($str)=@_;
  my $ul;
  if ($str=~/^[a-z]+:\S+$/) {
    $ul=RDF::Core::Resource->new($str);
  } else {
    $ul=RDF::Core::Literal->new($str);
  }
  return($ul);
}


=head2 VALIDATION

=head3 $model->check_model($uri_rem,$rem)

Take an RDF model of type RDF::Core::Model in $self and a Resource
Map URI $uri_rem. Attempt to parse/interpret it as a resource map. Will 
croak if parsing fails so usual call would be to wrap in an eval:

  eval {
    $model->check_model($uri_rem,$rem);
  };
  if ($@) {
    # oops
  }

If $rem is supplied then this is expected to be a SemanticWeb::OAI::ORE::ReM object
with methods uri(), aggregation(), creator() and 
timestamp_as_iso8601() which are used to set these values for easy reference.

The requirements are based mainly on the table given in 
L<http://www.openarchives.org/ore/1.0/datamodel#Constraints>.

=cut

sub check_model {
  my $self=shift;
  my ($uri_rem,$rem)=@_;

  my $resource_map=RDF::Core::Resource->new(RESOURCE_MAP);
  my $aggregation=RDF::Core::Resource->new(AGGREGATION);
  my $has_type=RDF::Core::Resource->new(HAS_TYPE);
  my $describes=RDF::Core::Resource->new(DESCRIBES);
  my $aggregates=RDF::Core::Resource->new(AGGREGATES);

  # First, work out what the Resource Map URI (URI-R) is
  {
    my $statement=undef;
    my $uri=undef;
    my $cnt=$self->countStmts(undef,$has_type,$resource_map);
    if ($cnt==0) {
      $self->err(FATAL,"No resource map node defined as such and not URI-R supplied") if (not defined $uri_rem);
      #if FATAL turned off or $uri_rem supplied then just assume $uri_rem as given
      $self->err(WARN,"Using supplied URI-R ($uri_rem) as resource map URI") if (defined $uri_rem);
      $uri=$uri_rem;
    } elsif ($cnt==1) {
      my $enum=$self->getStmts(undef,$has_type,$resource_map);
      $statement=$enum->getFirst;
      $enum->close();
      $uri=$statement->getSubject->getURI;
    } else {
      # more than one match, can't handle that yet so barf.
      # can probably work it out by looking for an AGGREGATES arc from the same Subject
      $self->err(FATAL,"Got $cnt candidates for resourceMap node");
      return(0); #if FATAL turned off
    }
    # Only get here if we found $statement and extracted $uri
    if (defined $rem) {
      $rem->uri($uri);
    }
    if (defined $uri_rem and $uri_rem ne $uri) {
      $self->err(WARN,"URI for ReM supplied ($uri_rem) but does not match that inside object ($uri)");
    }  
    $uri_rem=$uri;
  }

  # Second, work out what the Aggregation URI (URI-A) is. First look for a DESCRIBES
  # predicate, look for a node typed as an aggregation if that fails.
  my $uri_agg=undef;
  {
    my $statement=undef;
    my $rem_resource=RDF::Core::Resource->new($uri_rem);
    my $cnt=$self->countStmts($rem_resource,$describes,undef);
    if ($cnt==1) {
      my $enum=$self->getStmts($rem_resource,$describes,undef);
      $statement=$enum->getFirst();
      $enum->close();
      $uri_agg=$statement->getObject()->getURI();
    } elsif ($cnt==0) {
      # Any describes statement..    
      my $cnt=$self->countStmts(undef,$describes,undef);
      if ($cnt==1) {
        my $enum=$self->getStmts(undef,$describes,undef);
        $statement=$enum->getFirst();
        $enum->close();
        $uri_agg=$statement->getObject()->getURI();
      }
    }
    # If that did not work, try typed node
    if (not defined $uri_agg) {
      my $cnt=$self->countStmts(undef,$has_type,$aggregation);
      if ($cnt==0) {
        $self->err(FATAL,"Failed to find an Aggregation node!");
        return(0);
      } elsif ($cnt==1) {
        my $enum=$self->getStmts(undef,$has_type,$aggregation);
        $statement=$enum->getFirst();
        $enum->close();
        $uri_agg=$statement->getSubject()->getURI();
      } else {
        # more than one match, can't handle that yet so barf.
        $self->err(FATAL,"Got $cnt candidates for Aggregation node");
        return(0);
      }
    }
    # Only get here if we found $statement and extracted $uri_agg, record 
    # in model.
    if (defined $rem) {
      $rem->aggregation($uri_agg);
    }
  }

  # Now look for $uri_agg AGGREGATES <blah> statements and add to 
  # the list of aggregated resources
  my $uri_agg_resource=RDF::Core::Resource->new($uri_agg);
  {
    my $cnt=$self->countStmts($uri_agg_resource,$aggregates,undef);
    if ($cnt==0) {
      $self->err(WARN,"No resources aggregated by Aggregation $uri_agg. This is legal but perhaps not what is intended.");
    } else {
      carp "Found $cnt aggregated resources" if ($self->{debug});
    }
  }

  # Now look for essential metadata: creator and modified
  {
    if (scalar($self->creators($uri_rem))==0) {
      $self->err(FATAL,"Resource map must have at least one ".CREATOR);
      return(0);
    }
  }

  my $uri_rem_resource=RDF::Core::Resource->new($uri_rem);
  if (my $timestamp=$self->get_timestamp($uri_rem_resource,1)) {
    $rem->timestamp_as_iso8601(MODIFIED,$timestamp);
  } else {
    # Will have already thrown error
    return(0);
  }
  
  return(1);
}


=head3 $model->creators($uri)

Find all the CREATOR objects (resources or literals) for $uri.

=cut

sub creators {
  my $self=shift;
  my ($uri_rem)=@_;
  my $uri_rem_resource=RDF::Core::Resource->new($uri_rem);
  return($self->objects_matching($uri_rem_resource,CREATOR));
}


=head3 $model->get_timestamp($uri_rem,$throw_error)

Return timestamp literal associated with $uri_rem. There must be
just one otherwise nothing (error) will be returned.

=cut

sub get_timestamp {
  my $self=shift;
  my ($uri_rem,$throw_error)=@_;
  my @timestamps=$self->objects_matching($uri_rem,MODIFIED);
  if (scalar(@timestamps)!=1) {
    if ($throw_error) {
      $self->err(FATAL,"Resource map must have one and only one ".MODIFIED);
    }
    return();
  }
  my $timestamp=$timestamps[0];
  if (not $timestamp->isLiteral()) {
    if ($throw_error) {
      $self->err(FATAL,"Resource map timestamp must be a literal value");
    }
    return();
  }
  return($timestamp->getLabel());
}


=head3 $model->err($level,$msg)

Error handling. Will use similar error method of $self->{errobj} if
that is set. Otherwise handles here.

=cut

sub err {
  my $self=shift;
  if ($self->{errobj}) {
    return($self->{errobj}->err(@_));
  }
  my ($level,$msg)=@_;
  if ($level>=$self->die_level) {
    croak "ERROR: $msg";
  }
  $self->add_errstr($msg);
}


=head2 INTROSPECTION

These routines support examination of the model to pull out key reference
points and information such as the Resource Map URI or the Aggregation URI.

=head3 $model->find_rem

Attempt to find the Resource Map. Returns the appropriate Resource object 
if successful, nothing otherwise. 

=cut

sub find_rem {
  my $self=shift;

  my $rem=undef;

  my $resource_map=RDF::Core::Resource->new(RESOURCE_MAP);
  my $has_type=RDF::Core::Resource->new(HAS_TYPE);
  my $enum=$self->getStmts(undef,$has_type,$resource_map);
  if (my $statement=$enum->getFirst) {
    # If more than one match, recklessly pick the 'first'
    # FIXME - could look for one with describes link
    $rem=$statement->getSubject;
    $enum->close;
  } else {
    # None found from that test, try looking for something 
    # that DESCRIBES
    my $describes=RDF::Core::Resource->new(DESCRIBES);
    my $cnt=$self->countStmts(undef,$describes,undef);
    if ($cnt==1) {
      # Just one so we take it
      $enum=$self->getStmts(undef,$describes,undef);
      $rem=$enum->getFirst->getSubject;
      $enum->close;
    } else {
      # FIXME - look for one with other matches
    }
  }

  # Now have Resource in $rem if we found it
  return( $rem || () );
}


=head3 $model->find_rem_uri(%opts)

Wrapper around $model->find_rem that returns a URI on
success, nothing otherwise.

=cut

sub find_rem_uri {
  my $self=shift;
  my $agg=$self->find_rem(@_);
  return($agg ? $agg->getURI : () );
}


=head3 $model->find_aggregation(%opts)

Find the Aggregation in this Resource Map. Returns the appropriate 
Resource object if successful, nothing otherwise.

Valid options are:

 uri_rem -> Resurce Map URI,

=cut 

sub find_aggregation {
  my $self=shift;

  my $agg=undef;

  my $aggregation=RDF::Core::Resource->new(AGGREGATION);
  my $has_type=RDF::Core::Resource->new(HAS_TYPE);
  my $cnt=$self->countStmts(undef,$has_type,$aggregation);
  if ($cnt==1) {
    my $enum=$self->getStmts(undef,$has_type,$aggregation);
    $agg=$enum->getFirst->getSubject;
    $enum->close;
  } elsif ($cnt>1) {
    # FIXME - do something smarter than taking the first
    my $enum=$self->getStmts(undef,$has_type,$aggregation);
    $agg=$enum->getFirst->getSubject;
    $enum->close;
  } else { # ($cnt==0)
    # None found from that test, try looking for something 
    # that the rem DESCRIBES
    my $describes=RDF::Core::Resource->new(DESCRIBES);
    my $cnt=$self->countStmts(undef,$describes,undef);
    if ($cnt==1) {
      # Just one so we take it
      my $enum=$self->getStmts(undef,$describes,undef);
      $agg=$enum->getFirst->getObject;
      $enum->close;
    } else {
      # FIXME - look for one with other matches
    }
    # ???
  }

  return( $agg || () );
}


=head3 $model->find_aggregation_uri(%opts)

Wrapper around $model->find_aggregation that returns a URI on
success, nothing otherwise.

=cut

sub find_aggregation_uri {
  my $self=shift;
  my $agg=$self->find_aggregation(@_);
  return($agg ? $agg->getURI : () );
}


=head2 DATA DUMP 

These are low-level data dump methods. It is expected that normally
the methods provided via L<SemanticWeb::OAI::ORE::ReM>::serialize will be used.

=head3 $model->as_n3($unsorted)

Very simple dump of this object as N3. No prefixes are used and the triples
are sorted alphabetically by line unless $unsorted is set true (in which case 
the output will be essentially random).

See L<SemanticWeb::OAI::ORE::N3> for "pretty printing" methods.

=cut

sub as_n3 {
  my $self=shift;
  my ($unsorted)=@_;

  my @triples=();
  my $enum=$self->getStmts(undef,undef,undef);
  my $statement=$enum->getFirst();
  while ($statement) {
    my $subject='<'.$statement->getSubject()->getLabel().'>';
    my $predicate='<'.$statement->getPredicate()->getLabel().'>';
    my $obj=$statement->getObject();
    my $object=$obj->getLabel();
    if ($obj->isa('RDF::Core::Resource')) {
      $object='<'.$object.'>';
    } else {
      $object='"'.SemanticWeb::OAI::ORE::N3::_n3_escape($object).'"';
    }
    push(@triples,"$subject $predicate $object.\n");
    $statement=$enum->getNext();
  }

  my $str="# Dump of OAI-ORE Resource Map model as N3\n";
  if ($unsorted) {
    $str.=join('',@triples);
  } else {
    $str.=join('',sort(@triples));
  }
  return($str);
}


=head3 $model->as_rdfxml

Simple RDF XML dump, returns string. For more sophisticated output
see L<SemanticWeb::OAI::ORE::RDFXML>.

=cut

sub as_rdfxml {
  my $self=shift;
  my $xml = '';
  my $serializer = new RDF::Core::Model::Serializer(Model=>$self,
                                                    Output=>\$xml,
                                                    BaseURI => 'http://example.com/',
                                                   );
  $serializer->serialize;
  return($xml);
}


=head1 SEE ALSO

L<SemanticWeb::OAI::ORE::ReM>

=head1 AUTHOR

Simeon Warner

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2010 Simeon Warner.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
