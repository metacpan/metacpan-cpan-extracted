package Regex::Common::URI::RFC2396;
use strict;
use warnings;
use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

use vars qw /@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA/;

use Exporter ();
@ISA = qw /Exporter/;

my %vars;

BEGIN {
    $vars{low} = [
        qw /$digit $upalpha $lowalpha $alpha $alphanum $hex
          $escaped $mark $unreserved $reserved $pchar $uric
          $urics $userinfo $userinfo_no_colon $uric_no_slash/
    ];
    $vars{parts} = [
        qw /$query $fragment $param $segment $path_segments
          $ftp_segments $rel_segment $abs_path $rel_path
          $path/
    ];
    $vars{connect} = [
        qw /$port $IPv4address $toplabel $domainlabel $hostname
          $host $hostport $server $reg_name $authority/
    ];
    $vars{URI} = [
        qw /$scheme $net_path $opaque_part $hier_part
          $relativeURI $absoluteURI $URI_reference/
    ];
}

use vars map { @$_ } values %vars;

@EXPORT      = ();
@EXPORT_OK   = map { @$_ } values %vars;
%EXPORT_TAGS = ( %vars, ALL => [@EXPORT_OK] );

# RFC 2396, base definitions.
$digit      = '[0-9]';
$upalpha    = '[A-Z]';
$lowalpha   = '[a-z]';
$alpha      = '[a-zA-Z]';                  # lowalpha | upalpha
$alphanum   = '[a-zA-Z0-9]';               # alpha    | digit
$hex        = '[a-fA-F0-9]';
$escaped    = "(?:%$hex$hex)";
$mark       = "[\\-_.!~*'()]";
$unreserved = "[a-zA-Z0-9\\-_.!~*'()]";    # alphanum | mark
                                           # %61-%7A, %41-%5A, %30-%39
                                           #  a - z    A - Z    0 - 9
    # %21, %27, %28, %29, %2A, %2D, %2E, %5F, %7E
    #  !    '    (    )    *    -    .    _    ~
$reserved = "[;/?:@&=+\$,]";
$pchar    = "(?:[a-zA-Z0-9\\-_.!~*'():\@&=+\$,]|$escaped)";

# unreserved | escaped | [:@&=+$,]
$uric = "(?:[;/?:\@&=+\$,a-zA-Z0-9\\-_.!~*'()]|$escaped)";

# reserved | unreserved | escaped
$urics = "(?:(?:[;/?:\@&=+\$,a-zA-Z0-9\\-_.!~*'()]+|" . "$escaped)*)";

$query         = $urics;
$fragment      = $urics;
$param         = "(?:(?:[a-zA-Z0-9\\-_.!~*'():\@&=+\$,]+|$escaped)*)";
$segment       = "(?:$param(?:;$param)*)";
$path_segments = "(?:$segment(?:/$segment)*)";
$ftp_segments  = "(?:$param(?:/$param)*)";    # NOT from RFC 2396.
$rel_segment   = "(?:(?:[a-zA-Z0-9\\-_.!~*'();\@&=+\$,]*|$escaped)+)";
$abs_path      = "(?:/$path_segments)";
$rel_path      = "(?:$rel_segment(?:$abs_path)?)";
$path          = "(?:(?:$abs_path|$rel_path)?)";

$port        = "(?:$digit*)";
$IPv4address = "(?:$digit+[.]$digit+[.]$digit+[.]$digit+)";
$toplabel    = "(?:$alpha" . "[-a-zA-Z0-9]*$alphanum|$alpha)";
$domainlabel = "(?:(?:$alphanum" . "[-a-zA-Z0-9]*)?$alphanum)";
$hostname    = "(?:(?:$domainlabel\[.])*$toplabel\[.]?)";
$host        = "(?:$hostname|$IPv4address)";
$hostport    = "(?:$host(?::$port)?)";

$userinfo          = "(?:(?:[a-zA-Z0-9\\-_.!~*'();:&=+\$,]+|$escaped)*)";
$userinfo_no_colon = "(?:(?:[a-zA-Z0-9\\-_.!~*'();&=+\$,]+|$escaped)*)";
$server            = "(?:(?:$userinfo\@)?$hostport)";

$reg_name  = "(?:(?:[a-zA-Z0-9\\-_.!~*'()\$,;:\@&=+]*|$escaped)+)";
$authority = "(?:$server|$reg_name)";

$scheme = "(?:$alpha" . "[a-zA-Z0-9+\\-.]*)";

$net_path      = "(?://$authority$abs_path?)";
$uric_no_slash = "(?:[a-zA-Z0-9\\-_.!~*'();?:\@&=+\$,]|$escaped)";
$opaque_part   = "(?:$uric_no_slash$urics)";
$hier_part     = "(?:(?:$net_path|$abs_path)(?:[?]$query)?)";

$relativeURI   = "(?:(?:$net_path|$abs_path|$rel_path)(?:[?]$query)?";
$absoluteURI   = "(?:$scheme:(?:$hier_part|$opaque_part))";
$URI_reference = "(?:(?:$absoluteURI|$relativeURI)?(?:#$fragment)?)";

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::RFC2396 -- Definitions from RFC2396;

=head1 SYNOPSIS

    use Regex::Common::URI::RFC2396 qw /:ALL/;

=head1 DESCRIPTION

This package exports definitions from RFC2396. It's intended
usage is for Regex::Common::URI submodules only. Its interface
might change without notice.

=head1 REFERENCES

=over 4

=item B<[RFC 2396]>

Berners-Lee, Tim, Fielding, R., and Masinter, L.: I<Uniform Resource
Identifiers (URI): Generic Syntax>. August 1998.

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
