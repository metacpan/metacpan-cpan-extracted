package RDF::Helper::Properties;

# Uhm, well, this should probably also be a role at some point...

use RDF::Trine qw(iri variable statement);
use Types::Standard qw(InstanceOf ArrayRef HashRef Object);
use Scalar::Util qw(blessed);
use Carp qw(confess);
use Moo;
use namespace::autoclean -also => [qw/cached/];

our $VERSION = '0.24';

has model => (
	is         => 'ro',
	isa        => InstanceOf['RDF::Trine::Model'],
	required   => 1,
);

has [qw/ page_properties title_properties /] => (
	is         => 'lazy',
	isa        => ArrayRef[InstanceOf['RDF::Trine::Node::Resource']],
	predicate  => 1,
	clearer    => 1,
);

use constant {
	_build_page_properties => [
		iri( 'http://xmlns.com/foaf/0.1/homepage' ),
		iri( 'http://xmlns.com/foaf/0.1/page' ),
	],
	_build_title_properties => [
		iri( 'http://xmlns.com/foaf/0.1/name' ),
		iri( 'http://purl.org/dc/terms/title' ),
		iri( 'http://purl.org/dc/elements/1.1/title' ),
		iri( 'http://www.w3.org/2004/02/skos/core#prefLabel' ),
		iri( 'http://www.geonames.org/ontology#officialName' ),
		iri( 'http://www.geonames.org/ontology#name' ),
		iri( 'http://purl.org/vocabularies/getty/vp/labelPreferred' ),
		iri( 'http://opengraphprotocol.org/schema/title' ),
		iri( 'http://www.w3.org/2000/01/rdf-schema#label' ),
		# doap ?
	],
};

has cache => (
	is         => 'rw',
	isa        => HashRef|Object,
	lazy       => 1,
	builder    => 1,
	predicate  => 1,
	clearer    => 1,
);

sub _build_cache
{
	+{
		title => {
			'<http://www.w3.org/2000/01/rdf-schema#label>'       => 'label',
			'<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>'  => 'type',
		},
		pred => {
			'<http://www.w3.org/2000/01/rdf-schema#label>'       => 'label',
			'<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>'  => 'type',
			'<http://purl.org/dc/elements/1.1/type>'             => 'Type',
		},
	};
}

sub _cache_set
{
	my ($self, $type, $uri, $value) = @_;
	my $cache = $self->cache;
	if (blessed $cache)
		{ $cache->set("$type$uri" => $value) }
	else
		{ $cache->{$type}{$uri} = $value }
	return $value;
}

sub _cache_get
{
	my ($self, $type, $uri) = @_;
	my $cache = $self->cache;
	if (blessed $cache)
		{ return $cache->get("$type$uri") }
	else
		{ return $cache->{$type}{$uri} }
}

# Helper function, cleaned away by namespace::autoclean
sub cached
{
	my ($method_name, $coderef) = @_;
	no strict 'refs';
	*{$method_name} = sub
	{
		my ($self, $node) = @_;
		my $return = $self->_cache_get($method_name, $node)
			|| $self->_cache_set($method_name, $node, $self->$coderef($node));
		
		if (blessed $return and $return->isa('RDF::Trine::Node'))
		{
			if ($return->is_literal)
			{
				return wantarray
					? ($return->literal_value, $return->literal_value_language, $return->literal_datatype)
					: $return->literal_value;
			}
			elsif ($return->is_resource)
			{
				return $return->uri_value;
			}
			else
			{
				return $return->as_string;
			}
		}
		
		return $return;
	}
}

cached page => sub
{
	my ($self, $node) = @_;
	
	confess "Node argument needs to be a RDF::Trine::Node::Resource."
		unless $node && $node->isa('RDF::Trine::Node::Resource');
	
	my @props = @{ $self->page_properties };
	
	my ($object) =
		grep { blessed $_ and $_->is_resource }
		scalar $self->model->objects_for_predicate_list($node, @props);
	($object) =
		grep { blessed $_ and $_->is_resource }
		$self->model->objects_for_predicate_list($node, @props)
		unless $object;
	
	return $object if $object;
	
	# Return the common link to ourselves
	return iri($node->uri_value . '/page');
};

cached title => sub
{
	my ($self, $node) = @_;
	
	my @props = @{ $self->title_properties };
	
	my ($object) =
		grep { blessed $_ and $_->is_literal }
		scalar $self->model->objects_for_predicate_list($node, @props);
	($object) =
		grep { blessed $_ and $_->is_literal }
		$self->model->objects_for_predicate_list($node, @props)
		unless $object;
	
	return $object if $object;
	
	# and finally fall back on just returning the node
	return $node;
};

