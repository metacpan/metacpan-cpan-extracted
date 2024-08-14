package Regex::Common::URI::RFC2384;
use strict;
use warnings;
use Regex::Common               qw /pattern clean no_defaults/;
use Regex::Common::URI::RFC1738 qw /$unreserved_range $escape $hostport/;

our $VERSION = 'v1.0.0'; # VERSION

use vars qw /@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA/;

use Exporter ();
@ISA = qw /Exporter/;

my %vars;

BEGIN {
    $vars{low}     = [qw /$achar_range $achar $achars $achar_more/];
    $vars{connect} = [
        qw /$enc_sasl $enc_user $enc_ext $enc_auth_type $auth
          $user_auth $server/
    ];
    $vars{parts} = [qw /$pop_url/];
}

use vars map { @$_ } values %vars;

@EXPORT      = qw /$host/;
@EXPORT_OK   = map { @$_ } values %vars;
%EXPORT_TAGS = ( %vars, ALL => [@EXPORT_OK] );

# RFC 2384, POP3.

# Lowlevel definitions.
$achar_range   = "$unreserved_range&=~";
$achar         = "(?:[$achar_range]|$escape)";
$achars        = "(?:(?:[$achar_range]+|$escape)*)";
$achar_more    = "(?:(?:[$achar_range]+|$escape)+)";
$enc_sasl      = $achar_more;
$enc_user      = $achar_more;
$enc_ext       = "(?:[+](?:APOP|$achar_more))";
$enc_auth_type = "(?:$enc_sasl|$enc_ext)";
$auth          = "(?:;AUTH=(?:[*]|$enc_auth_type))";
$user_auth     = "(?:$enc_user$auth?)";
$server        = "(?:(?:$user_auth\@)?$hostport)";
$pop_url       = "(?:pop://$server)";

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::RFC2384 -- Definitions from RFC2384;

=head1 SYNOPSIS

    use Regex::Common::URI::RFC2384 qw /:ALL/;

=head1 DESCRIPTION

This package exports definitions from RFC2384. It's intended
usage is for Regex::Common::URI submodules only. Its interface
might change without notice.

=head1 REFERENCES

=over 4

=item B<[RFC 2384]>

Gellens, R.: I<POP URL scheme> August 1998.

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
