package SemanticWeb::OAI::ORE::RDFXML;
#$Id: RDFXML.pm,v 1.6 2010-12-06 14:44:15 simeon Exp $

=head1 NAME

SemanticWeb::OAI::ORE::RDFXML - Parse/serialize OAI-ORE Resource Maps in RDF/XML format

=head1 SYNPOSIS

Module to parse and serialize OAI-ORE resource maps in RDF/XML format. 
See L<SemanticWeb::OAI::ORE>.

=cut

use strict;
use warnings;
use Carp;

use SemanticWeb::OAI::ORE::ReM;
use RDF::Core::Storage::Memory;
use RDF::Core::Model;
use RDF::Core::Model::Parser;
use RDF::Core::Model::Serializer;

=head1 METHODS

=head2 new()

Create a new RDFXML handler object.

=cut

sub new {
  my $class=shift;
  my $self={@_};
  bless $self, (ref($class) || $class);
  return($self);
}


=head2 parse($rdfxml,$uri_rem)

Parse input string or read from open filehandle $rdfxml which contains the 
RDF/XML serialization of the ReM with base URI $uri_rem. A base URI must be 
supplied otherwise the parser (L<RDF::Core::Model::Parser>) will fail.

Returns a L<RDF::Core::Model> model.

=cut

sub parse {
  my $self=shift;
  my ($rdfxml,$uri_rem)=@_;  

  # Read in file if necessary
  if (ref($rdfxml)) {
    # Assume filehandle
    my $fh=$rdfxml;
    local $/=undef; #to slurp file
    $rdfxml=<$fh>;
  }

  my $storage=RDF::Core::Storage::Memory->new();
  my $model=RDF::Core::Model->new(Storage => $storage);
  # The BaseURI must be supplied otherwise the parser will fail
  my $parser=RDF::Core::Model::Parser->new(Model=>$model,
                                           BaseURI=>$uri_rem,
                                           Source=>$rdfxml,
                                           SourceType=>'string');
  $parser->parse();
  return($model);
}


=head2 serialize()

Serialize resource map as RDF/XML. Returns serializetion
as a string.

See L<RDF::Core::Model::Serializer> and L<RDF::Core::Serializer>.

=cut

sub serialize {
  my $self=shift;
  my $out='';
  my $rem=$self->{rem};
  if (ref($rem) and $rem->isa('SemanticWeb::OAI::ORE::ReM')) {
    # Get the info from the ReM
    $out.="<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    $out.="<!-- OAI-ORE Resource Map (".$rem->uri.") -->\n";

    # Do not specify a BaseURI option as we do not want relative URIs in output
    my $serializer = RDF::Core::Model::Serializer->new(Model=>$rem->model,
                                                       Output => \$out);
    $serializer->serialize;
  } else {
    die "Can't serialize something that isn't a resource map: have a ".ref($rem)."\n";
  }
  return($out);
}


=head1 SEE ALSO

L<SemanticWeb::OAI::ORE::ReM>

=head1 AUTHORS

Simeon Warner

=head1 LICENSE AND COPYRIGHT

Copyright 2007-2010 Simeon Warner.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
