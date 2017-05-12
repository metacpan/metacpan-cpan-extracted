package RDF::Crypt::Role::DoesSign;

use 5.010;
use Any::Moose 'Role';

use Encode qw(encode);
use RDF::TrineX::Functions -shortcuts;

use namespace::clean;

BEGIN {
	$RDF::Crypt::Role::DoesSign::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::DoesSign::VERSION   = '0.002';
}

requires 'sign_bytes';
requires 'SIG_MARK';

sub sign_text
{
	my ($self, $text) = @_;
	$self->sign_bytes(
		encode('utf-8', $text),
	);
}

sub generate_manifest
{
	my ($self, $my_webid, $uris) = @_;
	my $data = {};
	my $i    = 0;
	
	foreach my $u (@$uris)
	{
		my $model = rdf_parse($u);
		my $blank = '_:sig'.(++$i);
		
		push @{ $data->{$u}{'http://xmlns.com/wot/0.1/assurance'} },
			{ type=>'blank', value=>$blank };
		
		push @{ $data->{$blank}{'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'} },
			{ type=>'uri', value=>'http://xmlns.com/wot/0.1/Endorsement' };
		
		push @{ $data->{$blank}{'http://ontologi.es/wotox#signer'} },
			{ type=>'uri', value=>$my_webid };
			
		push @{ $data->{$blank}{'http://ontologi.es/wotox#scheme'} },
			{ type=>'uri', value=>'http://ontologi.es/wotox#RDF-Crypt' };
		
		push @{ $data->{$blank}{'http://ontologi.es/wotox#signedAt'} },
			{ type=>'literal', value=>DateTime->now->strftime('%FT%T%z'), datatype=>'http://www.w3.org/2001/XMLSchema#dateTime' };
		
		push @{ $data->{$blank}{'http://ontologi.es/wotox#signature'} },
			{ type=>'literal', value=>$self->sign_model($model) };
	}
	
	my $rv = RDF::Trine::Model->temporary_model;
	$rv->add_hashref($data);
	
	return $rv;
}

sub sign_model
{
	my ($self, $model) = @_;
	my $ser = RDF::Trine::Serializer::NTriples::Canonical->new(onfail=>'truncate');
	my $canonical = $ser->serialize_model_to_string($model);
	return $self->sign_text($canonical);
}

sub sign_embed_turtle
{
	my ($self, $turtle, $base) = @_;
	
	my $parser = RDF::Trine::Parser::Turtle->new;
	my $model  = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model($base, $turtle, $model);
	
	my $signature = $self->sign_model($model);
	
	$turtle .= sprintf("\n\n# {%s{%s}}", $self->SIG_MARK, $signature);
	
	return $turtle;
}

sub sign_embed_rdfxml
{
	my ($self, $turtle, $base) = @_;
	
	my $parser = RDF::Trine::Parser::RDFXML->new;
	my $model  = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model($base, $turtle, $model);
	
	my $signature = $self->sign_model($model);
	
	$turtle .= sprintf("\n<!-- {%s{%s}} -->", $self->SIG_MARK, $signature);
	
	return $turtle;
}

sub sign_embed_rdfa
{
	my ($self, $rdfa, $base, $config, $return_dom) = @_;
	
	my $p;
	if (Scalar::Util::blessed($rdfa) && $rdfa->isa('RDF::RDFa::Parser'))
	{
		$p = $rdfa;
		$rdfa = $p->dom->toString;
	}
	else
	{
		$p = RDF::RDFa::Parser->new($rdfa, $base, $config);
		$rdfa = $rdfa->toString if ref $rdfa;
	}
	
	$p->consume;
	my $model   = $p->graph;
	my $sig     = $self->sign_model($model);
	my $sigmark = $self->SIG_MARK;
	
	$p->dom->documentElement->setAttribute($sigmark, $sig);
	
	return $return_dom ? $p->dom : $p->dom->toString;
}

1;


__END__

=head1 NAME

RDF::Crypt::Role::DoesSign - signing methods

=head1 DESCRIPTION

=head2 Object Methods

=over

=item C<< sign_model($model) >>

Given an L<RDF::Trine::Model>, returns a signature as a string.

The model is converted to a canonicalised N-Triples representation (see
L<RDF::Trine::Serializer::NTriples::Canonical>) with any triples that
cannot be canonicalised being truncated. This representation is then
signed using an MD5 digest, and the resulting binary signature encoded
using base64.

=item C<< generate_manifest($webid, \@urls) >>

Given a WebID that people can use to recover your public key, and a
list of URLs that need signing, signs each and returns an
L<RDF::Trine::Model> containing the results of processing. This
can be serialised as, say, Turtle to act as an endorsement for
a bunch of RDF graphs.

=item C<< sign_embed_turtle($turtle, $baseuri) >>

Parses the given Turtle into a model, generates a signature for that
and then returns the original Turtle with the signature embedded as
a comment. This allows the signature to sit in the same file as the
data itself.

The base URI is used to resolve any relative URI references. Note that
if a different base URI is provided when verifying the signature, this
may cause verification to fail. The base URI is optional.

=item C<< sign_embed_rdfxml($xml, $baseuri) >>

As per C<sign_embed_turtle>, but RDF/XML.

=item C<< sign_embed_rdfa($html, $baseuri, \%config) >>

Similar to C<sign_embed_turtle> and C<sign_embed_rdfxml>. The base
URI is required. A set of configuration options may be provided,
which will be passed along to L<RDF::RDFa::Parser>'s constructor.

Rather than storing the signature as an XML/HTML comment, the
signature is stored on the root element as an attribute.

=item C<< sign_text($str) >>

Signs a literal string which may or may not have anything to do with RDF.

=back

=head2 Required Methods

This role does not implement these methods, but requires classes to
implement them instead:

=over

=item C<< sign_bytes($str) >>

Generates a signature for an octet string.

=item C<< SIG_MARK >>

Returns a string used as a marker for signatures within serialised RDF.

=back

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Signer>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

