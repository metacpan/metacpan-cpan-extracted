#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use JSON::PP ();
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    plan skip_all => 'Punk-OAuth2 0.08 required'
        unless eval { require Punk::OAuth2::Checker; Punk::OAuth2->VERSION('0.08'); 1 };
}
use PMCPAuth;

my $t = auth_app(q{title => 'Acme', website => 'https://acme.test/docs',
    oauth => { issuer => 'https://id.test', key => $PMCPAuth::SECRET, algs => ['HS256'],
               scopes => ['mcp', 'mcp:write'] }});

my $want = {
    resource                 => 'http://localhost/mcp',
    authorization_servers    => ['https://id.test'],
    scopes_supported         => ['mcp', 'mcp:write'],
    bearer_methods_supported => ['header'],
    resource_name            => 'Acme',
    resource_documentation   => 'https://acme.test/docs',
};
for my $path ('/.well-known/oauth-protected-resource',
              '/.well-known/oauth-protected-resource/mcp') {
    $t->get_ok($path);
    is($t->status, 200, "$path is served");
    is($t->header('Content-Type'), 'application/json', 'as JSON');
    is_deeply(JSON::PP->new->decode($t->body), $want, 'with every field');
}

$t->get_ok('/.well-known/oauth-protected-resource/mcp',
           headers => { Origin => 'https://anywhere.test' });
is($t->status, 200, 'a browser on any origin may read it');
is($t->header('Access-Control-Allow-Origin'), '*', 'it is public metadata');

$t->request_ok('HEAD', '/.well-known/oauth-protected-resource/mcp');
is($t->status, 200, 'HEAD is answered');
is($t->body, '', 'with no body');

my $plain = auth_app('');
$plain->get_ok('/.well-known/oauth-protected-resource');
is($plain->status, 404, 'without oauth there is no document');

done_testing;
