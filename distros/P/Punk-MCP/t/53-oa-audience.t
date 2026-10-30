#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    plan skip_all => 'Punk-OAuth2 0.08 and Crypt::JWS required'
        unless eval { require Punk::OAuth2::Checker; Punk::OAuth2->VERSION('0.08');
                      require Crypt::JWS; 1 };
}
use PMCPOA;
use PMCPAuth qw(token);

# With oauth, the caller's token is bound to the MCP endpoint (11), and an
# OpenAPI tool carries it on to the mount, whose own checker decides. Three
# cases, as the POD has them.

my $OAUTH = q{oauth => { issuer => 'https://id.test', key => $PMCPAuth::SECRET,
                         algs => ['HS256'], scopes => ['mcp'] }};
my $MCP = 'http://localhost/mcp';
my $tok = token();

sub mount_checker {
    my ($aud) = @_;
    return "Punk::OAuth2::Checker->jwt(issuer => 'https://id.test', audience => '$aud',
            key => \$PMCPAuth::SECRET, algs => ['HS256'])";
}

my @w;
my $t;
{
    local $SIG{__WARN__} = sub { push @w, @_ };
    $t = oa_app("openapi => '*', $OAUTH",
                security => 'sub { $_[0] ? { any => 1 } : undef }');
}
like(join('', @w), qr/openapi tools carry the caller's token to the mount, whose own checker decides/,
    'boot says the mount checker decides');
my $r = oa_call($t, 'adminop', {}, Authorization => "Bearer $tok")->{result};
ok(!$r->{isError}, 'a mount that checks no audience: the token passes');

{
    local $SIG{__WARN__} = sub {};
    $t = oa_app("openapi => '*', $OAUTH", security => mount_checker('https://api.acme.test'));
}
$r = oa_call($t, 'adminop', {}, Authorization => "Bearer $tok")->{result};
ok($r->{isError}, 'a mount that wants another audience: the token is refused there');
is($r->{_meta}{status}, 401, 'with the mount\'s 401, as a tool error');

{
    local $SIG{__WARN__} = sub {};
    $t = oa_app("openapi => '*', $OAUTH", security => mount_checker($MCP));
}
$r = oa_call($t, 'adminop', {}, Authorization => "Bearer $tok")->{result};
ok(!$r->{isError}, 'a mount that accepts this endpoint\'s audience: the token passes');

$t->post_ok('/mcp', body => '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"adminop","arguments":{}}}',
            type => 'application/json',
            headers => { Authorization => 'Bearer ' . token(aud => 'https://api.acme.test') });
is($t->status, 401, 'a token issued for the API alone is refused at the MCP endpoint');

done_testing;
