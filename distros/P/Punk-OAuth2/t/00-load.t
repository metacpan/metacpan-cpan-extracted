#!perl
use 5.024;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Punk::OAuth2')           || print "Bail out!\n";
    use_ok('Punk::OAuth2::Util')     || print "Bail out!\n";
    use_ok('Punk::OAuth2::Tokens')   || print "Bail out!\n";
    use_ok('Punk::OAuth2::Presets')  || print "Bail out!\n";
    use_ok('Punk::OAuth2::JWKS')     || print "Bail out!\n";
    use_ok('Punk::OAuth2::Provider') || print "Bail out!\n";
    require_ok('Punk::Plugin::OAuth2');
}

# the XS core loaded and is callable
ok defined &Punk::OAuth2::_mint_flow, 'XS _mint_flow present';
my $flow = Punk::OAuth2::_mint_flow();
is ref $flow, 'HASH', 'mint_flow returns a hashref';
like $flow->{state}, qr/\A[A-Za-z0-9_-]{43}\z/, '256-bit state';
like $flow->{challenge}, qr/\A[A-Za-z0-9_-]{43}\z/, 'S256 challenge';
isnt $flow->{state}, Punk::OAuth2::_mint_flow()->{state}, 'states vary';

# the S256 challenge is really b64url(sha256(verifier))
{
    require Crypt::JWS;
    my $expect = Crypt::JWS::b64url(Crypt::JWS::sha256($flow->{verifier}));
    is $flow->{challenge}, $expect, 'challenge = b64url(sha256(verifier))';
}

is Punk::OAuth2::uri_escape('a b/c'), 'a%20b%2Fc', 'uri_escape (XS)';
is Punk::OAuth2::_form({ b => 2, a => 1 }), 'a=1&b=2', 'form sorted (XS)';
ok Punk::OAuth2::ct_eq('x', 'x'), 'ct_eq (XS)';
ok !Punk::OAuth2::ct_eq('x', 'y'), 'ct_eq differ';
# the open-redirect guard: what it must let through, and what it must not
{
    for my $ok ('/', '/ok', '/a/b?x=1&y=2#frag', '/a%5Cb', '/sp ace',
                "/caf\xc3\xa9") {
        is Punk::OAuth2::same_origin_path($ok), $ok,
            "same_origin accepts '$ok'";
    }

    # CVE-2026-75628: a browser removes TAB/CR/LF from a URL before it
    # parses it, and folds '\' to '/' under a special scheme, so each of
    # these resolves to another host despite not starting with "//".
    my %evil = (
        'protocol-relative' => '//evil.example',
        'backslash'         => '/\\evil.example',
        'backslash-slash'   => '/\\/evil.example',
        'slash-backslash'   => '//\\evil.example',
        'deep backslash'    => '/ok/\\/evil.example',
        'tab'               => "/\t/evil.example",
        'tab first'         => "/\t\\evil.example",
        'CR'                => "/\r/evil.example",
        'LF'                => "/\n/evil.example",
        'CRLF header'       => "/ok\r\nLocation: //evil.example",
        'NUL'               => "/\0//evil.example",
        'vertical tab'      => "/\x0b//evil.example",
        'form feed'         => "/\x0c//evil.example",
        'DEL'               => "/\x7f//evil.example",
        'absolute'          => 'https://evil.example/',
        'scheme'            => 'javascript:alert(1)',
        'bare'              => 'evil.example',
        'empty'             => '',
        'undef'             => undef,
    );
    for my $why (sort keys %evil) {
        is Punk::OAuth2::same_origin_path($evil{$why}), undef,
            "same_origin rejects $why";
    }
}

diag("Testing Punk::OAuth2 $Punk::OAuth2::VERSION, "
   . "Crypt::JWS $Crypt::JWS::VERSION, Perl $], $^X");
done_testing();
