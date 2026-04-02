##----------------------------------------------------------------------------
## Regexp patterns from RFC 3986 - ~/lib/Regexp/Common/URI/RFC3986.pm
## Version 2025102001
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/10/20
## Modified 2026/04/02
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Regexp::Common::URI::RFC3986;

use strict;
use warnings;

our $VERSION = '2025102001';

use Exporter ();
our @ISA = qw /Exporter/;


my %vars;

BEGIN
{
    $vars{low}     = [qw /$digit $upalpha $lowalpha $alpha $alphanum $hex $hexdig
                          $escaped $pct_encoded $mark $unreserved $sub_delims $reserved
                          $pchar $uric $urics $userinfo $userinfo_no_colon $uric_no_slash/];
    $vars{parts}   = [qw /$query $fragment $param $segment $segment_nz $segment_nz_nc
                          $path_abempty $path_absolute $path_noscheme $path_rootless
                          $path_empty $path_segments $ftp_segments $rel_segment
                          $abs_path $rel_path $path/];
    $vars{connect} = [qw /$port $dec_octet $IPv4address $hextet $ls32 $IPv6address
                          $IPvFuture $IP_literal $toplabel $domainlabel $hostname
                          $host $hostport $server $reg_name $authority/];
    $vars{URI}     = [qw /$scheme $net_path $opaque_part $hier_part $relative_part
                          $relativeURI $absoluteURI $relative_ref $URI_reference/];
    $vars{IDN}     = [qw /$IDN_DOT $ACE $IDN_U_LABEL $IDN_HOST/];
}

our @EXPORT      = ();
our @EXPORT_OK   = map { @$_ } values %vars;
our %EXPORT_TAGS = (%vars, ALL => [@EXPORT_OK]);

# RFC3986, base definitions.
our $digit             =  '[0-9]';
our $upalpha           =  '[A-Z]';
our $lowalpha          =  '[a-z]';
our $alpha             =  '[a-zA-Z]';                # lowalpha | upalpha
our $alphanum          =  '[a-zA-Z0-9]';             # alpha    | digit
our $hexdig            =  '[a-fA-F0-9]';
our $hex               =  $hexdig;                   # RFC2396 compatibility alias
our $pct_encoded       =  "(?:\%$hexdig$hexdig)";    # pct-encoded
our $escaped           =  $pct_encoded;              # RFC2396 compatibility alias
# RFC3986 unreserved + sub-delims (ASCII)
our $unreserved        =  "[a-zA-Z0-9\\-_.~]";       # alphanum | mark
                          # %61-%7A, %41-%5A, %30-%39
                          #  a - z    A - Z    0 - 9
                          # %2D, %5F, %2E, %7E
                          #  -    _    .    ~
our $sub_delims        =  "[!\\\$&'\\(\\)\\*\\+,;=]";
our $reserved          =  "[;/?:@&=+\$,]";
our $pchar             =  "(?:$unreserved|$pct_encoded|$sub_delims|[:\@])";
                          # unreserved | pct-encoded / sub-delims / ":" / "@"
# Compatibility aliases to RFC2396's uric/urics/uric_no_slash
our $mark              =  "[\\-_.!~*'()]";           # RFC2396 legacy
our $uric              =  "(?:[/?]|$pchar)";         # RFC2396 legacy superset
our $urics             =  "(?:(?:$uric)*)";          # RFC2396 legacy
our $uric_no_slash     =  "(?:$pchar|[?])";          # RFC2396 legacy

# query / fragment = *( pchar / "/" / "?" )
our $query             =  "(?:(?:$pchar|[/?])*)";
our $fragment          =  "(?:(?:$pchar|[/?])*)";
our $param             =  "(?:(?:[a-zA-Z0-9\\-_.!~*'():\@&=+\$,]+|$escaped)*)";
# Path productions (RFC3986 §3.3)
our $segment           =  "(?:$pchar*)";
our $segment_nz        =  "(?:$pchar+)";
our $segment_nz_nc     =  "(?:(?:$unreserved|$pct_encoded|$sub_delims|@)+)";

