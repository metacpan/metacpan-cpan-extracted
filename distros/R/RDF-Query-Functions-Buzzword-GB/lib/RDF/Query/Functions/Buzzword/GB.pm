package RDF::Query::Functions::Buzzword::GB;

our $VERSION = '0.002';

use strict;
use RDF::Query::Error qw(:try);
use RDF::Trine::Namespace qw[XSD];
use Scalar::Util qw[blessed];

sub install
{
	# Various types of UK postcodes, for later use.
	my %PostcodeRE;
	$PostcodeRE{'area'}     = '([A-PR-UWYZ][A-HK-Y]?)';
	$PostcodeRE{'district'} = '([0-9]{1,2}|[1-9][A-HJKMNPR-Y])';
	$PostcodeRE{'space'}    = '\s+';
	$PostcodeRE{'space?'}   = '\s*';
	$PostcodeRE{'sector'}   = '([0-9])';
	$PostcodeRE{'unit'}     = '([ABDEFGHJLNP-UW-Z]{2})';
	$PostcodeRE{'std'}      = join '', @PostcodeRE{qw'area district space? sector unit'}; 
	$PostcodeRE{'bfpo'}     = '(BFPO)\s*([0-9]{1,4})';
	$PostcodeRE{'giro'}     = '(GIR)\s*(0AA)';
	$PostcodeRE{'santa'}    = '(SAN)\s*(TA1)';
	$PostcodeRE{'os_area'}  = '(ASCN|BBND|BIQQ|FIQQ|PCRN|SIQQ|STHL|TDCU|TKCA)';
	$PostcodeRE{'os_pc'}    = $PostcodeRE{'os_area'} .'\s*(1ZZ)';
	$PostcodeRE{'*'}        = join '|', map {"(?:$_)"} @PostcodeRE{qw'std bfpo giro santa os_pc'};
	
	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#postcode_valid"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "postcode_valid function requires literal argument");
		}

		if ($node->literal_value =~ /$PostcodeRE{'*'}/i)
		{
			return RDF::Query::Node::Literal->new('true', undef, $XSD->boolean->uri);
		}
		
		return RDF::Query::Node::Literal->new('false', undef, $XSD->boolean->uri);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#postcode_format"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "postcode_format function requires literal argument");
		}

		if ($node->literal_value =~ /$PostcodeRE{'std'}/i)
		{
			return RDF::Query::Node::Literal->new(
				uc sprintf('%s%s %s%s', $1, $2, $3, $4),
				$node->literal_value_language,
				$node->literal_datatype,
				);
		}
		
		if (my @parts = ($node->literal_value =~ /$PostcodeRE{'*'}/i))
		{
			return RDF::Query::Node::Literal->new(
				(uc join ' ', grep { defined $_ } @parts[1 .. $#parts]),
				$node->literal_value_language,
				$node->literal_datatype,
				);
		}
		
		return $node;
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#telephone_valid"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "telephone_valid function requires literal argument");
		}

		my ($intl, $std, $num, $ext) = _parse_telephone_number($node->literal_value);
		
		if (ref $intl)
		{
			return RDF::Query::Node::Literal->new('false', undef, $XSD->boolean->uri);
		}
		
		return RDF::Query::Node::Literal->new('true', undef, $XSD->boolean->uri);
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#telephone_std"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "telephone_std function requires literal argument");
		}

		my ($intl, $std, $num, $ext) = _parse_telephone_number($node->literal_value);
		
		if (defined $std && !ref $std)
		{
			return RDF::Query::Node::Literal->new($std);
		}
		
		return RDF::Query::Node::Literal->new('');
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#telephone_local"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "telephone_number function requires literal argument");
		}

		my ($intl, $std, $num, $ext) = _parse_telephone_number($node->literal_value);
		
		if (defined $num && !ref $num)
		{
			return RDF::Query::Node::Literal->new($num);
		}
		
		return RDF::Query::Node::Literal->new('');
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#telephone_extension"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "telephone_extension function requires literal argument");
		}

		my ($intl, $std, $num, $ext) = _parse_telephone_number($node->literal_value);
		
		if (defined $ext && !ref $ext)
		{
			return RDF::Query::Node::Literal->new($ext);
		}
		
		return RDF::Query::Node::Literal->new('');
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#telephone_uri"} ||= sub {
		my ($query, $node) = @_;
		
		if (blessed($node) and $node->isa('RDF::Trine::Node::Resource'))
		{
			return $node if $node->uri =~ /^tel:/i;
		}
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "telephone_uri function requires literal argument, or <tel:> URI.");
		}

		my ($intl, $std, $num, $ext) = _parse_telephone_number($node->literal_value);
		
		my $uri;
		if (defined $intl && !ref $intl)
		{
			$uri = sprintf('tel:%s', $intl);
		}
		elsif (defined $std)
		{
			my $stdx = $std;
			$stdx =~ s/^0//;
			$uri = sprintf('tel:+44-%s-%s', $stdx, $num);
		}
		elsif (defined $num)
		{
			$uri = sprintf('tel:%s;phone-context=+44', $num);
		}
		
		if (defined $uri && defined $ext)
		{
			$uri .= sprintf(';extension=%s', $ext);
		}
		
		if (defined $uri)
		{
			return RDF::Query::Node::Resource->new($uri);
		}
		
		return $node;
	};

	$RDF::Query::functions{"http://buzzword.org.uk/2011/functions/gb#telephone_format"} ||= sub {
		my ($query, $node) = @_;
		
		unless (blessed($node) and $node->isa('RDF::Trine::Node::Literal'))
		{
			throw RDF::Query::Error::TypeError(-text => "telephone_format function requires literal argument.");
		}

		my ($intl, $std, $num, $ext) = _parse_telephone_number($node->literal_value);
		
		my $uri;
		if (defined $intl && !ref $intl)
		{
			$uri = sprintf('%s', $intl);
		}
		elsif (defined $std)
		{
			$uri = sprintf('%s %s', $std, $num);
		}
		elsif (defined $num)
		{
			$uri = sprintf('%s', $num);
		}
		
		if (defined $uri && defined $ext)
		{
			$uri .= sprintf(' x%s', $ext);
		}
		
		if (defined $uri)
		{
			return RDF::Query::Node::Literal->new($uri);
		}
		
		return $node;
	};

} #/sub install

