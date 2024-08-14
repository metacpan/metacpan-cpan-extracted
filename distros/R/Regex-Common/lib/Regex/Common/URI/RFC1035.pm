package Regex::Common::URI::RFC1035;
use strict;
use warnings;
use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

use vars qw /@EXPORT @EXPORT_OK %EXPORT_TAGS @ISA/;

use Exporter ();
@ISA = qw /Exporter/;

my %vars;

BEGIN {
    $vars{low}    = [qw /$digit $letter $let_dig $let_dig_hyp $ldh_str/];
    $vars{parts}  = [qw /$label $subdomain/];
    $vars{domain} = [qw /$domain/];
}

use vars map { @$_ } values %vars;

@EXPORT      = qw /$host/;
@EXPORT_OK   = map { @$_ } values %vars;
%EXPORT_TAGS = ( %vars, ALL => [@EXPORT_OK] );

# RFC 1035.
$digit       = "[0-9]";
$letter      = "[A-Za-z]";
$let_dig     = "[A-Za-z0-9]";
$let_dig_hyp = "[-A-Za-z0-9]";
$ldh_str     = "(?:[-A-Za-z0-9]+)";
$label       = "(?:$letter(?:(?:$ldh_str){0,61}$let_dig)?)";
$subdomain   = "(?:$label(?:[.]$label)*)";
$domain      = "(?: |(?:$subdomain))";

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::RFC1035 -- Definitions from RFC1035;

=head1 SYNOPSIS

    use Regex::Common::URI::RFC1035 qw /:ALL/;

=head1 DESCRIPTION

This package exports definitions from RFC1035. It's intended
usage is for Regex::Common::URI submodules only. Its interface
might change without notice.

=head1 REFERENCES

=over 4

=item B<[RFC 1035]>

Mockapetris, P.: I<DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION>.
November 1987.

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
