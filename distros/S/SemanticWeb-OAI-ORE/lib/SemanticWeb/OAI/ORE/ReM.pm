package SemanticWeb::OAI::ORE::ReM;
#$Id: ReM.pm,v 1.32 2010-12-07 16:38:29 simeon Exp $

=head1 NAME

SemanticWeb::OAI::ORE::ReM - Module implementing OAI-ORE Resource Map object

=head1 SYNPOSIS

This class is designed to provide convenient ways to interact with
OAI-ORE resource maps from Perl code. It as based around a data model
class L<SemanticWeb::OAI::ORE::Model> which is the RDF model and may be
accessed directly via $rem->model. The access methods here are intended 
to hide the RDF and instead work more naturally with the constraints
and language of OAI-ORE.

Written against the v1.0 OAI-ORE specification 
(L<http://www.openarchives.org/ore/1.0/toc>).

=head1 DESCRIPTION

An ORE Resource Map is comprised of two things:

1) a URI indicating its location

2) an RDF graph expressing the relationship between an aggregation and 
aggreted resources

This class encapsulates these two things ($rem->uri and $rem->model),
some other useful informatino about paring and serialization methods,
and provides routines to create/read, update, and write the
resource map.

=head2 CREATION OF A RESOURCE MAP

For simple case where we have simply a set of aggregated resources 
and minimal metadata is required:

 use SemanticWeb::OAI::ORE::ReM;

 my $rem=SemanticWeb::OAI::ORE::ReM->new('ar'=>['uri:1','uri:2']);
 print $rem->serialize('rdfxml');

=head2 PARSING A RESOURCE MAP

 use SemanticWeb::OAI::ORE::ReM;
 my $rem=SemanticWeb::OAI::ORE::ReM->new;
 $rem->parse('rdfxml',$rdfxml_string);

=cut

use warnings;
use strict;
use Carp;

use SemanticWeb::OAI::ORE::Agent;
use SemanticWeb::OAI::ORE::Constant qw(:all);
use SemanticWeb::OAI::ORE::Model;
use DateTime;
use IO::File;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(default_format die_level warn_level));

=head1 METHODS

=head3 SemanticWeb::OAI::ORE::ReM->new(%args)

Create a new Resource Map (ReM) object. The resource map is comprised
of a URI (URI-R) and a set of triples, the model.

Any C<%args> supplied are used to set the object variables.
As a shorthand for construction argument C{ar} may be used to 
provide an arrayref of aggregated resources which are added
using C<$rem->aggregated_resources($args{ar})>.

=cut

sub new {
  my $class=shift;
  my $self={'uri'=>undef,
            'uri_agg'=>undef,
            'model'=>undef,
            'io'=>{#'atom'   =>'SemanticWeb::OAI::ORE::Atom',
                   'rdfxml' =>'SemanticWeb::OAI::ORE::RDFXML',
                   'trix'   =>'SemanticWeb::OAI::ORE::TriX',
                   'n3'     =>'SemanticWeb::OAI::ORE::N3'},
            'default_format'=>'rdfxml',
            'die_level'=>FATAL,
            'warn_level'=>WARN,
            @_};
  bless $self, (ref($class) || $class);

  # As a shorthand we accept the {ar} parameter which may be
  # an arrayref to a list of aggregated resources
  if ($self->{ar}) {
    $self->aggregated_resources($self->{ar});
    delete($self->{ar});
  }

  return($self);
}


=head3 $rem->uri()

Set or access the identity of the ReM (URI-R). This should be the first 
thing set when building a Resource Map. The validity of the URI is checked
with C<check_valid_uri(..)>.

=cut

sub uri {
  my $self=shift;
  if (@_) {
    my $uri=shift;
    $self->check_valid_uri($uri,'Resource Map URI');
    $self->{uri}=$uri;
  }
  return($self->{uri});
}


=head3 $rem->model()

Set or access the model (see L<SemanticWeb::OAI::ORE::Model>) of this Resource 
Map. It is usually expected that ORE specific accessor methods such
as L<aggregated_resources>, L<creator> and such will be used to 
add data to the model when building a resource map.

See L<SemanticWeb::OAI::ORE::Model> for details of how the model may be
accessed and manipulated, and also methods that follow for convenient
accessors to ORE elements.

