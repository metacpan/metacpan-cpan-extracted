package RDF::RDB2RDF::DatatypeMapper; # this is a mixin

use 5.010;
use strict;
use utf8;

use Math::BigFloat;
use RDF::Trine qw[literal];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use Scalar::Util qw[refaddr blessed];
use URI::Escape qw[uri_escape];

use namespace::clean;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

sub datatyped_literal
{
	my ($self, $value, $sql_datatype) = @_;

	for ($sql_datatype)
	{
		if (!defined)
			{ return literal("$value"); }
		if (/^(?:bp)?char\(?(\d+)\)?/i) # fixed width char strings.
			{ return literal(sprintf("%-$1s", "$value")); }
		if (/^(?:char|bpchar|varchar|string|text|note|memo)/i)
			{ return literal("$value"); }
		if (/^(?:int|smallint|bigint)/i)
			{ return literal("$value", undef, $XSD->integer->uri); }
		if (/^(?:decimal|numeric)/i)
			{ return literal("$value", undef, $XSD->decimal->uri); }
		if (/^(?:float|real|double)/i)
		{
			my ($m, $e) = map { "$_" } Math::BigFloat->new($value)->parts;
			while ($m >= 10.0) {
				$e++;
				$m /= 10.0;
			}
			$m = sprintf('%.8f', $m);
			$m =~ s/0+$//;
			$m =~ s/\.$/.0/;
			$m =~ s/^$/0.0/;
			return literal(sprintf('%sE%d', $m, $e), undef, $XSD->double->uri);
		}
		if (/^(?:binary|varbinary|blob|bytea)/i)
		{
			$value = uc unpack('H*' => $value);
			return literal($value, undef, $XSD->hexBinary->uri);
		}
		if (/^(?:bool)/i)
		{
			$value = ($value and $value !~ /^[nf0]/i) ? 'true' : 'false';
			return literal("$value", undef, $XSD->boolean->uri);
		}
		if (/^(?:timestamp|datetime)/i)
		{
			$value =~ s/ /T/;
			return literal("$value", undef, $XSD->dateTime->uri);
		}
		if (/^(?:date)/i)
			{ return literal("$value", undef, $XSD->date->uri); }
		if (/^(?:time)/i)
			{ return literal("$value", undef, $XSD->time->uri); }
			
		return literal("$value", undef, $self->_dt_uri($sql_datatype));
	}

	literal("$value");
}

sub _dt_uri
{
	my $self = shift;
	sprintf('tag:buzzword.org.uk,2011:rdb2rdf:datatype:%s', uri_escape($_[0]));
}

1;

__END__

=encoding utf8

=head1 NAME

RDF::RDB2RDF::DatatypeMapper - mixin for converting SQL datatypes to RDF (XSD) datatypes

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-RDB2RDF>.

=head1 SEE ALSO

L<RDF::RDB2RDF>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2013 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

