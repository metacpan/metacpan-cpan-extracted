package PowerDNS::API::ACL 0.002;

#ABSTRACT: Per-token access control in front of the PowerDNS HTTP API

use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

use List::Util 1.33 qw{any};


# A refusal: the status to answer with, and why.
my $refuse = sub {
    my ( $status, $reason ) = @_;
    return { allow => 0, status => $status, reason => $reason };
};


sub new {
    my ( $class, %opts ) = @_;
    die "PowerDNS::API::ACL needs a store\n" unless $opts{store};
    return bless { store => $opts{store} }, $class;
}


sub canonical_name {
    my ( undef, $name ) = @_;
    $name = lc( $name // q{} );
    $name =~ s/[.]*\z/./;
    return $name;
}


sub covers {
    my ( $class, $grant, $name, $type ) = @_;
    $name = $class->canonical_name($name);

    my @types = @{ $grant->{types} // ['*'] };
    return 0 unless any { $_ eq q{*} || uc($_) eq uc( $type // q{} ) } @types;

    my $pattern = $class->canonical_name( $grant->{name} );
    if ( index( $pattern, q{*.} ) == 0 ) {
        my $below = substr( $pattern, 1 );
        return length($name) > length($below) && substr( $name, -length $below ) eq $below ? 1 : 0;
    }

    return $name eq $pattern ? 1 : 0;
}


sub authorize {
    my ( $self, %req ) = @_;

    my @grants = $self->{store}->grants_for_token( $req{token} // q{} );
    return $refuse->( 401, 'Unknown API key' ) unless @grants;

    my $method = uc( $req{method} // q{} );
    my $path   = $req{path} // q{};

    # Creating a zone names it in the body, not in the path.
    if ( $path =~ m{\A/api/v1/servers/[^/]+/zones/?\z} ) {
        my $new = ref $req{body} eq 'HASH' ? __PACKAGE__->canonical_name( $req{body}{name} ) : q{.};
        return { allow => 1 } if $method eq 'POST' && any { $_->{access} eq 'manage' && __PACKAGE__->canonical_name( $_->{zone} ) eq $new } @grants;
        return $refuse->( 403, $method eq 'POST' ? "This key cannot create the zone $new" : 'This key cannot list zones' );
    }

    my ( $zone, $notify ) = $path =~ m{\A/api/v1/servers/[^/]+/zones/([^/]+?)(/notify)?/?\z};
    return $refuse->( 403, 'Only the records of a zone are open to this key' ) unless defined $zone;

    # PowerDNS escapes a byte of a zone id as =XX, so a slash in a classless
    # reverse zone is =2F.
    $zone =~ s/=([[:xdigit:]]{2})/chr hex $1/ge;
    $zone = __PACKAGE__->canonical_name($zone);
    my @in_zone = grep { __PACKAGE__->canonical_name( $_->{zone} ) eq $zone } @grants;
    return $refuse->( 403, "This key has no grant in $zone" ) unless @in_zone;

    my @write = grep { $_->{access} eq 'write' } @in_zone;

    my $manages = any { $_->{access} eq 'manage' } @in_zone;
    if ( $method eq 'DELETE' && !$notify ) {    ## no critic (ValuesAndExpressions::PreventSQLInjection) -- an HTTP method, not SQL
        return $manages ? { allow => 1 } : $refuse->( 403, "Removing the zone $zone is not open to this key" );
    }
    if ($notify) {
        return $method eq 'PUT' && @write ? { allow => 1 } : $refuse->( 403, "This key cannot notify for $zone" );
    }
    my @readable = grep { $_->{access} ne 'manage' } @in_zone;
    return { allow => 1, filter => \@readable } if $method eq 'GET' && @readable;
    return $refuse->( 403, "This key cannot $method $zone" ) unless $method eq 'PATCH';

    my $rrsets = ref $req{body} eq 'HASH' ? $req{body}{rrsets} : undef;
    return $refuse->( 403, 'A PATCH without rrsets changes nothing this key may change' ) unless ref $rrsets eq 'ARRAY' && @$rrsets;

    foreach my $rrset (@$rrsets) {
        my ( $name, $type ) = @{$rrset}{qw{name type}};
        next if any { __PACKAGE__->covers( $_, $name, $type ) } @write;
        return $refuse->( 403, sprintf( 'This key cannot write the %s records of %s', $type // '(no type)', __PACKAGE__->canonical_name($name) ) );
    }

    return { allow => 1 };
}


sub filter_zone {
    my ( $class, $zone, $grants ) = @_;
    return $zone unless ref $zone eq 'HASH' && ref $zone->{rrsets} eq 'ARRAY';

    my @visible;
    foreach my $rrset ( @{ $zone->{rrsets} } ) {
        push( @visible, $rrset ) if any { $class->covers( $_, $rrset->{name}, $rrset->{type} ) } @$grants;
    }
    $zone->{rrsets} = \@visible;

    return $zone;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PowerDNS::API::ACL - Per-token access control in front of the PowerDNS HTTP API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use PowerDNS::API::ACL;
    use PowerDNS::API::ACL::Store;

    my $store = PowerDNS::API::ACL::Store->new( path => '/var/lib/pdns-acl/acl.db' );
    my $acl   = PowerDNS::API::ACL->new( store => $store );

    my $verdict = $acl->authorize(
        token  => 'the-key-the-client-sent',
        method => 'PATCH',
        path   => '/api/v1/servers/localhost/zones/lab.example.net.',
        body   => { rrsets => [ { name => 'web1.lab.example.net.', type => 'A', changetype => 'REPLACE' } ] },
    );
    return [ $verdict->{status}, [], [ $verdict->{reason} ] ] unless $verdict->{allow};

=head1 DESCRIPTION

The PowerDNS API has one key, and the key can do everything: read and rewrite
every zone, create and delete zones, and change the configuration of the
server.  A client that needs to write one record must therefore be trusted with
all of them.

This distribution puts a list of grants between a client and that key.  Each
client gets a token of its own.  A grant lets one token read or write the
records of a set of names in one zone.  L<PowerDNS::API::ACL::Proxy> is a PSGI
application that checks each request against the grants, and passes only
allowed requests to PowerDNS with the real key.  L<PowerDNS::API::ACL::Store>
keeps the tokens and the grants in SQLite, and C<pdns-acl> manages them.

This module is the decision.  It knows the requests that a record client makes,
which are the calls that dns-lexicon makes:

=over 4

=item C<GET /api/v1/servers/:server/zones/:zone>

Allowed when the token has any grant in the zone.  The response holds every
record of the zone, so the proxy passes on only the records that the token can
read.  See C<filter_zone>.

=item C<PATCH /api/v1/servers/:server/zones/:zone>

Allowed when every rrset in the body is one that the token can write.  One
rrset that it cannot write refuses the whole request, because PowerDNS applies
a PATCH as one change.

=item C<PUT /api/v1/servers/:server/zones/:zone/notify>

Allowed when the token can write anything in the zone.

=item C<POST /api/v1/servers/:server/zones>

Creates the zone that the body names.  Allowed when the token has a C<manage>
grant for that zone.

=item C<DELETE /api/v1/servers/:server/zones/:zone>

Allowed when the token has a C<manage> grant for the zone.

=back

Every other request is refused.  That includes the list of zones, a change to
the settings of a zone, search, and the configuration of the server.

=head2 Grants

A grant has four parts:

=over 4

=item C<zone>

The zone, as PowerDNS names it, with the trailing dot.

=item C<name>

The names that the grant covers.  Either one name, such as
C<webmail.lab.example.net.>, or C<*.> and a name, such as
C<*.lab.example.net.>, which covers every name below that name at any depth
and not the name itself.  The name must be in the zone.

=item C<types>

The record types that the grant covers, such as C<A> and C<CNAME>, or C<*> for
every type.

=item C<access>

C<read>, C<write> or C<manage>.  A write grant also lets the token read.  A
manage grant lets the token create and delete the zone, and nothing else: it
reads and writes no record.  Its name is the zone, and its types are C<*>.

=back

Names compare without regard to case, and always with the trailing dot.

A token that needs its own records gets two grants: its name, and C<*.> and
its name, which covers the names below it, such as the C<_acme-challenge>
record of its certificate.

=head2 Limitations

=over 4

=item * A grant cannot restrict the content of a record.  A token that may
write the A records of a name can point that name at any address.  Every DNS
provider works this way.

=item * There are no rules that deny, and no default other than refusal.  A
token can do what its grants allow, and nothing else.

=item * A grant cannot let a token change the settings of a zone, such as its
kind or its masters, or rectify or export it.

=back

=head1 METHODS

=head2 new(store => $store)

C<store> is a L<PowerDNS::API::ACL::Store>, or anything that answers
C<grants_for_token>.

=head2 canonical_name($name)

Returns C<$name> in lower case with one trailing dot.  A class method.

=head2 covers($grant, $name, $type)

True when C<$grant> covers the record C<$name> of type C<$type>.  A class
method, and it ignores C<access>.

=head2 authorize(token => $token, method => $method, path => $path, body => $body)

Decides one request.  C<body> is the decoded JSON of the request, or undef.

Returns a hash reference.  C<allow> is true or false, C<status> is the HTTP
status of a refusal (401 for an unknown token, 403 for a refused request), and
C<reason> says why.  An allowed GET of a zone also carries C<filter>, the
grants that C<filter_zone> needs for the response.

=head2 filter_zone($zone, $grants)

Takes the decoded response to a GET of a zone and the C<filter> that
C<authorize> returned, and removes each rrset that none of the grants covers.
Changes C<$zone> in place and returns it.  A class method.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-powerdns-api-acl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