cached description => sub
{
	my ($self, $node) = @_;
	my $model = $self->model;
	
	my $iter  = $model->get_statements( $node );
	my @label = @{ $self->title_properties };
	
	my @desc;
	while (my $st = $iter->next)
	{
		my $p = $st->predicate;
		my $ps;
		
		if ($ps = $self->_cache_get(pred => $p))
			{ 1 }
		
		elsif (my $pname = $model->objects_for_predicate_list($p, @label))
			{ $ps = $self->html_node_value( $pname ) }
		
		elsif ($p->is_resource and $p->uri_value =~ m<^http://www.w3.org/1999/02/22-rdf-syntax-ns#_(\d+)$>)
			{ $ps = '#' . $1 }
		
		else
		{
			# try to turn the predicate into a qname and use the local part as the printable name
			my $name;
			eval {
				(undef, $name) = $p->qname;
			};
			$ps = _escape( $name || $p->uri_value );
		}
		
		$self->_cache_set(pred => $p, $ps);
		my $obj = $st->object;
		my $os  = $self->html_node_value( $obj, $p );
		
		push(@desc, [$ps, $os]);
	}
	
	return \@desc;
};

sub html_node_value
{
	my $self       = shift;
	my $n          = shift;
	my $rdfapred   = shift;
	my $qname      = '';
	my $xmlns      = '';
	
	if ($rdfapred)
	{
		eval {
			my ($ns, $ln) = $rdfapred->qname;
			$xmlns        = qq[xmlns:ns="${ns}"];
			$qname        = qq[ns:$ln];
		};
	}
	
	return '' unless blessed $n;
	
	if ($n->is_literal)
	{
		my $l = _escape( $n->literal_value );
		
		return $qname
			? qq[<span $xmlns property="${qname}">$l</span>]
			: $l;
	}
	
	elsif ($n->is_resource)
	{
		my $uri    = _escape( $n->uri_value );
		my $title  = _escape( $self->title($n) );
		
		return $qname
			? qq[<a $xmlns rel="${qname}" href="${uri}">$title</a>]
			: qq[<a href="${uri}">$title</a>];
	}
	
	else
	{
		return $n->as_string;
	}
}

sub _escape
{
	my $l = shift;
	for ($l)
	{
		s/&/&amp;/g;
		s/</&lt;/g;
		s/"/&quot;/g;
	}
	return $l;
}

__PACKAGE__->meta->make_immutable || 1;
__END__

=head1 NAME

RDF::Helper::Properties - Module that provides shortcuts to retrieve certain information

=head1 VERSION

Version 0.22

=head1 SYNOPSIS

 my $helper = RDF::Helper::Properties->new($model);
 print $helper->title($node);

=head1 DESCRIPTION

=head2 Constructor

=over

=item C<< new(model => $model, %attributes) >>

Moose-style constructor.

=back

=head2 Attributes

=over

=item C<< model >>

The RDF::Trine::Model which data will be extracted from. The only attribute
which the constructor requires.

=item C<< page_properties >>

An arrayref of RDF::Trine::Node::Resource objects, each of which are
taken to mean "something a bit like foaf:homepage". There is a sensible
default.

=item C<< title_properties >>

An arrayref of RDF::Trine::Node::Resource objects, each of which are
taken to mean "something a bit like foaf:name". There is a sensible
default.

=item C<< cache >>

A hashref for caching data into, or a blessed object which supports C<get>
and C<set> methods compatible with L<CHI> and L<Cache::Cache>. If you do not
supply a cache, then a hashref will be used by default.

=back

=head2 Methods

=over

=item C<< page($node) >>

A suitable page to redirect to, based on foaf:page or foaf:homepage.

=item C<< title($node) >>

A suitable title for the document will be returned, based on document contents.

Called in list context, returns a ($value, $lang, $datatype) tuple.

=item C<< description($node) >>

A suitable description for the document will be returned, based on document contents

=item C<< html_node_value($node) >>

Formats the nodes for HTML output.

=back

=begin private

=item C<< cached($subname, $coderef) >>

Install a cached version of a sub.

=end private

=head1 AUTHOR

Most of the code was written by Gregory Todd Williams C<<
<gwilliams@cpan.org> >> for L<RDF::LinkedData::Apache>, but refactored
into this class for use by other modules by Kjetil Kjernsmo, C<<
<kjetilk at cpan.org> >>, then refactored again by Toby Inkster,
C<< <tobyink at cpan.org> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Gregory Todd Williams and ABC Startsiden AS.

Copyright 2012 Toby Inkster.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