# RFC2396 names kept for compatibility
our $path_segments     =  "(?:$segment(?:/$segment)*)";  # RFC2396 legacy name
our $abs_path          =  "(?:/$path_segments)";         # RFC2396 legacy
our $ftp_segments      =  "(?:$param(?:/$param)*)";      # NOT from RFC 2396.
our $rel_segment       =  "(?:(?:[a-zA-Z0-9\\-_.!~*'();\@&=+\$,]*|$escaped)+)"; # RFC2396 legacy
our $rel_path          =  "(?:$rel_segment(?:$abs_path)?)";  # RFC2396 legacy
our $path              =  "(?:(?:$abs_path|$rel_path)?)";    # RFC2396 legacy

# 3986 canonical forms
our $path_abempty      =  "(?:/$segment)*";
our $path_absolute     =  "(?:/(?:$segment_nz(?:/$segment)*)?)";
our $path_noscheme     =  "(?:$segment_nz_nc(?:/$segment)*)";
our $path_rootless     =  "(?:$segment_nz(?:/$segment)*)";
our $path_empty        =  "(?:)";

# RFC3986 §3.2.2 Host / Authority
# IPv4
our $dec_octet         =  "(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])";
our $IPv4address       =  "(?:$dec_octet\\.$dec_octet\\.$dec_octet\\.$dec_octet)";

# IPv6 (RFC3986 Appendix A)
our $hextet            =  "(?:(?:$hexdig){1,4})";
our $ls32              =  "(?:$hextet:$hextet|$IPv4address)";

# A faithful (and readable) IPv6address alternation set.
# Corresponds exactly to the 9 alternatives in RFC 3986 Appendix A:
#   1.                            6( h16 ":" ) ls32
#   2.                       "::" 5( h16 ":" ) ls32
#   3. [               h16 ] "::" 4( h16 ":" ) ls32
#   4. [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
#   5. [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
#   6. [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
#   7. [ *4( h16 ":" ) h16 ] "::"              ls32
#   8. [ *5( h16 ":" ) h16 ] "::"    h16
#   9. [ *6( h16 ":" ) h16 ] "::"
our $IPv6address = "(?:" .
    "(?:$hextet:){6}$ls32"                                  . '|' .
    "::(?:$hextet:){5}$ls32"                                . '|' .
    "(?:$hextet)?::(?:$hextet:){4}$ls32"                    . '|' .
    "(?:(?:$hextet:){0,2}$hextet)?::(?:$hextet:){3}$ls32"   . '|' .
    "(?:(?:$hextet:){0,3}$hextet)?::(?:$hextet:){2}$ls32"   . '|' .
    "(?:(?:$hextet:){0,4}$hextet)?::(?:$hextet:)$ls32"      . '|' .
    "(?:(?:$hextet:){0,5}$hextet)?::$ls32"                  . '|' .
    "(?:(?:$hextet:){0,5}$hextet)?::$hextet"                . '|' .
    "(?:(?:$hextet:){0,6}$hextet)?::"                       .
")";

# IPvFuture = 'v' 1*HEXDIG '.' 1*( unreserved / sub-delims / ":" )
our $IPvFuture         =  "(?:v(?:$hexdig)+\\.(?:$unreserved|$sub_delims|:)+)";

# IP-literal = "[" ( IPv6address / IPvFuture ) "]"
our $IP_literal        =  "(?:\\[(?:$IPv6address|$IPvFuture)\\])";

# reg-name = *( unreserved / pct-encoded / sub-delims )
our $reg_name          =  "(?:(?:$unreserved|$pct_encoded|$sub_delims)*)";

# host = IP-literal / IPv4address / reg-name
our $host              =  "(?:$IP_literal|$IPv4address|$reg_name)";
our $port              =  "(?:$digit*)";

# userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
our $userinfo          =  "(?:(?:$unreserved|$pct_encoded|$sub_delims|:)*)";
our $userinfo_no_colon =  "(?:(?:$unreserved|$pct_encoded|$sub_delims)*)";

# authority = [ userinfo "@" ] host [ ":" port ]
our $authority         =  "(?:(?:$userinfo\@)?$host(?::$port)?)";

# Legacy RFC2396 names kept (not used by RFC3986, but exported for compatibility)
our $toplabel          =  "(?:$alpha"."[-a-zA-Z0-9]*$alphanum|$alpha)";
our $domainlabel       =  "(?:(?:$alphanum"."[-a-zA-Z0-9]*)?$alphanum)";
our $hostname          =  "(?:(?:$domainlabel\[.])*$toplabel\[.]?)";    # RFC2396 legacy ASCII hostname
our $hostport          =  "(?:$host(?::$port)?)";                       # RFC2396 legacy
our $server            =  "(?:(?:$userinfo\@)?$hostport)";              # RFC2396 legacy

