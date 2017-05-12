# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Model::Parser;

use strict;
require Exporter;

use Carp;
require RDF::Core::Parser;
require RDF::Core::Statement;
require RDF::Core::NodeFactory;

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
    bless $self, $pkg;
}
sub setOptions {
    my ($self,$options) = @_;
    $self->{_options} = $options;
}
sub getOptions {
    my $self = shift;
    return $self->{_options};
}
sub parse {
    my $self = shift;
    if (@_ > 0) {
	#set options if passed
	$self->{_options} = $_[0];
    }
    # make copy of options for parser
    my %parserOptions = %{$self->getOptions};
    delete $parserOptions{Model};
    delete $parserOptions{Source};
    delete $parserOptions{SourceType};
    $parserOptions{Assert} = 
      sub {my %params = @_;
	   my $params = \%params;
	   my $factory = new RDF::Core::NodeFactory();
	   my ($subject,$object,$predicate);
	   if (exists $params->{subject_ns}) {
	       $subject = $factory->newResource($params->{subject_ns},
						$params->{subject_name});
	   } else {
	       $subject = $factory->newResource($params->{subject_uri});
	   }
	   if (exists $params->{predicate_ns}) {
	       $predicate = $factory->newResource($params->{predicate_ns},
						  $params->{predicate_name});
	   } else {
	       $predicate = $factory->newResource($params->{predicate_uri});
	   }
	   if (exists $params->{object_literal}) {
	       $object = $factory->newLiteral($params->{object_literal},
					      $params->{object_lang} || undef,
					      $params->{object_datatype}||undef
					     );
	   } elsif (exists $params->{object_ns}) {
	       $object = $factory->newResource($params->{object_ns},
					       $params->{object_name});
	   } else {
	       $object = $factory->newResource($params->{object_uri});
	   }
	   my $st = new RDF::Core::Statement($subject,$predicate,$object);
	   $self->getOptions->{Model}->addStmt($st);
       }
      unless defined $parserOptions{Assert};
    my $parser = new RDF::Core::Parser(%parserOptions);
    return $parser->parse($self->getOptions->{Source})
      if $self->getOptions->{SourceType} eq 'string';
    return $parser->parseFile($self->getOptions->{Source})
      if $self->getOptions->{SourceType} eq 'file';
}
1;
__END__

=head1 NAME

RDF::Core::Model::Parser - interface between model and RDF::Core::Parser

=head1 SYNOPSIS

  require RDF::Core::Model::Parser;
  %options = (Model => $model,
              Source => $fileName,
              SourceType => 'file',
              #parserOptions
              BaseURI => "http://www.foo.com/",
              BNodePrefix => "genid"
             )
  my $parser = new RDF::Core::Model::Parser(%options);
  $parser->parse;

=head1 DESCRIPTION

While RDF::Core::Parser transforms RDF/XML syntax into general assertions, RDF::Core::Model::Parser defines default handler for assertion and provides methods that should conform any parsing request. That is setting options and doing the parse job. If there is need for use of another existing rdf parser or more parsers, a new parser interface should be created. 

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * Model

Where should the statements be stored in.

=item * Source

A name of a XML file or a string containing XML.

=item * SourceType

Contains 'string' if source is a XML string or 'file' if source is a file name.

=item * [ParserOptions]

All other options are passed to the parser (L<RDF::Core::Parser>).

=back

=item * getOptions

=item * setOptions(\%options)

=item * parse



=back

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Parser, RDF::Core::Model

=cut
