package RDF::Server::Formatter;

use Moose::Role;

requires 'wants_rdf';

requires 'resource';

requires 'to_rdf';

requires 'collection';

requires 'workspace';

requires 'service';

requires 'category';

requires 'feed';

1;

__END__

=pod

=head1 NAME

RDF::Server::Formatter - handles rendering an object in a particular format

=head1 SYNOPSIS

 package My::Format;

 use Moose;
 with 'RDF::Server::Formatter';

 sub resource { }

 sub to_rdf { }

=head1 DESCRIPTION

Formatters handle the translation of documents from the format used by
the handlers, model, and resource and the client.

The RDF triple store interface modules work with RDF.  If another document
format is preferred, then a formatter is needed to translate between the
preferred format and RDF.

=head1 REQUIRED METHODS

=over 4

=item wants_rdf : Bool

This should return true if the C<resource> rendering method expects RDF.
Otherwise, the resource handler will pass in a Perl data structure.  Rendering
to data serialization formats such as JSON or YAML will probably prefer 
a data structure instead of RDF.

=item resource : Str

This returns the content in the appropriate format given the RDF or data
structure representing the information in the triple store.

=item to_rdf : Str

This should return an RDF document representing the information presented in
the format understood by the formatter.

=item collection : Str

This should return a document representing the items in a collection as well
as any categories or domains into which resources are divided.

=item workspace : Str

This should return a document representing a set of collections.

=item service : Str

This should return a document representing a set of workspaces.

=item category : Str

This should return a document representing a domain within a collection.

=item feed : Str

This should return a document representing a list of resources that result
from a query on a collection.

=back

=head1 AUTHOR 

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