our $scheme            =  "(?:$alpha"."[a-zA-Z0-9+\\-.]*)";

our $net_path          =  "(?://$authority$abs_path?)";
our $opaque_part       =  "(?:$uric_no_slash$urics)";
# hier-part = ("//" authority path-abempty) / path-absolute / path-rootless / path-empty
our $hier_part         =  "(?:(?://$authority$path_abempty)|$path_absolute|$path_rootless|$path_empty)";
# relative-part = ("//" authority path-abempty) / path-absolute / path-noscheme / path-empty
our $relative_part     =  "(?:(?://$authority$path_abempty)|$path_absolute|$path_noscheme|$path_empty)";
# absolute-URI  = scheme ":" hier-part [ "?" query ]
our $absoluteURI       =  "(?:$scheme:$hier_part(?:\\?$query)?)";
# relative-ref  = relative-part [ "?" query ] [ "#" fragment ]
our $relative_ref      =  "(?:$relative_part(?:\\?$query)?(?:\\#$fragment)?)";
# URI-reference = URI / relative-ref
# (where URI      = scheme ":" hier-part [ "?" query ] [ "#" fragment ])
our $URI_reference     =  "(?:(?:$absoluteURI(?:\\#$fragment)?|$relative_ref))";
# Legacy RFC2396 "relativeURI" (without fragment)
our $relativeURI       =  "(?:$relative_part(?:\\?$query)?)";

# Optional Unicode/IDN helpers (non-normative)
# Accept "." and the IDNA dot equivalents
our $IDN_DOT           = '[\.\x{3002}\x{FF0E}\x{FF61}]';

# ACE punycode prefix (case-insensitive)
our $ACE               = '(?i:xn--)';

# Unicode IDN label with ACE hyphen rule (<=63 chars)
our $IDN_U_LABEL       = join '',
    '(?:',
        '(?:', $ACE, '[\\p{L}\\p{N}\\p{M}\\p{Pc}-]{1,59})',
        '|',
        '(?![\\p{L}\\p{N}]{2}--)',   # forbid "--" at pos 3-4 unless ACE
        '[\\p{L}\\p{N}]',
        '[\\p{L}\\p{N}\\p{M}\\p{Pc}-]{0,61}',
        '(?<!-)',
    ')';

# Unicode IDN hostname: label *( DOT-equivalent label )
our $IDN_HOST          = "(?:$IDN_U_LABEL(?:$IDN_DOT$IDN_U_LABEL)*)";

1;
# NOTE: TODO
__END__

=pod

=encoding utf8

=head1 NAME

Regexp::Common::URI::RFC3986 - Regexp patterns from RFC 3986

=head1 SYNOPSIS

    use Regexp::Common::URI::RFC3986 qw /:ALL/;

    # Match a full URI
    if( $string =~ /^$URI_reference$/ )
    {
        print "Valid URI reference\n";
    }

    # Match an IPv6 literal host
    if( $string =~ /^$IP_literal$/ )
    {
        print "Valid IP literal\n";
    }

    # Use IDN helpers for Unicode hostnames
    use Regexp::Common::URI::RFC3986 qw /:IDN/;

    if( $string =~ /^$IDN_HOST$/ )
    {
        print "Valid Unicode hostname\n";
    }

=head1 VERSION

    2025102001

=head1 DESCRIPTION

This module exports regular expressions derived from RFC 3986 (I<Uniform Resource Identifier (URI): Generic Syntax>, January 2005), which supersedes RFC 2396.

All exported variables are plain strings containing non-capturing regex fragments (C<(?:...)>). They are designed to be interpolated into larger patterns and do B<not> require C<Regexp::Common> to function.

The exported variables mirror the structure and naming of C<Regexp::Common::URI::RFC2396> (from the C<Regexp-Common> distribution), updated to the RFC 3986 grammar. Key improvements over RFC 2396 include:

=over 4

=item * C<$pct_encoded> replacing the old C<$escaped>

=item * C<$sub_delims> and C<$unreserved> per RFC 3986 §2

=item * The full set of C<path_*> productions (C<$path_abempty>, C<$path_absolute>, C<$path_noscheme>, C<$path_rootless>, C<$path_empty>)

=item * C<$IP_literal> supporting IPv6 addresses and C<IPvFuture> forms

