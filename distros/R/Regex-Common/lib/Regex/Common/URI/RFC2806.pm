package Regex::Common::URI::RFC2806;
use strict;
use warnings;
use Regex::Common::URI::RFC1035 qw /$domain/;
use Regex::Common::URI::RFC2396 qw /$unreserved $escaped $hex/;

our $VERSION = 'v1.0.0'; # VERSION

use vars qw /@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA/;

use Exporter ();
@ISA = qw /Exporter/;

my %vars;

BEGIN {
    $vars{low} = [
        qw /$dtmf_digit $wait_for_dial_tone $one_second_pause
          $pause_character $visual_separator $phonedigit
          $escaped_no_dquote $quoted_string $token_char
          $token_chars/
    ];
    $vars{parts}   = [qw /$future_extension/];
    $vars{connect} = [
        qw /$provider_hostname $provider_tag $service_provider
          $private_prefix $local_network_prefix
          $global_network_prefix $network_prefix/
    ];
    $vars{phone} = [
        qw /$phone_context_ident $phone_context_tag
          $area_specifier $post_dial $isdn_subaddress
          $t33_subaddress $local_phone_number
          $local_phone_number_no_future
          $base_phone_number $global_phone_number
          $global_phone_number_no_future $telephone_subscriber
          $telephone_subscriber_no_future/
    ];
    $vars{fax} = [
        qw /$fax_local_phone $fax_local_phone_no_future
          $fax_global_phone $fax_global_phone_no_future
          $fax_subscriber $fax_subscriber_no_future/
    ];
    $vars{modem} = [qw //];
}

use vars map { @$_ } values %vars;

@EXPORT      = ();
@EXPORT_OK   = map { @$_ } values %vars;
%EXPORT_TAGS = ( %vars, ALL => [@EXPORT_OK] );

# RFC 2806, URIs for tel, fax & modem.
$dtmf_digit         = "(?:[*#ABCD])";
$wait_for_dial_tone = "(?:w)";
$one_second_pause   = "(?:p)";
$pause_character    = "(?:[wp])";       # wait_for_dial_tone | one_second_pause.
$visual_separator   = "(?:[\\-.()])";
$phonedigit         = "(?:[0-9\\-.()])";    # DIGIT | visual_separator
$escaped_no_dquote  = "(?:%(?:[01]$hex)|2[013-9A-Fa-f]|[3-9A-Fa-f]$hex)";
$quoted_string      = "(?:%22(?:(?:%5C(?:$unreserved|$escaped))|"
  . "$unreserved+|$escaped_no_dquote)*%22)";

# It is unclear wether we can allow only unreserved
# characters to unescaped, or can we also use uric
# characters that are unescaped? Or pchars?
$token_char =
    "(?:[!'*\\-.0-9A-Z_a-z~]|"
  . "%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|"
  . "5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))";

# Only allowing unreserved chars to be unescaped.
$token_chars =
    "(?:(?:[!'*\\-.0-9A-Z_a-z~]+|"
  . "%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|"
  . "5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)";
$future_extension =
    "(?:;$token_chars"
  . "(?:=(?:(?:$token_chars(?:[?]$token_chars)?)|"
  . "$quoted_string))?)";
$provider_hostname = $domain;
$provider_tag      = "(?:tsp)";
$service_provider  = "(?:;$provider_tag=$provider_hostname)";
$private_prefix =
    "(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|"
  . "(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|"
  . "5[1-689A-Fa-f]|6[05-9A-Fa-f]|"
  . "7[1-689A-Ea-e])))"
  . "(?:[!'()*\\-.0-9A-Z_a-z~]+|"
  . "(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|"
  . "[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)";
$local_network_prefix  = "(?:[0-9\\-.()*#ABCDwp]+)";
$global_network_prefix = "(?:[+][0-9\\-.()]+)";
$network_prefix        = "(?:$global_network_prefix|$local_network_prefix)";
$phone_context_ident   = "(?:$network_prefix|$private_prefix)";
$phone_context_tag     = "(?:phone-context)";
$area_specifier        = "(?:;$phone_context_tag=$phone_context_ident)";
$post_dial             = "(?:;postd=[0-9\\-.()*#ABCDwp]+)";
$isdn_subaddress       = "(?:;isub=[0-9\\-.()]+)";
$t33_subaddress        = "(?:;tsub=[0-9\\-.()]+)";

$local_phone_number =
    "(?:[0-9\\-.()*#ABCDwp]+$isdn_subaddress?"
  . "$post_dial?$area_specifier"
  . "(?:$area_specifier|$service_provider|"
  . "$future_extension)*)";
$local_phone_number_no_future =
    "(?:[0-9\\-.()*#ABCDwp]+$isdn_subaddress?"
  . "$post_dial?$area_specifier"
  . "(?:$area_specifier|$service_provider)*)";
$fax_local_phone =
    "(?:[0-9\\-.()*#ABCDwp]+$isdn_subaddress?"
  . "$t33_subaddress?$post_dial?$area_specifier"
  . "(?:$area_specifier|$service_provider|"
  . "$future_extension)*)";
$fax_local_phone_no_future =
    "(?:[0-9\\-.()*#ABCDwp]+$isdn_subaddress?"
  . "$t33_subaddress?$post_dial?$area_specifier"
  . "(?:$area_specifier|$service_provider)*)";
$base_phone_number = "(?:[0-9\\-.()]+)";
$global_phone_number =
    "(?:[+]$base_phone_number$isdn_subaddress?"
  . "$post_dial?"
  . "(?:$area_specifier|$service_provider|"
  . "$future_extension)*)";
$global_phone_number_no_future =
    "(?:[+]$base_phone_number$isdn_subaddress?"
  . "$post_dial?"
  . "(?:$area_specifier|$service_provider)*)";
$fax_global_phone =
    "(?:[+]$base_phone_number$isdn_subaddress?"
  . "$t33_subaddress?$post_dial?"
  . "(?:$area_specifier|$service_provider|"
  . "$future_extension)*)";
$fax_global_phone_no_future =
    "(?:[+]$base_phone_number$isdn_subaddress?"
  . "$t33_subaddress?$post_dial?"
  . "(?:$area_specifier|$service_provider)*)";
$telephone_subscriber = "(?:$global_phone_number|$local_phone_number)";
$telephone_subscriber_no_future =
  "(?:$global_phone_number_no_future|" . "$local_phone_number_no_future)";
$fax_subscriber = "(?:$fax_global_phone|$fax_local_phone)";
$fax_subscriber_no_future =
  "(?:$fax_global_phone_no_future|" . "$fax_local_phone_no_future)";

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::RFC2806 -- Definitions from RFC2806;

=head1 SYNOPSIS

    use Regex::Common::URI::RFC2806 qw /:ALL/;

=head1 DESCRIPTION

This package exports definitions from RFC2806. It's intended
usage is for Regex::Common::URI submodules only. Its interface
might change without notice.

=head1 REFERENCES

=over 4

=item B<[RFC 2616]>

Fielding, R., Gettys, J., Mogul, J., Frystyk, H., Masinter, L.,
Leach, P. and Berners-Lee, Tim: I<Hypertext Transfer Protocol -- HTTP/1.1>.
June 1999.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 LICENSE and COPYRIGHT

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
glasswalk3r at yahoo.com.br

This file is part of regex-common project.

regex-commonis free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

regex-common is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
regex-common. If not, see (http://www.gnu.org/licenses/).

The original project [Regex::Common](https://metacpan.org/pod/Regex::Common)
is licensed through the MIT License, copyright (c) Damian Conway
(damian@cs.monash.edu.au) and Abigail (regexp-common@abigail.be).

=cut
