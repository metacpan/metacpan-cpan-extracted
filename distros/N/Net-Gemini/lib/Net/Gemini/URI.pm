# -*- Perl -*-
#
# Gemini protocol URI support, based on RFC 3986 and the specification
#
#   "Yuri Alekseyevich Gagarin was a Soviet pilot and cosmonaut who
#   became the first human to journey into outer space."

package Net::Gemini::URI;
our $VERSION = '0.03';
use 5.10.0;
use overload '""' => \&canonical;
use Carp 'confess';

our ( @ISA, @EXPORT_OK );

BEGIN {
    require Exporter;
    @ISA       = qw(Exporter);
    @EXPORT_OK = qw(parse_gemini_uri);
}

sub host     { defined $_[1] ? $_[0][0] = $_[1] : $_[0][0] }
sub port     { defined $_[1] ? $_[0][1] = $_[1] : $_[0][1] }
sub path     { defined $_[1] ? $_[0][2] = $_[1] : $_[0][2] }
sub query    { defined $_[1] ? $_[0][3] = $_[1] : $_[0][3] }
sub fragment { defined $_[1] ? $_[0][4] = $_[1] : $_[0][4] }

sub hostport { $_[0][0], $_[0][1] }

sub canonical {
    # KLUGE IPv6 "detection"
    my $host = $_[0][0];
    $host = '[' . $host . ']' if $host =~ m/:/;

    'gemini://'
      . $host
      . ( $_[0][1] == 1965 ? '' : ":$_[0][1]" )
      . $_[0][2]
      . ( defined $_[0][3] ? "?$_[0][3]" : '' )
      . ( defined $_[0][4] ? "#$_[0][4]" : '' );
}

sub new {
    my ( $class, $uri ) = @_;
    my ( $aref,  $err ) = parse_gemini_uri($uri);
    bless $aref, $class if defined $aref;
    $aref, $err;
}

sub parse_gemini_uri {
    my ($uri) = @_;
    return ( undef, 'URI undefined' ) unless defined $uri;
    # borrowed from the URI module perldoc
    my ( $scheme, $authority, $path, $query, $fragment ) =
      $uri =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
    return ( undef, 'URI unknown' ) if $scheme ne 'gemini';
    return ( undef, 'authority is required' ) unless length $authority;
    return ( undef, 'userinfo is not allowed' ) if $authority =~ m/[@]/;
    my ( $host, $port );
    # regular expressions were borrowed from Regexp::Common 2017060201;
    # they hopefully will not change much if at all and I want to keep
    # the dependency list as slim as possible. downside: needs 5.10.0
    if ( $authority =~
        m/^\[((?|(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4})|(?::(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):)))\]/
        or $authority =~
        m/^((?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))/
        or $authority =~
        m/^([A-Za-z](?:(?:[-A-Za-z0-9]){0,61}[A-Za-z0-9])?(?:\.[A-Za-z](?:(?:[-A-Za-z0-9]){0,61}[A-Za-z0-9])?)*)/
    ) {
        $host = $1;
    } else {
        return ( undef, "unknown authority '$authority'" );
    }
    if ( $authority =~ m/:([0-9]+)$/ ) {
        $port = $1;
        return ( undef, "port is out of range" ) if $port < 1 or $port > 65535;
    } else {
        $port = 1965;
    }
    $path = '/' unless length $path;
    [ $host, $port, $path, $query, $fragment ], undef;
}

1;
__END__

=head1 NAME

Net::Gemini::URI - Gemini protocol URI support

=head1 SYNOPSIS

  use Net::Gemini::URI;
  my ( $u, $err ) = Net::Gemini::URI->new('gemini://example.org');
  print $u->canonical, "\n";    # gemini://example.org/

  $u->host('example.com');
  print "$u\n";                 # gemini://example.com/

=head1 DESCRIPTION

This module provides Gemini protocol URI support, based on RFC 3986 and
the specification.

Note that Gemini request URI are restricted to 1024 bytes and must use
the UTF-8 encoding. These restrictions are not enforced by this module,
but are in L<Net::Gemini>. Also no particular handling of percent
encoding is done by this module, nor of path normalization. This may
need to change.

=head1 METHODS

=over 4

=item B<new> I<URI>

B<new> accepts a URI, and returns a list consisting of one of the
following two forms:

  object, undef
  undef, "error message"

Using the object in string context will emit the B<canonical> URI.

=item B<hostport>

Returns the host and port.

=item B<canonical>

Returns the URI in canonical form, as per section 6.2.3 of RFC 3986
assuming that I read that documentation aright.

=item B<host> [ I<new-host> ]
=item B<port> [ I<new-port> ]
=item B<path> [ I<new-path> ]
=item B<query> [ I<new-query> ]
=item B<fragment> [ I<new-fragment> ]

Returns the given portion of the URI after optionally setting a new
value. These methods do not do anything by way of validation of the
input, unlike B<new> does, so could be used to construct very
invalid URI.

=back

=head1 FUNCTION

=over 4

=item B<parse_gemini_uri> I<URI>

The B<parse_gemini_uri> function accepts a URI and returns one of the
two following lists:

  undef, "error message";                               # error
  [ $host, $port, $path, $query, $fragment ], undef;    # success

It is used internally by the B<new> method. It is not exported by default.

=back

=head1 BUGS

None known. But it is a rather incomplete module; that may be
considered a bug?

=head1 SEE ALSO

L<Net::Gemini>

L<gemini://gemini.circumlunar.space/docs/specification.gmi> (v0.16.1)

RFC 3986

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
