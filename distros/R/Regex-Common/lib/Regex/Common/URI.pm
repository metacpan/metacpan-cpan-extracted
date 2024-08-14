package Regex::Common::URI;
use strict;
use warnings;
no warnings 'syntax';

use Exporter ();

our @ISA       = qw /Exporter/;
our @EXPORT_OK = qw /register_uri/;

use Regex::Common qw /pattern clean no_defaults/;

our $VERSION = 'v1.0.0'; # VERSION

# Use 'require' here, not 'use', so we delay running them after we are compiled.
# We also do it using an 'eval'; this saves us from have repeated similar
# lines. The eval is further explained in 'perldoc -f require'.
my @uris = qw /fax file ftp gopher http pop prospero news tel telnet tv wais/;
foreach my $uri (@uris) {
    eval "require Regex::Common::URI::$uri";
    die $@ if $@;
}

my %uris;

sub register_uri {
    my ( $scheme, $uri ) = @_;
    $uris{$scheme} = $uri;
}

pattern
  name   => [qw (URI)],
  create => sub {
    my $uri = join '|' => values %uris;
    $uri =~ s/\(\?k:/(?:/g;
    "(?k:$uri)";
  },
  ;

1;

__END__

=pod

=head1 NAME

Regex::Common::URI -- provide patterns for URIs.

=head1 SYNOPSIS

    use Regex::Common qw /URI/;

    while (<>) {
        /$RE{URI}{HTTP}/       and  print "Contains an HTTP URI.\n";
    }

=head1 DESCRIPTION

Patterns for the following URIs are supported: fax, file, FTP, gopher,
HTTP, news, NTTP, pop, prospero, tel, telnet, tv and WAIS.
Each is documented in the I<Regex::Common::URI::B<scheme>>,
manual page, for the appropriate scheme (in lowercase), except for
I<NNTP> URIs which are found in I<Regex::Common::URI::news>.

=head2 C<$RE{URI}>

Return a pattern that recognizes any of the supported URIs. With
C<{-keep}>, only the entire URI is returned (in C<$1>).

=head1 REFERENCES

=over 4

=item B<[DRAFT-URI-TV]>

Zigmond, D. and Vickers, M: I<Uniform Resource Identifiers for
Television Broadcasts>. December 2000.

=item B<[DRAFT-URL-FTP]>

Casey, James: I<A FTP URL Format>. November 1996.

=item B<[RFC 1035]>

Mockapetris, P.: I<DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION>.
November 1987.

=item B<[RFC 1738]>

Berners-Lee, Tim, Masinter, L., McCahill, M.: I<Uniform Resource
Locators (URL)>. December 1994.

=item B<[RFC 2396]>

Berners-Lee, Tim, Fielding, R., and Masinter, L.: I<Uniform Resource
Identifiers (URI): Generic Syntax>. August 1998.

=item B<[RFC 2616]>

Fielding, R., Gettys, J., Mogul, J., Frystyk, H., Masinter, L.,
Leach, P. and Berners-Lee, Tim: I<Hypertext Transfer Protocol -- HTTP/1.1>.
June 1999.

=item B<[RFC 2806]>

Vaha-Sipila, A.: I<URLs for Telephone Calls>. April 2000.

=back

=head1 SEE ALSO

L<Regex::Common> for a general description of how to use this interface.

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
