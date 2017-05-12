package RDF::TrineX::Functions;

use 5.010;
use strict qw< vars subs >;
no warnings;
use utf8;

BEGIN {
	$RDF::TrineX::Functions::AUTHORITY = 'cpan:TOBYINK';
	$RDF::TrineX::Functions::VERSION   = '0.005';
}

use Carp qw< croak >;
use IO::Detect 0.003 qw< is_filehandle is_filename is_fileuri >;
use PerlX::Maybe qw< maybe >;
use RDF::NS::Trine;
use RDF::Trine qw< store >;
use RDF::Trine::Namespace qw< rdf rdfs owl xsd >;
use Scalar::Util qw< blessed >;
use URI::file;

use Sub::Exporter -setup => {
	exports => [
		qw< curie iri blank variable literal statement store model parse >,
		serialize => \&_build_serializer,
	],
	groups => {
		nodes     => [qw< curie iri blank literal variable >],
		shortcuts => [
			parse     => { -as => 'rdf_parse' },
			serialize => { -as => 'rdf_string' },
		],
		shortcuts_nodes => [
			parse     => { -as => 'rdf_parse' },
			serialize => { -as => 'rdf_string' },
			iri       => { -as => 'rdf_resource' },
			blank     => { -as => 'rdf_blank' },
			literal   => { -as => 'rdf_literal' },
			variable  => { -as => 'rdf_variable' },
			statement => { -as => 'rdf_statement' },
		],
	},
};

foreach my $nodetype (qw< iri blank variable literal >)
{
	my $orig = $nodetype eq 'iri'
		? sub { RDF::Trine::Node::Resource->new(@_) }
		: RDF::Trine->can($nodetype);
		
	my $sub;
	$sub = sub
	{
		shift if blessed $_[0] && $_[0]->isa(__PACKAGE__);
		return $sub->(@{$_[0]}) if ref $_[0] eq 'ARRAY';
	
		my $node = shift;
		
		if (blessed($node) and $node->isa('RDF::Trine::Node'))
		{
			return $node;
		}
		
		if ($nodetype eq 'iri' and blessed($node) and $node->isa('URI'))
		{
			return $orig->("$node", @_);
		}
		elsif ($nodetype eq 'literal' and blessed($node) and $node->isa('URI'))
		{
			$_[1] //= $xsd->anyURI unless $_[0];
			return $orig->("$node", @_);
		}
		
		if ($nodetype =~ m[^(iri|blank)$] and $node =~ /^_:(.+)$/)
		{
			return RDF::Trine::blank($1, @_);
		}
		
		if ($nodetype =~ m[^(variable|blank)$] and $node =~ /^\?(.+)$/)
		{
			return RDF::Trine::variable($1, @_);
		}
		
		$orig->("$node", @_);
	};
	
	*$nodetype = $sub;
}

sub new
{
	my ($class, @args) = @_;
	bless \@args, $class;
}

sub curie
{
	shift if blessed $_[0] && $_[0]->isa(__PACKAGE__);
	return curie(@{$_[0]}) if ref $_[0] eq 'ARRAY';
	
	my $node = shift;
	
	if (blessed($node) and $node->isa('RDF::Trine::Node'))
	{
		return $node;
	}
	
	if (blessed($node) and $node->isa('URI'))
	{
		return RDF::Trine::iri("$node", @_);
	}
	
	if ($node =~ /^_:(.+)$/)
	{
		return RDF::Trine::blank($1, @_);
	}
	
	state $ns = RDF::NS::Trine->new('any');
	$ns->URI($node);
}

sub statement
{
	shift if blessed $_[0] && $_[0]->isa(__PACKAGE__);
	return statement(@{$_[0]}) if ref $_[0] eq 'ARRAY';
	
	my (@nodes) = map {
		if (blessed($_) and $_->isa('RDF::Trine::Node'))  { $_ }
		elsif (blessed($_) and $_->isa('URI'))            { iri($_) }
		else                                              { literal($_) }
	} @_;
	
	(@nodes==4)
		? RDF::Trine::Statement::Quad->new(@nodes)
		: RDF::Trine::Statement->new(@nodes)
}

