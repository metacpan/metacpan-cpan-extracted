package Regex::Common::URI::http;
use strict;
use warnings;
use Regex::Common               qw /pattern clean no_defaults/;
use Regex::Common::URI          qw /register_uri/;
use Regex::Common::URI::RFC2396 qw /$host $port $path_segments $query/;

our $VERSION = 'v1.0.0'; # VERSION

my $http_uri = "(?k:(?k:http)://(?k:$host)(?::(?k:$port))?"
  . "(?k:/(?k:(?k:$path_segments)(?:[?](?k:$query))?))?)";

my $https_uri = $http_uri;
$https_uri =~ s/http/https?/;

register_uri HTTP => $https_uri;

pattern
  name   => [ qw (URI HTTP), "-scheme=http" ],
  create => sub {
    my $scheme = $_[1]->{-scheme};
    my $uri    = $http_uri;
    $uri =~ s/http/$scheme/;
    $uri;
  };

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::http -- Returns a pattern for HTTP URIs.

=head1 SYNOPSIS

    use Regex::Common qw /URI/;

    while (<>) {
        /$RE{URI}{HTTP}/       and  print "Contains an HTTP URI.\n";
    }

=head1 DESCRIPTION

=head2 $RE{URI}{HTTP}{-scheme}

Provides a regex for an HTTP URI as defined by RFC 2396 (generic syntax)
and RFC 2616 (HTTP).

If C<< -scheme => I<P> >> is specified the pattern I<P> is used as the scheme.
By default I<P> is C<qr/http/>. C<https> and C<https?> are reasonable
alternatives.

The syntax for an HTTP URI is:

    "http:" "//" host [ ":" port ] [ "/" path [ "?" query ]]

Under C<{-keep}>, the following are returned:

=over 4

=item $1

The entire URI.

=item $2

The scheme.

=item $3

The host (name or address).

=item $4

The port (if any).

=item $5

The absolute path, including the query and leading slash.

=item $6

The absolute path, including the query, without the leading slash.

=item $7

The absolute path, without the query or leading slash.

=item $8

The query, without the question mark.

=back

=head1 REFERENCES

=over 4

=item B<[RFC 2396]>

Berners-Lee, Tim, Fielding, R., and Masinter, L.: I<Uniform Resource
Identifiers (URI): Generic Syntax>. August 1998.

=item B<[RFC 2616]>

Fielding, R., Gettys, J., Mogul, J., Frystyk, H., Masinter, L.,
Leach, P. and Berners-Lee, Tim: I<Hypertext Transfer Protocol -- HTTP/1.1>.
June 1999.

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
