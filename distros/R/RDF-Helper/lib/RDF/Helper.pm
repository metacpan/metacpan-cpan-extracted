package RDF::Helper;
use 5.10.1;
use Moose;
our $VERSION = '2.01';

use RDF::Helper::Statement;
use RDF::Helper::Object;
use Class::Load;

has backend => (
    does     => 'RDF::Helper::API',
    is       => 'ro',
    required => 1,
    handles  => 'RDF::Helper::API',
);

sub BUILDARGS {
    my $this  = shift;
    my $args  = $this->SUPER::BUILDARGS(@_);
    return $args if $args->{backend};

    my $class = delete $args->{BaseInterface};

    $class = 'RDF::Redland'
      if (!$class
        && $args->{Model}
        && $args->{Model}->isa('RDF::Redland::Model') );

    given ($class) {
        when (qr/RDF::Helper::.*/) { }
        when ('RDF::Redland') { $class = 'RDF::Helper::RDFRedland'; };
        default { $class = 'RDF::Helper::RDFTrine' }
    }

    Class::Load::load_class($class);
    my $backend = $class->new(%$args);
    return { backend => $backend };
}

1;
__END__

=head1 NAME

RDF::Helper - Provide a consistent, high-level API for working with RDF with Perl

=head1 SYNOPSIS

  use RDF::Helper;

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      namespaces => {
          dct => 'http://purl.org/dc/terms/',
          rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
         '#default' => "http://purl.org/rss/1.0/",
     }
  );

=head1 DESCRIPTION

This module intends to simplify, normalize and extend Perl's existing
facilities for interacting with RDF data.

RDF::Helper's goal is to offer a syntactic sugar which will enable
developers to work more efficiently. To achieve this, it implements
methods to work with RDF in a way that would be familiar to Perl
programmers who are less experienced with RDF.

It builds on L<RDF::Trine>, which in turn provides the low-level API
which is closer to RDF.

=head1 CONSTRUCTOR OPTIONS

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      namespaces => {
          dc => 'http://purl.org/dc/terms/',
          rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
         '#default' => "http://purl.org/rss/1.0/",
     },
     ExpandQNames => 1
  );

=head2 BaseInterface

The C<BaseInterface> option expects a string that corresponds to the
class name of the underlying Perl RDF library that will be used by
this instance of the Helper. L<RDF::Trine> is the default, but
C<RDF::Redland> is retained as an option for historical reasons, but
may be removed in the future. If you have a Redland-based database,
you can use L<RDF::Trine::Store::Redland>.

=head2 Model

The C<Model> option expects a blessed instance object of the RDF model
that will be operated on with this instance of the Helper. Obviously,
the type of object passed should correspond to the L<BaseInterface>
used (L<RDF::Trine::Model> for a BaseInterface of L<RDF::Trine>,
etc.). If this option is omitted, a new, in-memory model will be
created.

=head2 namespaces

The C<namespaces> option expects a hash reference of prefix/value
pairs for the namespaces that will be used with this instance of the
Helper. The special '#default' prefix is reserved for setting the
default namespace.

For convenience, the L<RDF::Helper::Constants> class will export a
number of useful constants that can be used to set the namespaces for
common grammars:

  use RDF::Helper;
  use RDF::Helper::Constants qw(:rdf :rss1 :foaf);

  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      namespaces => {
          rdf => RDF_NS,
          rss => RSS1_NS,
          foaf => FOAF_NS
     },
     ExpandQNames => 1
  );

=head2 ExpandQNames

Setting a non-zero value for the C<ExpandQNames> option configures the
current instance of the Helper to allow for qualified URIs to be used
in the arguments to many of the Helper's convenience methods. For
example, given the L<namespaces> option for the previous example, with
C<ExpandQNames> turned on, the following will work as expected.

  $rdf->assert_resource( $uri, 'rdf:type', 'foaf:Person' );

With C<ExpandQNames> turned off, you would have to pass the full URI
for both the C<rdf:type> predicate, and the C<foaf:Person> object to
achieve the same result.