sub _parse_telephone_number
{
	no strict;
	
	my $std;
	my $n;
	my $x;
	
	local $_ = shift;
	s/[^0-9x\+]//ig;
	($_, $x) = split /x/i;
	
	s/^00/+/;
	
	if (/^\+/)
	{
		return ($_, undef, undef, $x);
	}
	
	if (/^118\d{3}$/ || /^1\d{2}$/ || /^999$/)
	{
		return (undef, undef, $_, undef);
	}

	$_ = "0$_" unless /^0/;
	return { error => "Phone number $_ seems to be wrong length." }
		unless (length($_) == 11 || length($_) == 10);
	
	if (/^02/)
	{
		$std = substr $_, 0, 3;
		$n   = substr $_, 3;
	}	
	elsif (/^011/ || /^0[358]/)
	{
		$std = substr $_, 0, 4;
		$n   = substr $_, 4;
	}
	else
	{
		$std = substr $_, 0, 5;
		$n   = substr $_, 5;
	}
	
	return (undef, $std, $n, $x);
}


1;

__END__

=head1 NAME

RDF::Query::Functions::Buzzword::GB - plugin for buzzword.org.uk British locale-specific functions

=head1 SYNOPSIS

  use RDF::Query;
  use RDF::TrineX::Functions -shortcuts;

  my $data = rdf_parse(<<'TURTLE', type=>'turtle', base=>$baseuri);
  @prefix foaf: <http://xmlns.com/foaf/0.1/> .
  @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

  <http://tobyinkster.co.uk/#i>
    foaf:name "Toby Inkster" ;
    foaf:phone "01234567890x1234";
    foaf:postcode "bn71rs" .
  TURTLE

  my $query = RDF::Query->new(<<'SPARQL');
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX sparql: <sparql:>
  PREFIX gb: <http://buzzword.org.uk/2011/functions/gb#>
  PREFIX util: <http://buzzword.org.uk/2011/functions/util#>
  SELECT
    ?name
    ?phone
    ?postcode
    (gb:postcode_format(?postcode) AS ?pcfmt)
    (gb:telephone_std(?phone) AS ?phonestd)
    (gb:telephone_local(?phone) AS ?phonelocal)
    (gb:telephone_extension(?phone) AS ?phoneext)
    (gb:telephone_uri(?phone) AS ?phoneuri)
  WHERE
  {
    ?person foaf:name ?name ; foaf:phone ?phone ; foaf:postcode ?postcode .
  }
  SPARQL

  print $query->execute($data)->as_xml;

=head1 DESCRIPTION

This is a plugin for RDF::Query providing a number of extension functions.

=over

=item * http://buzzword.org.uk/2011/functions/gb#postcode_valid

Given a literal, returns a boolean indicating whether it seems to be
a syntactically valid UK postcode.

=item * http://buzzword.org.uk/2011/functions/gb#postcode_format

Given a literal, if it seems to be a valid UK postcode, canonicalises
the formatting; otherwise returns the literal unscathed.

=item * http://buzzword.org.uk/2011/functions/gb#telephone_valid

Given a literal, returns a boolean indicating whether it seems to be
a number that could be dialed from a UK phone.

Only the digits '0' to '9', letter 'x' (extension) and '+' (international
dialing code) are expected. Other characters are stripped out before any
checks.

=item * http://buzzword.org.uk/2011/functions/gb#telephone_format

Canonicalises the formatting of a phone number that is valid. Should return
invalid phone numbers unscathed.

=item * http://buzzword.org.uk/2011/functions/gb#telephone_std

Returns the STD code for a phone number, if it could be extracted; the
empty string otherwise.

=item * http://buzzword.org.uk/2011/functions/gb#telephone_local

Returns the local part of a phone number, if it could be extracted; the
empty string otherwise.

=item * http://buzzword.org.uk/2011/functions/gb#telephone_extension

Returns the extension from a phone number, if it could be extracted; the
empty string otherwise.

=item * http://buzzword.org.uk/2011/functions/gb#telephone_uri

Returns a phone number as a E<lt>tel:E<gt> URI.

An existing E<lt>tel:E<gt> URI should pass through unscathed.

=back

=begin trustme

=item C<install>

=end trustme

=head1 SEE ALSO

L<RDF::Query>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2004-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
