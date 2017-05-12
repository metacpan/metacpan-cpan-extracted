package RDF::Query::Functions::Buzzword::Util;

our $VERSION = '0.003';

use strict;
use Data::UUID;
use RDF::Query::Error qw(:try);
use Scalar::Util qw(blessed reftype refaddr looks_like_number);
use XML::LibXML;

use constant OID_PREFIX => '1.3.6.1.4.1.33926.9';
my $UUID_URI = 'http://buzzword.org.uk/2011/functions/util#_Data::UUID';

sub install
{
	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#uc"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "uc function requires literal argument");
		}

		return RDF::Query::Node::Literal->new(
			uc( $node->literal_value ),
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#lc"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "lc function requires literal argument");
		}

		return RDF::Query::Node::Literal->new(
			lc( $node->literal_value ),
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#ltrim"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "ltrim function requires literal argument");
		}

		(my $trimmed = $node->literal_value) =~ s/^\s+//;

		return RDF::Query::Node::Literal->new(
			$trimmed,
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#rtrim"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "rtrim function requires literal argument");
		}

		(my $trimmed = $node->literal_value) =~ s/\s+$//;

		return RDF::Query::Node::Literal->new(
			$trimmed,
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#trim"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "trim function requires literal argument");
		}

		(my $trimmed = $node->literal_value) =~ s/\s+$//;
		$trimmed =~ s/^\s+//;

		return RDF::Query::Node::Literal->new(
			$trimmed,
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#sprintf"} ||= sub {
		my ($query, $pattern, @nodes) = @_;
		
		unless (blessed($pattern) and $pattern->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "sprintf function requires first argument to be literal");
		}

		my @litnodes = map {
			$_->is_literal ? $_->literal_value : ( $_->is_resource ? $_->uri : $_->as_ntriples )
			} @nodes;

		return RDF::Query::Node::Literal->new(
			sprintf($pattern->literal_value, @litnodes),
			$pattern->literal_value_language,
			$pattern->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#rand"} ||= sub {
		my ($query, $upper, $lower) = @_;
		
		$lower ||= RDF::Trine::Node::Literal->new(0, undef, $upper->literal_datatype);
		
		unless (blessed($lower) and $lower->isa('RDF::Trine::Node::Literal') and $lower->is_numeric_type)
		{
			throw RDF::Query::Error::TypeError(-text => "rand function requires numeric lower bound (e.g. xsd:integer)");
		}

		unless (blessed($upper) and $upper->isa('RDF::Trine::Node::Literal') and $upper->is_numeric_type)
		{
			throw RDF::Query::Error::TypeError(-text => "rand function requires numeric upper bound (e.g. xsd:integer)");
		}

		unless ($lower->literal_datatype eq $upper->literal_datatype)
		{
			throw RDF::Query::Error::TypeError(-text => "rand function requires lower and upper bound to be of same datatype");
		}

		my $rand = $lower->literal_value + rand( $upper->literal_value - $lower->literal_value );
		if ($lower->literal_datatype =~ qr<^http://www.w3.org/2001/XMLSchema#(integer|non(Positive|Negative)Integer|(positive|negative)Integer|long|int|short|byte|unsigned(Long|Int|Short|Byte))$>)
		{
			$rand = int($rand);
		}

		return RDF::Query::Node::Literal->new(
			$rand,
			undef,
			$lower->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#defragment"} ||= sub {
		my ($query, $node) = @_;

		unless (blessed($node) and $node->isa('RDF::Trine::Node::Resource'))
		{
			throw RDF::Query::Error::TypeError(-text => "defragment function requires first argument to be IRI");
		}

		my ($defragged) = split /#/, $node->uri;

		return RDF::Query::Node::Resource->new($defragged);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#str_replace"} ||= sub {
		my ($query, $pattern, $replacement, $node) = @_;

		unless (blessed($pattern)     and $pattern->isa('RDF::Trine::Node::Literal')
		and     blessed($replacement) and $replacement->isa('RDF::Trine::Node::Literal')
		and     blessed($node)        and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "str_replace function requires all three arguments to be literals");
		}

		$pattern     = $pattern->literal_value;
		$replacement = $replacement->literal_value;
		
		my $new_value = $node->literal_value;
		$new_value =~ s/\Q$pattern\E/$replacement/g;

		return RDF::Query::Node::Literal->new(
			$new_value,
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#preg_replace"} ||= sub {
		my ($query, $pattern, $replacement, $node, $mode) = @_;

		$mode ||= RDF::Trine::Node::Literal->new('g');

		unless (blessed($pattern)     and $pattern->isa('RDF::Trine::Node::Literal')
		and     blessed($replacement) and $replacement->isa('RDF::Trine::Node::Literal')
		and     blessed($node)        and $node->isa('RDF::Trine::Node::Literal')
		and     blessed($mode)        and $mode->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "preg_replace function requires all four arguments to be literals");
		}
		
		$pattern     = $pattern->literal_value;
		$replacement = $replacement->literal_value;
		$mode        = $mode->literal_value;
		
		throw RDF::Query::Error::FilterEvaluationError(-text => "preg_replace function passed an invalid mode")
			unless $mode =~ /^[msixpogc]+$/;
		
		my $new_value = $node->literal_value;
		eval '$new_value =~ s/$pattern/$replacement/'.$mode.';';

		return RDF::Query::Node::Literal->new(
			$new_value,
			$node->literal_value_language,
			$node->literal_datatype,
			);
	};


	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#uuid"} ||= sub {
		my ($query) = @_;
		
		$query->{_query_cache}{$UUID_URI} ||= Data::UUID->new;
		my $uuid = $query->{_query_cache}{$UUID_URI};
		
		return RDF::Query::Node::Literal->new($uuid->create_str);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#uuid_uri"} ||= sub {
		my ($query) = @_;
		
		$query->{_query_cache}{$UUID_URI} ||= Data::UUID->new;
		my $uuid = $query->{_query_cache}{$UUID_URI};
		
		return RDF::Query::Node::Resource->new('urn:uuid:' . $uuid->create_str);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#oid"} ||= sub {
		my ($query) = @_;
		
		$query->{_query_cache}{$UUID_URI} ||= Data::UUID->new;
		my $uuid = $query->{_query_cache}{$UUID_URI};
		
		my $hex = $uuid->create_hex;
		$hex =~ s/^0x//i;
		
		my $oid = OID_PREFIX;
		while ($hex)
		{
			my $chunk = substr($hex, 0, 4);
			$hex = substr($hex, 4);
			$oid .= "." . hex($chunk);
		}
		
		return RDF::Query::Node::Literal->new($oid);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#oid_uri"} ||= sub {
		my ($query) = @_;
		
		$query->{_query_cache}{$UUID_URI} ||= Data::UUID->new;
		my $uuid = $query->{_query_cache}{$UUID_URI};
		
		my $hex = $uuid->create_hex;
		$hex =~ s/^0x//i;
		
		my $oid = OID_PREFIX;
		while ($hex)
		{
			my $chunk = substr($hex, 0, 4);
			$hex = substr($hex, 4);
			$oid .= "." . hex($chunk);
		}
		
		return RDF::Query::Node::Resource->new('urn:oid:' . $oid);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#skolem"} ||= sub {
		my ($query, $node, $scheme) = @_;
		$scheme ||= RDF::Trine::Node::Literal->new('UUID');

		unless (blessed($node) and $node->isa('RDF::Trine::Node::Blank'))
		{
			return $node;
		}
		
		my $storage = "http://buzzword.org.uk/2011/functions/util#_SKOLEM";
		$query->{_query_cache}{$storage}{$node->blank_identifier} = do
		{
			if ($scheme->literal_value =~ /^oid$/i)
			{
				$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#oid_uri"}->($query);
			}
			elsif ($scheme->literal_value =~ /^uuid$/i)
			{
				$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#uuid_uri"}->($query);
			}
			else
			{
				throw RDF::Query::Error::FilterEvaluationError(-text => "Only skolemisation schemes supported are OID and UUID.");
			}
		};
		
		return $query->{_query_cache}{$storage}{$node->blank_identifier};
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/util#find_xpath"} ||= sub {
		my ($query, $path, $xmllit, $index) = @_;
		$index ||= RDF::Trine::Node::Literal->new(0, undef, 'http://www.w3.org/2001/XMLSchema#integer');

		unless (blessed($path) and $path->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "find_xpath function requires first argument to be literal");
		}

		unless (blessed($xmllit) and $xmllit->isa('RDF::Trine::Node::Literal') and $xmllit->literal_datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
		{
			throw RDF::Query::Error::TypeError(-text => "find_xpath function requires second argument to be an rdf:XMLLiteral");
		}

		unless (blessed($index) and $index->isa('RDF::Trine::Node::Literal') and $index->is_numeric_type and int($index->literal_value) eq $index->literal_value)
		{
			throw RDF::Query::Error::TypeError(-text => "find_xpath function requires first argument to be an xsd:integer");
		}

		my $doc = '<rdf:XMLLiteral xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
			. $xmllit->literal_value
			. "</rdf:XMLLiteral>";
		my $dom      = XML::LibXML->new->parse_string($doc);
		my $context  = XML::LibXML::XPathContext->new($dom);
		
		my $mappings = $query->{parsed}{namespaces};  # undocumented!
		while (my ($prefix, $namespace_uri) = each %$mappings)
		{
			$context->registerNs($prefix, $namespace_uri)
				unless defined $context->lookupNs($prefix);
		}
		my @nodes = $context->findnodes($path->literal_value);
		if (defined $nodes[ $index->literal_value ])
		{
			return RDF::Query::Node::Literal->new(
				$nodes[ $index->literal_value ]->toString,
				undef,
				'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral',
				);
		}
		else
		{
			return undef;
		}
	};
} #/sub install