sub model
{
	shift if blessed $_[0] && $_[0]->isa(__PACKAGE__);
	return model(@{$_[0]}) if ref $_[0] eq 'ARRAY';
	
	my $store = shift;
	return $store if blessed($store) && $store->isa('RDF::Trine::Model');
	
	$store
		? RDF::Trine::Model->new($store)
		: RDF::Trine::Model->new()
}

sub parse
{
	shift if blessed $_[0] && $_[0]->isa(__PACKAGE__);
	return parse(@{$_[0]}) if ref $_[0] eq 'ARRAY';
	
	my ($thing, %opts) = @_;
	
	my $model  = delete($opts{into})   // delete($opts{model});
	my $base   = delete($opts{base});
	my $parser = delete($opts{parser}) // delete($opts{type})  // delete($opts{as}) // delete($opts{using});
	my $graph  = delete($opts{graph})  // delete($opts{context});

	# Normalise $graph.
	#
	$graph = iri($graph) if defined $graph;

	if (blessed($thing) && $thing->isa('RDF::Trine::Store')
	or  blessed($thing) && $thing->isa('RDF::Trine::Model'))
	{
		return model($thing) unless $model;
		
		$thing->as_stream->each(sub {
			my ($s, $p, $o) = shift->nodes;
			$model->add_statement(
				$graph
					? statement($s, $p, $o, $graph)
					: statement($s, $p, $o)
			);
		});
		return $model;
	}
	
	$model //= model();
	return $model unless defined $thing;
	
	# Normalise $parser. It should be a class name or blessed object.
	# If undef, then 'RDF::Trine::Parser' class.
	# If media type then, figure out correct parser.
	# If format name then, figure out correct parser.
	#
	if (not $parser)
		{ $parser = 'RDF::Trine::Parser' }
	elsif (not blessed $parser and $parser =~ m{/} and $parser !~ m{^RDF/}i)
		{ $parser = RDF::Trine::Parser->parser_by_media_type($parser)->new }
	elsif (not blessed $parser)
		{ $parser = RDF::Trine::Parser->new($parser) }	

	# Normalise $base. Accept RDF::Trine::Nodes.
	#
	if (blessed $base and $base->isa('RDF::Trine::Node::Resource'))
	{
		$base = $base->uri;
	}	

	# Deal with $thing being a URI.
	# "file://" is explicitly not handled here.
	#
	if (blessed($thing) && $thing->isa('URI')
	or  blessed($thing) && $thing->isa('RDF::Trine::Node::Resource') && ($thing = $thing->uri)
	or !blessed($thing) && $thing =~ m{^(https?|ftp|file|data):\S+$})
	{
		if (is_fileuri $thing)
		{
			# Convert to a local path, and allow to fall through...
			URI->new("$thing")->file;
		}
		elsif (not ref $parser and $parser eq 'RDF::Trine::Parser')
		{
			RDF::Trine::Parser->parse_url_into_model(
				"$thing",
				$model,
				maybe context => $graph,
			);
			return $model;
		}
		else
		{
			# UA string consistent with RDF::Trine::Parser
			my $ua   = LWP::UserAgent->new(agent => "RDF::Trine/$RDF::Trine::VERSION");
			my $resp = $ua->get("$thing");
			$parser->parse_into_model(
				("$base"//"$thing"),
				$resp->decoded_content,
				$model,
				maybe context => $graph,
			);
			return $model;
		}
	}
	
	# Deal with $thing being a filename.
	#
	if (is_filename $thing)
	{
		$base //= URI::file->new_abs("$thing");
		$parser->parse_file_into_model(
			"$base",
			"$thing",
			$model,
			maybe context => $graph,
		);
		return $model;
	}
	
	croak "No base URI provided" unless $base;
	
	# Deal with $thing being a filehandle (or something similar).
	#
	if (is_filehandle $thing)
	{
		$parser->parse_file_into_model(
			"$base",
			$thing,
			$model,
			maybe context => $graph,
		);
		return $model;
	}
	
	croak "No parser provided for parsing" unless blessed $parser;
	$parser->parse_into_model(
		"$base",
		$thing,
		$model,
		maybe context => $graph,
	);
	
	return $model;
}

sub _build_serializer
{
	my ($class, $name, $arg) = @_;
	
	my $sub;
	$sub = sub
	{
		shift if blessed $_[0] && $_[0]->isa(__PACKAGE__);
		return $sub->(@{$_[0]}) if ref $_[0] eq 'ARRAY';
		
		my ($data, %opts) = do {
			(@_==2)
				? ($_[0], as => $_[1])
				: @_
		};
		
		my $ser = delete($opts{serializer})
			// delete($opts{type})
			// delete($opts{as})
			// delete($opts{using})
			// $arg->{type}
			// $arg->{-type}
			// 'Turtle';
		
		my $file = delete($opts{to})
			// delete($opts{file})
			// delete($opts{output});
		
		if (not blessed $ser)
		{
			$ser = RDF::Trine::Serializer->new($ser, %opts);
		}
		
		if (blessed $data and $data->isa('RDF::Trine::Iterator'))
		{
			return defined($file)
				? $ser->serialize_iterator_to_file($file, $data)
				: $ser->serialize_iterator_to_string($data);
		}
		
		return defined($file)
			? $ser->serialize_model_to_file($file, $data)
			: $ser->serialize_model_to_string($data);
	}
}

*serialize = __PACKAGE__->_build_serializer(serialize => {});

__PACKAGE__
__END__

=head1 NAME

RDF::TrineX::Functions - some shortcut functions for RDF::Trine's object-oriented interface

=head1 SYNOPSIS

  use RDF::TrineX::Functions -all;
  
  my $model = model();
  parse('/tmp/mydata.rdf', into => $model);
  
  $model->add_statement(statement(
      iri('http://example.com/'),
      iri('http://purl.org/dc/terms/title'),
      "An Example",
  ));
  
  print RDF::Trine::Serializer
      -> new('Turtle')
      -> serialize_model_to_string($model);

=head1 DESCRIPTION

This is a replacement for the venerable RDF::TrineShortcuts. Not a
drop-in replacement. It has fewer features, fewer dependencies,
less hackishness, less magic and fewer places it can go wrong.

It uses Sub::Exporter, which allows exported functions to be renamed
easily:

  use RDF::TrineX::Functions
    parse => { -as => 'parse_rdf' };

=head2 Functions

=over

=item C<iri>, C<literal>, C<blank>, C<variable>

As per the similarly named functions exported by L<RDF::Trine> itself.

These are wrapped with a very tiny bit of DWIMmery. A blessed L<URI>
object passed to C<iri> will be handled properly; a blessed URI
object passed to C<literal> will default the datatype to xsd:anyURI.
A string starting with "_:" passed to either C<iri> or C<blank> will
correctly create a blank node. A string starting with "?" passed to
either C<blank> or C<variable> will correctly create a variable. If
any of them are passed an existing RDF::Trine::Node, it will be
passed through untouched.

Other than that, no magic.

=item C<< curie >>

Like C<iri> but passes strings through L<RDF::NS::Trine>.

=item C<< statement(@nodes) >>

As per the similarly named function exported by L<RDF::Trine> itself.

Again, a tiny bit of DWIMmery: blessed URI objects are passed through
C<iri> and unblessed scalars (i.e. strings) are assumed to be literals.

=item C<store>

As per the similarly named function exported by L<RDF::Trine> itself.

=item C<model>

Returns a new RDF::Trine::Model. May be passed a store as a parameter.

=item C<< parse($source, %options) >>

Parses the source and returns an RDF::Trine::Model. The source may be:

=over

=item * a URI

A string URI, blessed URI object or RDF::Trine::Node::Resource, which
will be retrieved and parsed.

=item * a file

A filehandle, L<Path::Class::File>, L<IO::All>, L<IO::Handle> object,
or the name of an existing file (i.e. a scalar string). The file will
be read and parsed.

Except in the case of L<Path::Class::File>, L<IO::All> and strings,
you need to tell the C<parse> function what parser to use, and what
base URI to use.

=item * a string

You need to tell the C<parse> function what parser to use, and what
base URI to use.

=item * a model or store

An existing model or store, which will just be returned as-is.

=item * undef

Returns an empty model.

=back

The C<parser> option can be used to provide a blessed L<RDF::Trine::Parser>
object to use; the C<type> option can be used instead to provide a media
type hint. The C<base> option provides the base URI. The C<model> option
can be used to tell this function to parse into an existing model rather
than returning a new one. The C<graph> option may be used to provide a graph
URI.

C<into> is an alias for C<model>; C<type>, C<using> and C<as> are
aliases for C<parser>; C<context> is an alias for C<graph>.

Examples:

  my $model = parse('/tmp/data.ttl', as => 'Turtle');

  my $data   = iri('http://example.com/data.nt');
  my $parser = RDF::Trine::Parser::NTriples->new;
  my $model  = model();
  
  parse($data, using => $parser, into => $model);

=item C<< serialize($data, %options) >>

Serializes the data (which can be an RDF::Trine::Model or an
RDF::Trine::Iterator) and returns it as a string.

The C<serializer> option can be used to provide a blessed
L<RDF::Trine::Serializer> object to use; the C<type> option can be used
instead to provide a type hint. The C<output> option can be used to
provide a filehandle, IO::All, Path::Class::File or file name to
write to instead of returning the results as a string.

C<to> and C<file> are aliases for C<output>; C<type>, C<using> and C<as>
are aliases for C<serializer>.

Examples:

  print serialize($model, as => 'Turtle');

  my $file = Path::Class::File->new('/tmp/data.nt');
  serialize($iterator, to => $file, as => 'NTriples');

=back

=head2 Array References

In addition to the above interface, each function supports being called with a
single arrayref argument. In those cases, the arrayref is dereferenced into an
array, and treated as a list of arguments. That is, the following are
equivalent:

  foo($bar, $baz);
  foo([$bar, $baz]);

This is handy if you're writing a module of your own and wish to accept some
RDF data:

  sub my_method {
    my ($self, $rdf, $foo) = @_;
    $rdf = parse($rdf);
    
    ....
  }

Your method can now be called like this:

  $object->my_method($model, 'foo');
  
  $object->my_method($url, 'foo');
  
  $object->my_method(
      [ $filehandle, as => 'Turtle', base => $uri ],
      'foo',
  );

=head2 Export

By default, nothing is exported. You need to request things:

  use RDF::TrineX::Functions qw< iri literal blank statement model >;

Thanks to L<Sub::Exporter>, you can rename functions:

  use RDF::TrineX::Functions
    qw< literal statement model >,
    blank => { -as => 'bnode' },
    iri   => { -as => 'resource' };

If you want to export everything, you can do:

  use RDF::TrineX::Functions -all;

To export just the functions which generate RDF::Trine::Node objects:

  use RDF::TrineX::Functions -nodes;

Or maybe even:

  use RDF::TrineX::Functions -nodes => { -suffix => '_node' };

If you want to export something roughly compatible with the old
RDF::TrineShortcuts, then there's:

  use RDF::TrineX::Functions -shortcuts;

When exporting the C<serialize> function you may set a default format:

  use RDF::TrineX::Functions
      serialize => { -type => 'NTriples' };

This will be used when C<serialize> is called with no explicit type given.

=head2 Pseudo-OO interface

=over

=item C<new>

This acts as a constructor, returning a new RDF::TrineX::Functions object.

=back

All the normal functions can be called as methods:

 my $R = RDF::TrineX::Functions->new;
 my $model = $R->model;

There's no real advantage to using this module as an object, but it can
help you avoid namespace pollution.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Functions>.

=head1 SEE ALSO

L<RDF::Trine>, L<RDF::QueryX::Lazy>, L<RDF::NS>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