=item * C<$IPv6address> as a faithful transcription of RFC 3986 Appendix A

=back

For backward compatibility, several RFC 2396 names (C<$mark>, C<$uric>, C<$urics>, C<$uric_no_slash>, C<$escaped>, C<$hostname>, etc.) are also exported, mapped to sensible RFC 3986 equivalents.

=head1 EXPORTS

Nothing is exported by default. Use the following tags or individual names.

=head2 Export tags

=over 4

=item C<:low>

Base character class building blocks: C<$digit>, C<$upalpha>, C<$lowalpha>, C<$alpha>, C<$alphanum>, C<$hex>, C<$hexdig>, C<$escaped>, C<$pct_encoded>, C<$mark>, C<$unreserved>, C<$sub_delims>, C<$reserved>, C<$pchar>, C<$uric>, C<$urics>, C<$userinfo>, C<$userinfo_no_colon>, C<$uric_no_slash>.

=item C<:parts>

Path and query/fragment productions: C<$query>, C<$fragment>, C<$param>, C<$segment>, C<$segment_nz>, C<$segment_nz_nc>, C<$path_abempty>, C<$path_absolute>, C<$path_noscheme>, C<$path_rootless>, C<$path_empty>, C<$path_segments>, C<$ftp_segments>, C<$rel_segment>, C<$abs_path>, C<$rel_path>, C<$path>.

=item C<:connect>

Host and authority productions: C<$port>, C<$dec_octet>, C<$IPv4address>, C<$hextet>, C<$ls32>, C<$IPv6address>, C<$IPvFuture>, C<$IP_literal>, C<$toplabel>, C<$domainlabel>, C<$hostname>, C<$host>, C<$hostport>, C<$server>, C<$reg_name>, C<$authority>.

=item C<:URI>

Top-level URI productions: C<$scheme>, C<$net_path>, C<$opaque_part>, C<$hier_part>, C<$relative_part>, C<$relativeURI>, C<$absoluteURI>, C<$relative_ref>, C<$URI_reference>.

=item C<:IDN>

Optional non-normative Unicode/IDN helpers: C<$IDN_DOT>, C<$ACE>, C<$IDN_U_LABEL>, C<$IDN_HOST>.

=item C<:ALL>

All of the above.

=back

=head2 Optional Unicode/IDN helpers

RFC 3986 is ASCII-only at the syntax level; internationalised host names are to be represented as A-labels (punycode). For callers who want to pre-validate Unicode host names before ACE conversion, the following non-normative helpers are also exported under the C<:IDN> tag:

=over 4

=item C<$IDN_DOT>

Recognises C<.> and the three IDNA dot-equivalents (U+3002, U+FF0E, U+FF61).

=item C<$ACE>

Case-insensitive C<xn--> punycode prefix.

=item C<$IDN_U_LABEL>

A single Unicode label of at most 63 characters, with the ACE hyphen rule enforced: C<--> at positions 3-4 is only permitted for ACE labels.

=item C<$IDN_HOST>

One or more Unicode labels separated by C<$IDN_DOT>.

=back

These variables are I<non-normative> conveniences and are not used by the RFC 3986 C<$host> production, which remains ASCII per the specification.

=head1 DEPENDENCIES

None beyond L<Exporter>, which is part of the Perl core.

=head1 REFERENCES

=over 4

=item B<[RFC 3986]>

Berners-Lee, T., Fielding, R., and Masinter, L.: I<Uniform Resource Identifiers (URI): Generic Syntax>. January 2005. Supersedes RFC 2732, RFC 2396, and RFC 1808.
L<http://tools.ietf.org/html/rfc3986>

=item B<[RFC 2396]>

Berners-Lee, T., Fielding, R., and Masinter, L.: I<Uniform Resource Identifiers (URI): Generic Syntax>. August 1998.
L<http://tools.ietf.org/html/rfc2396>

=back

=head1 COMPATIBILITY

This module has been tested on Perl 5.10 and 5.12 via perlbrew (local), and on Perl 5.14 through 5.40 via the GitLab CI pipeline.

=head1 SEE ALSO

L<Regexp::Common::URI::RFC2396> in the C<Regexp-Common> distribution, which this module supersedes.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

The export structure and variable naming follow the conventions established by Damian Conway and Abigail in C<Regexp::Common::URI::RFC2396>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2025-2026, Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
