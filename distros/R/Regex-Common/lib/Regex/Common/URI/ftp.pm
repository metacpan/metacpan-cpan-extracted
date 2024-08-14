package Regex::Common::URI::ftp;
use strict;
use warnings;
use Regex::Common               qw /pattern clean no_defaults/;
use Regex::Common::URI          qw /register_uri/;
use Regex::Common::URI::RFC2396 qw /$host $port $ftp_segments $userinfo
  $userinfo_no_colon/;

our $VERSION = 'v1.0.0'; # VERSION

my $ftp_uri =
    "(?k:(?k:ftp)://(?:(?k:$userinfo)(?k:)\@)?(?k:$host)"
  . "(?::(?k:$port))?(?k:/(?k:(?k:$ftp_segments)"
  . "(?:;type=(?k:[AIai]))?))?)";

my $ftp_uri_password =
    "(?k:(?k:ftp)://(?:(?k:$userinfo_no_colon)"
  . "(?::(?k:$userinfo_no_colon))?\@)?(?k:$host)"
  . "(?::(?k:$port))?(?k:/(?k:(?k:$ftp_segments)"
  . "(?:;type=(?k:[AIai]))?))?)";

register_uri FTP => $ftp_uri;

pattern
  name   => [ qw (URI FTP), "-type=[AIai]", "-password=" ],
  create => sub {
    my $uri =
      exists $_[1]->{-password} && !defined $_[1]->{-password}
      ? $ftp_uri_password
      : $ftp_uri;
    my $type = $_[1]->{-type};
    $uri =~ s/\[AIai\]/$type/;
    $uri;
  };

1;

__END__

=pod

=head1 NAME

Regex::Common::URI::ftp -- Returns a pattern for FTP URIs.

=head1 SYNOPSIS

    use Regex::Common qw /URI/;

    while (<>) {
        /$RE{URI}{FTP}/       and  print "Contains an FTP URI.\n";
    }

=head1 DESCRIPTION

=head2 $RE{URI}{FTP}{-type}{-password};

Returns a regex for FTP URIs. Note: FTP URIs are not formally defined.
RFC 1738 defines FTP URLs, but parts of that RFC have been obsoleted
by RFC 2396. However, the differences between RFC 1738 and RFC 2396
are such that they aren't applicable straightforwardly to FTP URIs.

There are two main problems:

=over 4

=item Passwords.

RFC 1738 allowed an optional username and an optional password (separated
by a colon) in the FTP URL. Hence, colons were not allowed in either the
username or the password. RFC 2396 strongly recommends passwords should
not be used in URIs. It does allow for I<userinfo> instead. This userinfo
part may contain colons, and hence contain more than one colon. The regexp
returned follows the RFC 2396 specification, unless the I<{-password}>
option is given; then the regex allows for an optional username and
password, separated by a colon.

=item The ;type specifier.

RFC 1738 does not allow semi-colons in FTP path names, because a semi-colon
is a reserved character for FTP URIs. The semi-colon is used to separate
the path from the option I<type> specifier. However, in RFC 2396, paths
consist of slash separated segments, and each segment is a semi-colon
separated group of parameters. Straigthforward application of RFC 2396
would mean that a trailing I<type> specifier couldn't be distinguished
from the last segment of the path having a two parameters, the last one
starting with I<type=>. Therefore we have opted to disallow a semi-colon
in the path part of an FTP URI.

Furthermore, RFC 1738 allows three values for the type specifier, I<A>,
I<I> and I<D> (either upper case or lower case). However, the internet
draft about FTP URIs B<[DRAFT-FTP-URL]> (which expired in May 1997) notes
the lack of consistent implementation of the I<D> parameter and drops I<D>
from the set of possible values. We follow this practise; however, RFC 1738
behaviour can be archieved by using the I<-type => "[ADIadi]"> parameter.

=back

FTP URIs have the following syntax:

    "ftp:" "//" [ userinfo "@" ] host [ ":" port ]
                [ "/" path [ ";type=" value ]]

When using I<{-password}>, we have the syntax:

    "ftp:" "//" [ user [ ":" password ] "@" ] host [ ":" port ]
                [ "/" path [ ";type=" value ]]

Under C<{-keep}>, the following are returned:

=over 4

=item $1

The complete URI.

=item $2

The scheme.

=item $3

The userinfo, or if I<{-password}> is used, the username.

=item $4

If I<{-password}> is used, the password, else C<undef>.

=item $5

The hostname or IP address.

=item $6

The port number.

=item $7

The full path and type specification, including the leading slash.

=item $8

The full path and type specification, without the leading slash.

=item $9

The full path, without the type specification nor the leading slash.

=item $10

The value of the type specification.

=back

=head1 REFERENCES

=over 4

=item B<[DRAFT-URL-FTP]>

Casey, James: I<A FTP URL Format>. November 1996.

=item B<[RFC 1738]>

Berners-Lee, Tim, Masinter, L., McCahill, M.: I<Uniform Resource
Locators (URL)>. December 1994.

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