=head2 base_uri

If specified, this option sets what the base URI will be when working
with so called abbreviated URIs, like C<#me>.  If you do not specify
an explicit base_uri option, then one will be created automatically
for you.  See
L<http://www.w3.org/TR/rdf-syntax-grammar/#section-Syntax-ID-xml-base>
for more information on abbreviated URIs.

=head1 METHODS

=head2 new_resource

  $res = $rdf->new_resource($uri)

Creates and returns a new resource object that represents the supplied
URI.  In many cases this is not necessary as the methods available in
L<RDF::Helper> will automatically convert a string URI to the
appropriate object type in the back-end RDF implementation.

=head2 new_literal

  $lit = $rdf->new_literal($text)
  $lit = $rdf->new_literal($text, $lang)
  $lit = $rdf->new_literal($text, $lang, $type)

Creates and returns a new literal text object that represents the
supplied string.  In many cases this is not necessary as the methods
available in L<RDF::Helper> will automatically convert the value to
the appropriate object type in the back-end RDF implementation.

When it is necessary to explicitly create a literal object is when you
want to specify the language or datatype of the text string.  The
datatype argument expects a Resource object or a string URI.

=head2 new_bnode

  $bnode = $rdf->new_bnode()

Creates and returns a new "Blank Node" that can be used as the subject
or object in a new statement.

=head2 assert_literal

  $rdf->assert_literal($subject, $predicate, $object)

This method will assert, or "insert", a new statement whose value, or "object", is a literal.

Both the subject and predicate arguments can either take a URI object, a URI string.

Additionally, if you used the L</ExpandQNames> option when creating
the L<RDF::Helper> object, you can use QNames in place of the subject
and predicate values.  For example, "rdf:type" would be properly
expanded to its full URI value.

=head2 assert_resource

  $rdf->assert_resource($subject, $predicate, $object)

This method will assert, or "insert", a new statement whose value, or "object", is a resource.

The subject, predicate and object arguments can either take a URI object, or a URI string.

Like L</assert_literal>, if you used the L</ExpandQNames> option when
creating the L<RDF::Helper> object, you can use QNames in place of any
of the arguments to this method.  For example, "rdf:type" would be
properly expanded to its full URI value.

=head2 remove_statements

  $count = $rdf->remove_statements()
  $count = $rdf->remove_statements($subject)
  $count = $rdf->remove_statements($subject, $predicate)
  $count = $rdf->remove_statements($subject, $predicate, $object)

This method is used to remove statements from the back-end RDF model
whose constituent parts match the supplied arguments.  Any of the
arguments can be omitted, or passed in as C<undef>, which means any
value for that triple part will be matched and removed.

For instance, if values for the predicate and object are given, but
the subject is left as "undef", then any statement will be removed
that matches the supplied predicate and object.  If no arguments are
supplied, then all statements in the RDF model will be removed.

The number of statements that were removed in this operation is returned.

=head2 update_node

  $rdf->update_node($subject, $predicate, $object, $new_object)

This method is used when you wish to change the object value of an
existing statement.  This method acts as an intelligent wrapper around
the L</update_literal> and L</update_resource> methods, and will try
to auto-detect what type of object is currently in the datastore, and
will try to set the new value accordingly.  If it can't make that
determination it will fallback to L</update_literal>.

Keep in mind that if you need to change a statement from having a
Resource to a Literal, or vice versa, as its object, then you may need
to invoke the appropriate update method directly.

=head2 update_literal

  $rdf->update_literal($subject, $predicate, $object, $new_object)

Updates an existing statement's literal object value to a new one.
For more information on the operation of this method, see
L</update_node>.

=head2 update_resource

  $rdf->update_resource($subject, $predicate, $object, $new_object)

Updates an existing statement's resource object value to a new one.
For more information on the operation of this method, see
L</update_node>.

=head2 get_statements

  @stmts = $rdf->get_statements()
  @stmts = $rdf->get_statements($subject)
  @stmts = $rdf->get_statements($subject, $predicate)
  @stmts = $rdf->get_statements($subject, $predicate, $object)