Will always return the reference to the model object so one can do things
such as:

 $rem->model->add($ref_statement);

=cut

sub model {
  my $self=shift;
  if (@_ or not $self->{model}) {
    my $model=$_[0];
    if (ref($model) and $model->isa('SemanticWeb::OAI::ORE::Model')) {
      $self->{model}=$model;
    } else {
      if ($self->{model}=SemanticWeb::OAI::ORE::Model->new(@_)) {
        $self->{model}->{errobj}=$self;
      }
    }
  }
  return($self->{model});
}


=head3 $rem->aggregation()

Set or access the URI of the Aggregation described by this ReM (URI-A).
Must be set after the URI of the Resource Map (URI-R) and would usually
be the second thing set when building a resource map from scratch.

WARNING - this routine does not have the facility to update all occurrences 
in the model if changed when other statements (e.g. aggregated resources
or metadata) have been added that reference the aggregation.

=cut

sub aggregation {
  my $self=shift;
  if (@_) {
    my $aggregation=shift;
    $self->check_valid_uri($aggregation,'Aggregation URI');
    $self->{uri_agg}=$aggregation;
    $self->model->add_rel_to_resource($self->{uri},DESCRIBES,$aggregation);
  }
  return($self->{uri_agg});
}


=head3 $rem->creators()

Set or access the creator of the ReM. Returns If there is more than one creator then 
the first will be returned. Returns nothing if there is no creator set.

See L<http://www.openarchives.org/ore/1.0/datamodel#Metadata_about_the_ReM>:

 The identity of the authoring authority (human, organization, or agent) of 
 the Resource Map, using the dcterms:creator predicate, with an object that MUST 
 be a reference to a Resource of type L<http://purl.org/dc/terms/Agent>. This MAY 
 then be the subject of the following triples:

 * A triple with the predicate foaf:name and an object that is a text string 
   containing some descriptive name of the authoring authority.

 * A triple with the predicate foaf:mbox and an object that is a URI that is 
   the email address of the authoring authority.

=cut

sub creators {
  my $self=shift;
  foreach my $creator (@_) {
    $self->model->add_rel_to_resource($self->{uri},CREATOR,$creator);
  }
  my @creators=();
  foreach my $creator ($self->model->creators($self->{uri})) {
    push(@creators,SemanticWeb::OAI::ORE::Agent->new(uri=>$creator->getURI,
                                             name=>$self->model->literal_matching($creator,FOAF_NAME),
                                             mbox=>$self->model->literal_matching($creator,FOAF_MBOX)));
  }
  return(@creators);
}


=head3 $rem->creator()

Assumes one creator. Wrapper around $rem->creators() that does the same thing 
except in the case where there are multiple creators it will return just the first.

=cut

sub creator {
  my $self=shift;
  my @creators=$self->creators;
  return(@creators ? shift @creators : () );
}


=head3 $rem->creator_name()

Set or access the creator as a URI of the ReM.

=cut

sub creator_name {
  my $self=shift;
  if (@_) {
    $self->{creator_name}=shift;
    $self->model->add_rel_to_literal($self->{uri},CREATOR,$self->{creator_name});
  } else {

  }
  return($self->{creator_name});
}


=head3 $rem->timestamp_as_unix($type,$timestamp)

Set or access the option creation timestamp of the ReM. Returns 
now if not set. Type should be either CREATED or MODIFIED constant.
Usually called via created_as_unix() or modified_as_unix() wrappers.

Will set if timestamp if C<$timestamp> is defined.

=cut

sub timestamp_as_unix {
  my $self=shift;
  my ($type,$timestamp)=@_;
  if (not defined $type or ($type ne CREATED and $type ne MODIFIED)) {
    confess "OOPS - call to timestamp_as_unix(type) without valid type (got: $type)";
  }
  if (defined $timestamp) {
    if ($self->{timestamp_iso8601}) {
      carp "WARNING - Already have ISO8601 timestamp set";
    }
    $self->{timestamp_unix}=$timestamp;
  }
  if ($self->{timestamp_iso8601}) {
    croak "OOPS .. haven't implemented conversion of ISO8601 to unix time";
  } else {
    return($self->{timestamp_unix} || time());
  }
}

=head3 $rem->created_as_unix($timestamp)

