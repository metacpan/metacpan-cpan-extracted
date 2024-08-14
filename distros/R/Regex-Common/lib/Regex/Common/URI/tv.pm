package Regex::Common::URI::tv;
use strict;
use warnings;
use Regex::Common               qw /pattern clean no_defaults/;
use Regex::Common::URI          qw /register_uri/;
use Regex::Common::URI::RFC2396 qw /$hostname/;

our $VERSION = 'v1.0.0'; # VERSION

my $tv_scheme = 'tv';
my $tv_url    = "(?k:(?k:$tv_scheme):(?k:$hostname)?)";

register_uri $tv_scheme => $tv_url;

pattern
  name   => [qw (URI tv)],
  create => $tv_url,
  ;

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::tv -- Returns a pattern for tv URIs.

=head1 SYNOPSIS

    use Regex::Common qw /URI/;

    while (<>) {
        /$RE{URI}{tv}/       and  print "Contains a tv URI.\n";
    }

=head1 DESCRIPTION

=head2 C<$RE{URI}{tv}>

Returns a pattern that recognizes TV uris as per an Internet draft
[DRAFT-URI-TV].

Under C<{-keep}>, the following are returned:

=over 4

=item $1

The entire URI.

=item $2

The scheme.

=item $3

The host.

=back

=head1 REFERENCES

=over 4

=item B<[DRAFT-URI-TV]>

Zigmond, D. and Vickers, M: I<Uniform Resource Identifiers for
Television Broadcasts>. December 2000.

=item B<[RFC 2396]>

Berners-Lee, Tim, Fielding, R., and Masinter, L.: I<Uniform Resource
Identifiers (URI): Generic Syntax>. August 1998.

=back

=head1 SEE ALSO

L<Regex::Common::URI> for other supported URIs.

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