This method is used to fetch and return statements from the back-end
RDF model whose constituent parts match the supplied arguments.  Any
of the arguments can be omitted, or passed in as C<undef>, which means
any value for that triple part will be matched and returned.

For instance, if values for the predicate and object are given, but
the subject is left as "undef", then any statement will be returned
that matches the supplied predicate and object.  If no arguments are
supplied, then all statements in the RDF model will be returned.

Depending on which back-end type being used, different object types
will be returned.  For instance, if L<RDF::Trine> is used, then all
the returned objects will be of type L<RDF::Trine::Statement>.

=head2 get_triples

  @stmts = $rdf->get_triples()
  @stmts = $rdf->get_triples($subject)
  @stmts = $rdf->get_triples($subject, $predicate)
  @stmts = $rdf->get_triples($subject, $predicate, $object)

This method functions in the same way as L</get_statements>, except
instead of the statements being represented as objects, the
statement's values are broken down into plain strings and returned as
an anonymous array.  Therefore, an individual element of the returned
array may look like this:

  [ "http://some/statement/uri", "http://some/predicate/uri", "some object value" ]


=head2 resourcelist

  @subjects = $rdf->resourcelist()
  @subjects = $rdf->resourcelist($predicate)
  @subjects = $rdf->resourcelist($predicate, $object)

This method returns the unique list of subject URIs from within the
RDF model that optionally match the predicate and/or object arguments.
Like in L</get_statements>, either or all of the arguments to this
method can be C<undef>.

=head2 exists

  $result = $rdf->exists()
  $result = $rdf->exists($subject)
  $result = $rdf->exists($subject, $predicate)
  $result = $rdf->exists($subject, $predicate, $object)

Returns a boolean value indicating if any statements exist in the RDF
model that matches the supplied arguments.

=head2 count

  $count = $rdf->count()
  $count = $rdf->count($subject)
  $count = $rdf->count($subject, $predicate)
  $count = $rdf->count($subject, $predicate, $object)

Returns the number of statements that exist in the RDF model that
matches the supplied arguments.  If no arguments are supplied, it
returns the total number of statements in the model are returned.

=head2 include_model

  $rdf->include_model($model)

Include the contents of another, already opened, RDF model into the
current model.

=head2 include_rdfxml

  $rdf->include_rdfxml(xml => $xml_string)
  $rdf->include_rdfxml(filename => $file_path)

This method will import the RDF statements contained in an RDF/XML
document, either from a file or a string, into the current RDF model.
If a L</base_uri> was specified in the L<RDF::Helper>
L<constructor|/"CONSTRUCTOR OPTIONS">, then that URI is used as the
base for when the supplied RDF/XML is imported.  For instance, if the
hash notation is used to reference an RDF node
(e.g. C<E<lt>rdf:Description rdf:about="#dahut"/E<gt>>), the
L</base_uri> will be prepended to the C<rdf:about> URI.

=head2 serialize

  $string = $rdf->serialize()
  $string = $rdf->serialize(format => 'ntriple')
  $rdf->serialize(filename => 'out.rdf')
  $rdf->serialize(filename => 'out.n3', format => 'ntriple')

Serializes the back-end RDF model to a string, using the specified
format type, or defaulting to abbreviated RDF/XML.  The serialization
types depends on which RDF back-end is in use.  The L<RDF::Trine>
support within L<RDF::Helper> supports the following serialization
types:

=over 4

=item * ntriples

=item * nquads

=item * rdfxml

=item * rdfjson

=item * ntriples-canonical

=item * turtle

=back

=head2 new_query

  $query_object = $obj->new_query( $query, [$base_uri, $lang_uri, $lang_name] );

Returns an instance of the class defined by the L<QueryInterface>
argument passed to the constructor (or the default class for the base
interface if none is explicitly set) that can be used to query the
currently selected model.

=head1 PERLISH CONVENIENCE METHODS

=head2 property_hash

  $hash_ref = $rdf->property_hash($subject)