Set or access the creation timestamp of the ReM as a Unix timestamp. 

Will set timestamp if C<$timestamp> is defined.

=cut

sub created_as_unix {
  my $self=shift;
  return(timestamp_as_unix($self,CREATED,@_));
}


=head3 $rem->modified_as_unix($timestamp)

Set or access the modification timestamp of the ReM as a Unix timestamp.

Will set timestamp if C<$timestamp> is defined.

=cut

sub modified_as_unix {
  my $self=shift;
  return(timestamp_as_unix($self,MODIFIED,@_));
}


 
=head3 $rem->timestamp_as_iso8601($type,$timestamp)

Set or access the timestamp of the rem as an ISO8601 string.
Type should be either CREATED or MODIFIED constant.
Usually called via created_as_iso8601() or modified_as_iso8601() wrappers.

Will set timetstamp if C<$timestamp> is defined.

=cut

sub timestamp_as_iso8601 {
  my $self=shift;
  my ($type,$timestamp)=@_;
  if (not defined $type or ($type ne CREATED and $type ne MODIFIED)) {
    confess "OOPS - call to timestamp_as_iso8601(type) without valid type (got: $type)";
  }
  return(undef) if ($type eq CREATED); #FIXME - not yet implemented
  if (defined $timestamp) {
    if ($self->{timestamp_unix}) {
      carp "WARNING - Already have unix timestamp set";
    }
    $self->{timestamp_iso8601}=$timestamp;
  }
  return($self->{timestamp_iso8601});
}


=head3 $rem->now_as_iso8601()

Returns the current system time as an iso8601 string

=cut

sub now_as_iso8601 {
  my $self=shift;
  my $dt=DateTime->from_epoch(time());
  return($dt->iso8601().'Z');
}


=head3 $rem->created_as_iso8601($timestamp)

Set or access the creation timestamp of the ReM as a ISO8601 timestamp.

Will set timestamp if C<$timestamp> is defined.

=cut

sub created_as_iso8601 {
  my $self=shift;
  return(timestamp_as_iso8601($self,CREATED,@_));
}


=head3 $rem->modified_as_iso8601($timestamp)

Set or access the creation timestamp of the ReM as a ISO8601 timestamp.

Will set timestamp if C<$timestamp> is defined.

=cut

sub modified_as_iso8601 {
  my $self=shift;
  return(timestamp_as_iso8601($self,MODIFIED,@_));
}


=head3 $rem->aggregation_metadata($predicate,$only)

If C<$only> is not specified then the objects matching will be returned.

If C<$only> is C<RESOURCE> then only resource labels will be included, if
C<LITERAL> then only literal labels will be returned.

=cut

sub aggregation_metadata {
  my $self=shift;
  my ($predicate,$only)=@_;
  # Cannot do anything if we do not have an aggregation
  return() if (not $self->aggregation);
  # We do, search for all matching objects
  return( $self->model->objects_matching($self->aggregation,$predicate,$only) );
}


=head3 $rem->aggregation_metadata_literal($predicate)

Wrapper for C<$rem->aggregation_metadata> that will take just the first
matching literal, or return undef if there a no matches.

=cut

sub aggregation_metadata_literal {
  my $self=shift;
  my ($predicate)=@_;
  # Cannot do anything if we donot have an aggregation
  return() if (not $self->aggregation);
  # We do, get first matching literal
  return( $self->model->literal_matching($self->aggregation,$predicate) );
}


=head3 $rem->aggregated_resources()

Set or access the aggregated resources list.

 $rem->aggregated_resources('uri:3');

This method will never remove an aggregated resource from this ReM. Use 
delete_aggregated_resources to remove or clear the set of
aggregated resources for this ReM. Returns a list of all the
aggregated resources.

=cut

sub aggregated_resources {
  my $self=shift;
  foreach my $ar (@_) {
    $self->model->add_rel_to_resource($self->aggregation,AGGREGATES,$ar);
  } 
  # now return the list of all aggregated resources
  return($self->model->objects_matching($self->aggregation,AGGREGATES,RESOURCE));
}


=head3 $rem->rights()

Set of access the rights for this resource map. Permits only
one rights statement to be associated with the resource map.
Returns undef if no rights value is set.

=cut