1;

__END__

=head1 NAME

RDF::Query::Functions::Buzzword::Util - plugin for buzzword.org.uk utility functions

=head1 SYNOPSIS

  use RDF::TrineX::Functions -shortcuts;
  
  my $data = rdf_parse(<<'TURTLE', type => 'turtle', base => $base_uri);
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
  
  <http://tobyinkster.co.uk/#i>
    foaf:name "Toby Inkster" ;
    foaf:page [ foaf:name "Toby Inkster" ] ;
    foaf:junk "Foo <ex xmlns=\"urn:junk\">Bar</ex>"^^rdf:XMLLiteral ;
    foaf:mbox <mailto:tobyink@cpan.org> .
  TURTLE
  
  my $query = RDF::Query->new(<<'SPARQL');
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX util: <http://buzzword.org.uk/2011/functions/util#>
  PREFIX junk: <urn:junk> 
  SELECT
    ?name
    (util:uc(?name) AS ?ucname)
    (util:trim(util:sprintf(" I am %s "@en, ?name)) AS ?intro)
    (util:skolem(?page, "oid") AS ?skolempage)
    (util:preg_replace("t", "x", ?name, "ig") AS ?mangled)
    (util:find_xpath("//junk:ex", ?junk, 0) AS ?found)
  WHERE
  {
    ?person foaf:name ?name ; foaf:page ?page ; foaf:junk ?junk.
  }
  SPARQL
  
  print $query->execute($data)->as_xml;