For instances when you don't know what properties are bound to an RDF
node, or when it is too cumbersome to iterate over the results of a
L</get_triples> method call, this method can be used to return all the
properties and values bound to an RDF node as a hash reference.  The
key name will be the predicate URI (QName-encoded if a matching
namespace is found), and the value will be the object value of the
given predicate.  Multiple object values for the same predicate URI
will be returned as an array reference.

It is important to note that this is a read-only dump from the RDF
model.  For a "live" alternative to this, see L</tied_property_hash>.

=head2 deep_prophash

  $hashref = $rdf->deep_prophash($subject)

This method is similar to the L</property_hash> method, except this
method will recurse over children nodes, in effect creating a nested
hashref data structure representing a node and all of its associations.

B<Note:> This method performs no checks to ensure that it doesn't get
stuck in a deep recursion loop, so be careful when using this.

=head2 tied_property_hash

  $hash_ref = $rdf->tied_property_hash($subject)
  $hash_ref = $rdf->tied_property_hash($subject, \%options)

Like L</property_hash>, this method returns a hash reference
containing the predicates and objects bound to the given subject URI.
This method differs however in that any changes to the hash will
immediately be represented in the RDF model.  So if a new value is
assigned to an existing hash key, if a new key is added, or a key is
deleted from the hash, that will transparently be represented as
updates, assertions or removal operations against the model.

Optionally a hash can be passed to this method when tieing a property
hash to give additional instructions to the
L<RDF::Helper::RDFRedland::TiedPropertyHash> object.  Please see the
documentation in that class for more information.

=head2 get_object

  $obj = $rdf->get_object($subject, %options)
  $obj = $rdf->get_object($subject, \%options)

Returns an instance of L<RDF::Helper::Object> bound to the given
subject URI.  This exposes that RDF node as an object-oriented class
interface, allowing you to interact with and change that RDF node and
its properties using standard Perl-like accessor methods.  For more
information on the use of this method, please see
L<RDF::Helper::Object>.


=head2 arrayref2rdf

  $obj->arrayref2rdf(\@list, $subject, $predicate);
  $obj->arrayref2rdf(\@list, undef, $predicate);

Asserts a list of triples with the the subject C<$subject>, predicate
C<$predicate> and object(s) contained in C<\@list>. It the subject is
undefined, a new blank node will be used.

=head2 hashref2rdf

  $object->hashref2rdf( \%hash );
  $object->hashref2rdf( \%hash, $subject );

This method is the reverse of L</property_hash> and L</deep_prophash>
in that it accepts a Perl hash reference and unwinds it into a set
of triples in the RDF store. If the C<$subject> is missing or
undefined a new blank node will be used.


=head2 hashlist_from_statement

  @list = $rdf->hashlist_from_statement()
  @list = $rdf->hashlist_from_statement($subject)
  @list = $rdf->hashlist_from_statement($subject, $predicate)
  @list = $rdf->hashlist_from_statement($subject, $predicate, $object)

Accepting a sparsely populated triple pattern as its argument, this
methods return a list of subject/hash reference pairs for all
statements that match the pattern. Each member in the list will have
the following structure:

  [ $subject, $hash_reference ]

=head1 ACCESSOR METHODS

=head2 model

  $model = $rdf->model()
  $rdf->model($new_model)

An accessor method that can be used to retrieve or set the back-end
RDF model that this L<RDF::Helper> instance uses.

=head2 query_interface

  $iface = $rdf->query_interface()
  $rdf->query_interface($iface)

Accessor method that is used to either set or retrieve the current
class name that should be used for composing and performing queries.

=head1 SEE ALSO

L<RDF::Helper::Object>; L<RDF::Trine>, L<RDF::Redland>; L<RDF::Query>


=head1 SUPPORT

There is a mailing list at L<http://lists.perlrdf.org/listinfo/dev>.

A bunch of people are also hanging out in C<#perlrdf> on C<irc.perl.org>.


=head1 AUTHOR

Kip Hampton, E<lt>khampton@totalcinema.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2011 by Kip Hampton, Chris Prather, Mike Nachbaur

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