sub rights {
  my $self=shift;
  if (@_) {
    my $rights=shift(@_);
    $self->model->add_rel_to_resource($self->{uri},RIGHTS,$rights);
  }
  # now return the current rights URI
  my @rights=$self->model->objects_matching($self->{uri},RIGHTS,RESOURCE);
  return($rights[0] ? $rights[0] : undef);
}


=head3 $rem->is_valid

Run validation checks on the resource map model. Returns true (1) on succes,
false (nothing) on failures. Errors set in errstr.

=cut

sub is_valid {
  my $self=shift;

  eval {
    $self->model->check_model($self->uri,$self);
  };
  if ($@) {
    # Oops
    $self->add_errstr("Invalid resource map: $@");
    return;
  }
  return(1);
}



#####################################################################

=head2 INPUT AND OUTPUT METHODS

=head3 $rem->parse($format,$src,$uri_rem)

Parse resource C<$uri_rem>. Get it from C<$src>, where C<$src> may be 
either a string containing the representation to be parsed,
or an open filehandle. If C<$src> is not set then attempt to 
download from C<$uri_rem> using C<parseuri()>.

To parse a file directly, use the C<parsefile()> wrapper. To parse
a URI directly, use the C<parseuri()> wrapper.

Will run validation checks on the resource map model obtained. Set
C<$rem->die_level(RECKLESS)> to ignore errors.

Will return true (1) on success, false (undef) on failure. Will
have set errstr on failure.

=cut

sub parse {
  my $self=shift;
  my ($format,$src,$uri_rem)=@_;

  if (not defined $src and defined $uri_rem) {
    # Try to get from URI
    return($self->parseuri($format,$uri_rem));
  }

  my $input_uri_rem=$uri_rem;
  $uri_rem='http://unknown.example.org/' if (not defined $uri_rem);

  my $model=undef;
  if (my $io_class=$self->{io}{$format}) {
    eval {
      if (not eval("require $io_class")) {
        croak "Failed to load class $io_class: $@";
      }
      my $reader=$io_class->new(%$self,'rem'=>$self);
      #print "DEBUG ".__PACKAGE__."::parse: using reader: $reader isa ".ref($reader)."\n";
      $model=$reader->parse($src,$uri_rem);
    } or do {
      carp "Error trying to parse (".($uri_rem?$uri_rem:'ReM URI unknown').") in '$format' using class '$io_class': $@\n";
      if (not $self->errstr) {
	$self->errstr("Error parsing (".($uri_rem?$uri_rem:'ReM URI unknown').")");
      }
    };
  } else {
    croak "Unknown serialization format to parse '$format' in parse(..)\n";
  }

  # Now have model in $model, connect as model of this Resource Map
  # and check that it is valid.
  $model=$self->model($model);

  # If we didn't know the ReM URI to start, introspect to find it
  if ($input_uri_rem) {
    $self->uri($input_uri_rem);
  } else {
    if (my $uri=$self->model->find_rem_uri) {
      $self->uri($uri);
    }
  }

  # If we didn't know the Aggregation URI to start, introspect to find it
  if (not $self->aggregation) {
    if (my $agg=$self->model->find_aggregation_uri) {
      $self->{uri_agg}=$agg;
    }
  }

  # Validate?
  #$self->is_valid;

  return(1);
}


=head3 $rem->parsefile($format,$file,$uri_rem)

Wrapper for X<$rem->parse($format,$uri_rem,$src)> which does nothing with
C<$format> and C<$uri_rem> but opens C<$file> and passes the reulting filehandle
on to C<$rem->parse(...)>. Returns C<undef> if the file cannot be opened, otherwise
return values as for C<$rem->parse(...)>.

=cut

sub parsefile {
  my $self=shift;
  my ($format,$file,$uri_rem)=@_;
  my $srcfh=IO::File->new();
  if ($srcfh->open($file,'<')) {
    my $retval=$self->parse($format,$srcfh,$uri_rem);
    close($srcfh);
    return($retval);
  }
  $self->errstr("Can't open source file '$file'");
  return(undef);
}


=head3 $rem->parseuri($format,$uri_rem)

Simple wrapper for X<$rem->parse($format,$uri_rem,$src)> that 
downloads C<$uri_rem> with L<LWP::Simple> before passing it on. 
Returns C<undef> if C<$uri_rem> cannot be downloaded, otherwise 
return values as for C<$rem->parse(...)>.