=head1 DESCRIPTION

This is a plugin for RDF::Query providing a number of extension functions.

=over

=item * http://buzzword.org.uk/2011/functions/util#defragment

=item * http://buzzword.org.uk/2011/functions/util#find_xpath

=item * http://buzzword.org.uk/2011/functions/util#lc

=item * http://buzzword.org.uk/2011/functions/util#ltrim

=item * http://buzzword.org.uk/2011/functions/util#oid

=item * http://buzzword.org.uk/2011/functions/util#oid_uri

=item * http://buzzword.org.uk/2011/functions/util#preg_replace

=item * http://buzzword.org.uk/2011/functions/util#rand

=item * http://buzzword.org.uk/2011/functions/util#rtrim

=item * http://buzzword.org.uk/2011/functions/util#skolem

=item * http://buzzword.org.uk/2011/functions/util#sprintf

=item * http://buzzword.org.uk/2011/functions/util#str_replace

=item * http://buzzword.org.uk/2011/functions/util#trim

=item * http://buzzword.org.uk/2011/functions/util#uc

=item * http://buzzword.org.uk/2011/functions/util#uuid

=item * http://buzzword.org.uk/2011/functions/util#uuid_uri

=back

Some of these are somewhat close to new functions introduced in SPARQL 1.1.

=begin trustme

=item C<install>

=end trustme

=head1 SEE ALSO

L<RDF::Query>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

