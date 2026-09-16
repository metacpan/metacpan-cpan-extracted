#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
    plan skip_all => 'DBI and DBD::SQLite required for the DBI-backed store'
        unless eval { require DBI; require DBD::SQLite; 1 };
}
use POTest;
use Crypt::JWS qw(b64url random_bytes sha256);
use Punk::OAuth2::Server::Store;

# A hook may return a RESPONSE instead of an answer, and both hooks say so:
# authenticate returns a redirect to your login page, consent returns your
# consent screen. Until now nothing exercised either - every test in this
# distribution returns a plain string from authenticate and configures no
# consent hook at all - and the consent branch returned its response already
# mortalised while the XSUB's RETVAL mortalised it again.
#
# That is not a wrong status or a missing header. One owned reference with
# two scheduled decrements is a response freed while the caller still holds
# it, and the process dies later in the host application's cleanup, on a
# poisoned pointer, with no frame belonging to this distribution in the
# stack. It took a real application rendering a real consent page to find
# it.
#
# So these tests are about liveness as much as output: with the fault
# present this file does not fail, it SEGVs before its plan.

my $dbfile = "/tmp/pox-hookref-$$.db";
unlink $dbfile;
my $store = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$dbfile");
END { unlink $dbfile if $dbfile }

$store->client_put({
    client_id     => 'webapp',
    secret        => 'topsecret',
    redirect_uris => ['https://app.test/cb'],
    scopes        => 'read',
});

sub authorize_url {
    my $verifier  = b64url(random_bytes(32));
    my $challenge = b64url(sha256($verifier));
    return "/oauth/authorize?response_type=code&client_id=webapp"
         . "&redirect_uri=https%3A%2F%2Fapp.test%2Fcb&scope=read&state=xyz"
         . "&code_challenge=$challenge&code_challenge_method=S256";
}

# ---- consent returns a response --------------------------------------------

{
    package ConsentApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.test',
        store        => $store,
        authenticate => sub { 'user-42' },
        consent      => sub {
            return [200, ['Content-Type' => 'text/plain'], ['CONSENT PAGE']];
        },
    };
}
my $capp = ConsentApp->to_app;

{
    my ($status, undef, $body) = POTest::hit($capp, GET => authorize_url());
    is $status, 200, 'a consent hook may answer with a response';
    is $body, 'CONSENT PAGE', '...and it is returned unchanged';
}

# Repeatedly, because an over-free is a use-after-free: the first response
# may well look right and the damage surface on a later one.
{
    my $intact = 0;
    for (1 .. 25) {
        my ($s, undef, $b) = POTest::hit($capp, GET => authorize_url());
        $intact++ if defined $s && $s == 200 && defined $b
                  && $b eq 'CONSENT PAGE';
    }
    is $intact, 25, 'twenty-five of them, all intact - the response is not '
                  . 'freed from under the caller';
}

# ---- authenticate returns a response ---------------------------------------

{
    package LoginApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.test',
        store        => $store,
        authenticate => sub {
            return [302, ['Location' => '/login'], ['']];
        },
    };
}
my $lapp = LoginApp->to_app;

{
    my ($status, $headers) = POTest::hit($lapp, GET => authorize_url());
    is $status, 302, 'an authenticate hook may answer with a redirect';
    is +($headers->{location} // ''), '/login',
       '...to the application login page';

    my $intact = 0;
    for (1 .. 25) {
        my ($s) = POTest::hit($lapp, GET => authorize_url());
        $intact++ if defined $s && $s == 302;
    }
    is $intact, 25, 'twenty-five of those too';
}

done_testing;
