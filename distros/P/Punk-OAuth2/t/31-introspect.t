#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POUA;
use MockIdP;
use Punk::OAuth2::Checker;

my $idp = MockIdP::app();
my $ua  = POUA->new(map => { idp_origin() => $idp });
sub idp_origin { $MockIdP::ISSUER }

my $intro = Punk::OAuth2::Checker->introspect(
    url           => "$MockIdP::ISSUER/introspect",
    client_id     => $MockIdP::CLIENT_ID,
    client_secret => $MockIdP::CLIENT_SECRET,
    ua            => $ua,
    cache_ttl     => 60,
);

my $fake = FakeCtx->new;

# active token -> claims
{
    my $claims = $intro->('good-read', $fake, undef, undef);
    ok $claims, 'active token accepted';
    is $claims->{sub}, 'user-1', 'introspection claims returned';
}

# inactive token -> false
{
    my $c = FakeCtx->new;
    my $claims = $intro->('bogus', $c, undef, undef);
    ok !$claims, 'inactive token rejected';
    is $c->stash->{'punk.oauth2.error'}, 'invalid_token',
        'invalid_token recorded';
}

# scope enforcement from the introspection response
{
    my $c = FakeCtx->new;
    ok $intro->('good-read', $c, undef, ['read']),
        'scope satisfied by introspection';
    my $c2 = FakeCtx->new;
    ok !$intro->('good-read', $c2, undef, ['admin']),
        'missing scope rejected';
    is $c2->stash->{'punk.oauth2.error'}, 'insufficient_scope',
        'insufficient_scope recorded';
}

# cache: a second call for the same token does not hit the endpoint again
{
    my $before = scalar @{ $ua->log };
    $intro->('good-freshcache', FakeCtx->new, undef, undef);
    my $after1 = scalar @{ $ua->log };
    $intro->('good-freshcache', FakeCtx->new, undef, undef);
    my $after2 = scalar @{ $ua->log };
    ok $after1 > $before, 'first (uncached) call hit the endpoint';
    is $after2, $after1, 'second call served from cache (no new request)';
}

# guard integration
{
    my $g = Punk::OAuth2::Checker->guard($intro, scopes => ['read']);
    my $c = FakeCtx->new(auth => 'Bearer good-read');
    my $r = $g->($c);
    ok !defined $r, 'guard passes an active, in-scope token';
    my $c2 = FakeCtx->new(auth => 'Bearer bogus');
    my $r2 = $g->($c2);
    is $r2->[0], 401, 'guard 401s an inactive token';
}

done_testing();

package FakeCtx;
sub new {
    my ($class, %o) = @_;
    return bless { stash => {}, auth => $o{auth} }, $class;
}
sub stash { $_[0]{stash} }
sub req   { $_[0] }
sub header {
    my ($self, $name) = @_;
    return $name eq 'Authorization' ? $self->{auth} : undef;
}
