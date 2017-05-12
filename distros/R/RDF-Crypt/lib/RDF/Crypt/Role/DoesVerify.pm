package RDF::Crypt::Role::DoesVerify;

use 5.010;
use Any::Moose 'Role';

use Encode qw(encode);
use RDF::TrineX::Functions -shortcuts;
use RDF::Query;
use RDF::Crypt::ManifestItem;

use namespace::clean;

BEGIN {
	$RDF::Crypt::Role::DoesVerify::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::Role::DoesVerify::VERSION   = '0.002';
}

requires 'verify_bytes';
requires 'SIG_MARK';

sub verify_text
{
	my ($self, $text, $signature) = @_;
	$self->verify_bytes($text, $signature);
}

sub verify_manifest
{
	my ($class, $data, %opts) = @_;
	
	confess "$class cannot new_from_webid"
		unless $class->can('new_from_webid');
	
	$data = rdf_parse($data, %opts);
	
	my $query_string = <<'QUERY';
	PREFIX wot: <http://xmlns.com/wot/0.1/>
	PREFIX wotox: <http://ontologi.es/wotox#>
	SELECT *
	{
		?document wot:assurance ?assurance .
		?assurance wotox:signature ?signature ; wotox:signer ?signer .
		OPTIONAL { ?assurance wotox:scheme ?scheme . }
		OPTIONAL { ?assurance wotox:signedAt ?signedAt . }
		FILTER (isIRI(?signer) && isIRI(?document))
	}
QUERY

	my $results = RDF::Query->new($query_string)->execute($data);
	my (%docs, %webids, @rows);
	
	while (my $row = $results->next)
	{
		if (defined $row->{scheme}
		and $row->{scheme}->uri ne 'http://ontologi.es/wotox#RDF-Crypt')
		{
			next;
		}
		
		$docs{ $row->{document} } ||= rdf_parse($row->{document});

		my $verifier = do 
		{
			my $s = $row->{signer};
			if (blessed($class) and $class->does(__PACKAGE__))
				{ $class }
			else
				{ $webids{$s} ||= $class->new_from_webid($s) }
		};

		push @rows, RDF::Crypt::ManifestItem->new(
			manifest     => $data,
			scheme       => ($row->{scheme} ? $row->{scheme}->uri : 'http://ontologi.es/wotox#RDF-Crypt'),
			verification => scalar($verifier->verify_model($docs{ $row->{document} }, $row->{signature})),
			document     => $row->{document}->uri,
			signature    => $row->{signature}->literal_value,
			signer       => $row->{signer},
			signed_at    => ($row->{signedAt} ? $row->{signedAt}->literal_value : undef),
		);
	}
	
	return @rows;
}

sub verify_model
{
	state $ser = RDF::Trine::Serializer::NTriples::Canonical->new(
		onfail => 'truncate',
	);
	my ($self, $model, $signature) = @_;
	
	$self->verify_text(
		$ser->serialize_model_to_string($model),
		$signature,
	);
}

sub verify_embedded_turtle
{
	my ($self, $turtle, $base) = @_;
	
	my $sigmark = $self->SIG_MARK;
	if ($turtle =~ /\{$sigmark\{([^\}]+)\}\}/)
	{
		my $sig = $1;
		
		my $parser = RDF::Trine::Parser::Turtle->new;
		my $model  = RDF::Trine::Model->temporary_model;
		$parser->parse_into_model($base, $turtle, $model);
		
		return $self->verify_model($model, $sig);
	}
	
	return undef;
}

sub verify_embedded_rdfxml
{
	my ($self, $rdfxml, $base) = @_;
	
	my $sigmark = $self->SIG_MARK;
	if ($rdfxml =~ /\{$sigmark\{([^\}]+)\}\}/)
	{
		my $sig = $1;
		
		my $parser = RDF::Trine::Parser::RDFXML->new;
		my $model  = RDF::Trine::Model->temporary_model;
		$parser->parse_into_model($base, $rdfxml, $model);
		
		return $self->verify_model($model, $sig);
	}
	
	return undef;
}

sub verify_embedded_rdfa
{
	my ($self, $rdfa, $base, $config) = @_;
	
	my $p;
	if (blessed $rdfa && $rdfa->isa('RDF::RDFa::Parser'))
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
	my $sig     = undef;
	my $sigmark = $self->SIG_MARK;
	
	if ($p->dom->documentElement->hasAttribute($sigmark))
	{
		$sig = $p->dom->documentElement->getAttribute($sigmark);
	}
	elsif ($rdfa =~ /\{$sigmark\{([^\}]+)\}\}/)
	{
		$sig = $1;
	}
	
	return unless defined $sig;
	return $self->verify_model($model, $sig);
}

1;

__END__

=head1 NAME

RDF::Crypt::Role::DoesVerify - verification methods

=head1 DESCRIPTION

=head2 Class Methods

=over

=item C<< verify_manifest($manifest) >>

Given a manifest created by the Signer, attempts to verify each signature
in it. Returns a list of RDF::Crypt::ManifestItem objects.

May also be called as an object method in which case it ignores the
manifest's information about who signed each thing, and instead assumes
that the current object's keys are sufficient to verify the signature.

=back

=head2 Object Methods

=over

=item C<< verify_model($model, $signature) >>

Returns true if verification was successful; false but defined if
verification failed; undefined if verification was not attempted
for some reason.

=item C<< verify_embedded_turtle($turtle, $baseuri) >>

Counterpart to C<sign_embed_turtle> from L<RDF::Crypt::Role::DoesSign>.

=item C<< verify_embedded_rdfxml($xml, $baseuri) >>

Counterpart to C<sign_embed_rdfxml> from L<RDF::Crypt::Role::DoesSign>.

=item C<< verify_embedded_rdfa($html, $baseuri, \%config) >>

Counterpart to C<sign_embed_rdfa> from L<RDF::Crypt::Role::DoesSign>.

=item C<< verify_text($str, $signature) >>

Verifies a character string which may or may not have anything to do with RDF.

=back

=head2 Required Methods

This role does not implement these methods, but requires classes to
implement them instead:

=over

=item C<< verify_bytes($str, $signature) >>

Verifies that an octet string satisfies the signature.

=item C<< SIG_MARK >>

Returns a string used as a marker for signatures within serialised RDF.

=back

=head1 SEE ALSO

L<RDF::Crypt>,
L<RDF::Crypt::Verifier>,
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

