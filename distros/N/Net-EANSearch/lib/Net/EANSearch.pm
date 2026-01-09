package Net::EANSearch;

use strict;
use warnings;

use LWP;
use JSON;
use URL::Encode;
use MIME::Base64 qw(decode_base64);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::EANSearch ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.20';

our $ALL_LANGUAGES = 99;
our $ENGLISH = 1;
our $DANISH = 2;
our $GERMAN = 3;
our $SPANISH = 4;
our $FINISH = 5;
our $FRENCH = 6;
our $HUNGARIAN = 7;
our $ITALIAN = 8;
our $JAPANESE = 9;
our $DUTCH = 10;
our $NORWEGIAN = 11;
our $POLISH = 12;
our $PORTGUESE = 13;
our $SWEDISH = 15;
our $CHECH = 16;
our $CROATIAN = 18;
our $ROMAINAN = 19;
our $BULGARIAN = 20;
our $GREEK = 21;

my $BASE_URI = 'https://api.ean-search.org/api?format=json&token=';
my $MAX_API_TRIES = 3; # retry, eg. on 429 error

sub new {
	my $class = shift;
	my $token = shift;

	my $ua = LWP::UserAgent->new(agent => "perl-eansearch/$VERSION");
	$ua->timeout(30);

	my $self = bless { base_uri => $BASE_URI . $token, ua => $ua, remaining => -1 }, $class;

    return $self;
}

sub barcodeLookup {
	my $self = shift;
	my $ean = shift;
	my $lang = shift || 1;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=barcode-lookup&ean=$ean&language=$lang");
	my $json = decode_json($json_str);
	return $json->[0];
}

sub isbnLookup {
	my $self = shift;
	my $isbn = shift;
	my $lang = shift || 1;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=barcode-lookup&isbn=$isbn&language=$lang");
	my $json = decode_json($json_str);
	return $json->[0];
}

sub barcodePrefixSearch {
	my $self = shift;
	my $prefix = shift;
	my $lang = shift || 1;
	my $page = shift || 0;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=barcode-prefix-search&page=$page&language=$lang&prefix=$prefix");
	my $json = decode_json($json_str);
	return @{ $json->{productlist} };
}

sub productSearch {
	my $self = shift;
	my $kw = shift;
	my $lang = shift || 1;
	my $page = shift || 0;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=product-search&page=$page&language=$lang&name="
		. URL::Encode::url_encode_utf8($kw));
	my $json = decode_json($json_str);
	return @{ $json->{productlist} };
}

sub similarProductSearch {
	my $self = shift;
	my $kw = shift;
	my $lang = shift || 1;
	my $page = shift || 0;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=similar-product-search&page=$page&language=$lang&name="
		. URL::Encode::url_encode_utf8($kw));
	my $json = decode_json($json_str);
	return @{ $json->{productlist} };
}

sub categorySearch {
	my $self = shift;
	my $category = shift;
	my $kw = shift;
	my $lang = shift || 1;
	my $page = shift || 0;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=category-search&category=$category"
		. "&page=$page&language=$lang&name=" . URL::Encode::url_encode_utf8($kw));
	my $json = decode_json($json_str);
	return @{ $json->{productlist} };
}

sub issuingCountry {
	my $self = shift;
	my $ean = shift;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=issuing-country&ean=$ean");
	my $json = decode_json($json_str);
	return $json->[0]->{issuingCountry};
}

sub barcodeImage {
	my $self = shift;
	my $ean = shift;
	my $width = shift || 102;
	my $height = shift || 50;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=barcode-image&ean=$ean&width=$width&height=$height");
	my $json = decode_json($json_str);
	return decode_base64($json->[0]->{barcode});
}

sub verifyChecksum {
	my $self = shift;
	my $ean = shift;

	my $json_str = $self->_apiCall($self->{base_uri} . "&op=verify-checksum&ean=$ean");
	my $json = decode_json($json_str);
	return $json->[0]->{valid} + 0;
}

sub creditsRemaining {
	my $self = shift;

	if ($self->{remaining} < 0) {
		$self->_apiCall($self->{base_uri} . "&op=account-status");
	}
	return $self->{remaining};
}

sub _apiCall {
	my $self = shift;
	my $url = shift;
	my $tries = 0;

	while ($tries < $MAX_API_TRIES) {
		my $response = $self->{ua}->request(HTTP::Request->new(GET => $url));
		$tries++;
		if (!defined($response) || $response->is_error()) {
			if ($response->code == 429) { # auto-retry on 429 (too many requests)
				sleep 1;
				next;
			}
			print STDERR 'Network error: ' . (defined($response) ? $response->code : 'unknown') . "\n";
			return undef;
		} else {
			$self->{remaining} = $response->header('X-Credits-Remaining');
			return $response->content;
		}
	}
	return undef;
}

1;

__END__

=head1 NAME

Net::EANSearch - Perl module for EAN and ISBN lookup and validation using the API on L<https://www.ean-search.org>

=head1 SYNOPSIS

  use Net::EANSearch;

  my $eansearch = Net::EANSearch->new($API_TOKEN);

  my $product = $eansearch->barcodeLookup('5099750442227');

  my $book = $eansearch->isbnLookup('1119578884');

=head1 DESCRIPTION

C<Net::EANSearch> is a class used to search the ean-search.org barcode database by EAN, ISBN or keyword.

=head2 METHODS

=over 4

=item new($token)

Constructs a new C<Net::EANSearch> object, used to send queries.
Set the API token used for all subsequent queries.

=item barcodeLookup($ean [, $language])

Search the database for an EAN barcode.

Optionally, you can specify a preferred language for the result. See appendix B in the manual for all supported language codes.

=item isbnLookup($isbn)

Lookup book data for an ISBN number (ISBN-10 or ISBN-13 format).

=item barcodePrefixSearch($prefix [, $language, $page])

Search for all EANs starting with a certain prefix.

Optionally, you can specify a preferred language for the results.

If there are many results, you may need to page through the results to retrieve them all. Page numbers start at 0.

=item productSearch($name [, $language, $page])

Search the database by product name or keyword (exact search, all parts of the query must be found).
If you get no results, you might want to try a similarProductSearch().

Optionally, you can specify a preferred language for the results.

If there are many results, you may need to page through the results to retrieve them all. Page numbers start at 0.

=item similarProductSearch($name [, $language, $page])

Search the database by product name or keyword (find similar products, not all parts of the query must match).
You probably want to try an exact search (productSearch()) before you do a similarProductSearch().

Optionally, you can specify a preferred language for the results.

If there are many results, you may need to page through the results to retrieve them all. Page numbers start at 0.

=item categorySearch($category, $name [, $language, $page])

Search a certain product category for a product name or keyword. See appendix C in the API manual for category numbers.

Optionally, you can specify a preferred language for the results.

If there are many results, you may need to page through the results to retrieve them all. Page numbers start at 0.

=item issuingCountry($ean)

Look up the country where the EAN code was registered. This may or may not be the country where the product was manufactured.

=item barcodeImage($ean [, $width, $height])

Generate a PNG image with the barcode for the EAN number.

=item verifyChecksum($ean)

Verify if the checksum in the EAN number is valid.

=back

=head1 HOMEPAGE

The EAN database is hosted at L<https://www.ean-search.org>.

For API keys visit L<https://www.ean-search.org/ean-database-api.html>.

=head1 SOURCE

Source repository is at L<https://github.com/eansearch/perl-ean-search>.

=head1 AUTHOR

Relaxed Communications GmbH, E<lt>info@relaxedcommunications.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2025-2026 by Relaxed Communications GmbH, E<lt>info@relaxedcommunications.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

