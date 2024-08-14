package Regex::Common::URI::news;
use strict;
use warnings;
use Regex::Common               qw /pattern clean no_defaults/;
use Regex::Common::URI          qw /register_uri/;
use Regex::Common::URI::RFC1738 qw /$grouppart $group $article
  $host $port $digits/;

our $VERSION = 'v1.0.0'; # VERSION

my $news_scheme = 'news';
my $news_uri    = "(?k:(?k:$news_scheme):(?k:$grouppart))";

my $nntp_scheme = 'nntp';
my $nntp_uri    = "(?k:(?k:$nntp_scheme)://(?k:(?k:(?k:$host)(?::(?k:$port))?)"
  . "/(?k:$group)(?:/(?k:$digits))?))";

register_uri $news_scheme => $news_uri;
register_uri $nntp_scheme => $nntp_uri;

pattern
  name   => [qw (URI news)],
  create => $news_uri,
  ;

pattern
  name   => [qw (URI NNTP)],
  create => $nntp_uri,
  ;

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::news -- Returns a pattern for file URIs.

=head1 SYNOPSIS

    use Regex::Common qw /URI/;

    while (<>) {
        /$RE{URI}{news}/       and  print "Contains a news URI.\n";
    }

=head1 DESCRIPTION

=head2 $RE{URI}{news}

Returns a pattern that matches I<news> URIs, as defined by RFC 1738.
News URIs have the form:

    "news:" ( "*" | group | article "@" host )

Under C<{-keep}>, the following are returned:

=over 4

=item $1

The complete URI.

=item $2

The scheme.

=item $3

The part of the URI following "news://".

=back

=head2 $RE{URI}{NNTP}

Returns a pattern that matches I<NNTP> URIs, as defined by RFC 1738.
NNTP URIs have the form:

    "nntp://" host [ ":" port ] "/" group [ "/" digits ]

Under C<{-keep}>, the following are returned:

=over 4

=item $1

The complete URI.

=item $2

The scheme.

=item $3

The part of the URI following "nntp://".

=item $4

The host and port, separated by a colon. If no port was given, just
the host.

=item $5

The host.

=item $6

The port, if given.

=item $7

The group.

=item $8

The digits, if given.

=back

=head1 REFERENCES

=over 4

=item B<[RFC 1738]>

Berners-Lee, Tim, Masinter, L., McCahill, M.: I<Uniform Resource
Locators (URL)>. December 1994.

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