=cut

sub parseuri {
  my $self=shift;
  my ($format,$uri_rem)=@_;

  if (not defined $uri_rem) {
    croak("Attempt to call parseuri without a URI");
  }

  # Wrap in eval so we can run this module without LWP::Simple if
  # this method is not required
  my $src_string;
  eval {
    use LWP::Simple (); #do not import
    $src_string=LWP::Simple::get($uri_rem);
  };
  if ($@ or not defined $src_string) {
    $self->errstr("Can't get ReM from $uri_rem: $@");
    return(undef);
  }
  
  return($self->parse($format,$src_string,$uri_rem));
}


=head3 $rem->serialize()

Serialize in default format which has accessor C<$rem->default_format>.

=head3 $rem->serialize($format)

Serialize in C<$format>. This will use and call the appropriate
writer class.

=cut

sub serialize {
  my $self=shift;
  my $format=shift || $self->{default_format};
  my $out='';
  if (my $io_class=$self->{io}{$format}) {
    eval {
      eval("require $io_class");
      my $writer=$io_class->new('rem'=>$self,@_);
      #print "DEBUG ".__PACKAGE__."::serialize: using writer: $writer isa ".ref($writer)."\n";
      $out=$writer->serialize();
    } or do {
      carp "Error trying to serialize in '$format' using class '$io_class': $@\n";
    };
  } else {
    carp "Unknown serialization format '$format'\n";
  }
  return($out);
}


=head3 $rem->errstr($str) or $rem->errstr

Resets the error string to C<$str> if C<$str> provided.

Returns a string, either the error string if set, else ''.

=cut

sub errstr {
  my $self=shift;
  my $str=shift;
  $self->{errstr}=$str if (defined $str);
  return($self->{errstr}?$self->{errstr}:'');
}


=head3 $rem->add_errstr($str)

Add to the error string. Will append C<\n> if not present in C<$str>.

=cut

sub add_errstr {
  my $self=shift;
  my ($str)=@_;
  $str.="\n" if ($str!~/\n$/);
  $self->{errstr}.=$str;
}


=head3 $rem->err($level,$msg)

Log and/or report an error C<$msg> at level C<$level>. Intended mainly
for internal use and use by particular format classes.

=cut 

sub err {
  my $self=shift;
  my ($level,$msg)=@_;
  if ($self->die_level and $level>=$self->die_level) {
    croak "ERROR: $msg";
  } elsif ($self->warn_level and $level>=$self->warn_level) {
    my $code=ERROR_LEVEL->[$level] || 'UNKNOWN';
    $self->add_errstr("[$code] $msg");
  } #else ignore!
}


=head3 $rem->check_valid_uri($uri,$description)

Check that the supplied C<$uri> is valid and create C<$rem->err> if not. 
Returns true if valid, false otherwise.

=cut

sub check_valid_uri {
  my $self=shift;
  my ($uri,$description)=@_;
  if (not defined $uri) {
    $self->err(WARN,"$description is not defined and thus not a valid URI");
    return();
  } elsif ($uri!~/^[a-z]+:\S+$/) {
    $self->err(WARN,"$description ($uri) is not a valid URI");
    return();
  }
  return(1);
}


=head1 SEE ALSO

Details of the Open Archive Initiative, including both the OAI-ORE and
OAI-PMH specification are found at L<http://www.openarchives.org/>.

This module is the primary class for support of OAI-ORE resource maps. 
Other parts include:
L<SemanticWeb::OAI::ORE::Model>
L<SemanticWeb::OAI::ORE::N3>
L<SemanticWeb::OAI::ORE::Trix>

Support for the OAI-PMH protocol is provided by other modules 
including L<SemanticWeb::OAI::Harvester>.

=head1 AUTHOR

Simeon Warner, C<< <simeon at cpan.org> >>

=head1 BUGS

Support for Atom format output is not yet provided, this should be
L<SemanticWeb::OAI::ORE::Atom>.

Please report any bugs or feature requests to
C<bug-net-oai-ore at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OAI-ORE>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SemanticWeb::OAI::ORE

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OAI-ORE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OAI-ORE>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OAI-ORE>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OAI-ORE>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 Simeon Warner.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
