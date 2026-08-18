#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# Single-use tokens ($c->issue_token / $c->take_token). The property that
# carries the security weight is the spend order: a token is deleted before
# its kind or expiry are examined, so a wrong-kind probe burns it. Also
# pinned: only the digest is stored, issuing again invalidates the older
# same-kind token, and both methods ride the await seam.

{
    package T::Backend::Memory;
    sub new {
        my ($class, %a) = @_;
        bless { primary => $a{primary} || 'id', rows => {}, seq => 0 }, $class;
    }
    sub get {
        my ($s, %k) = @_;
        my $r = $s->{rows}{ $k{ $s->{primary} } };
        return $r ? { %$r } : undef;
    }
    sub search {
        my ($s, $filter) = @_;
        $filter ||= {};
        my @rows = grep {
            my $r = $_;
            !grep { ($r->{$_} // '') ne $filter->{$_} } keys %$filter;
        } map { $s->{rows}{$_} } sort { $a <=> $b } keys %{ $s->{rows} };
        return { rows => [ map { +{ %$_ } } @rows ],
                 has_more_data => 0, next => undef };
    }
    sub all    { return $_[0]->search({}) }
    sub create {
        my ($s, $d) = @_;
        my $id = ++$s->{seq};
        my $row = { %$d, $s->{primary} => $id };
        $s->{rows}{$id} = $row;
        return { %$row };
    }
    sub update {
        my ($s, $d) = @_;
        my $row = $s->{rows}{ $d->{ $s->{primary} } } or return undef;
        %$row = (%$row, %$d);
        return { %$row };
    }
    sub delete {
        my ($s, %k) = @_;
        return delete $s->{rows}{ $k{ $s->{primary} } } ? 1 : 0;
    }
    sub _raw { return $_[0]->{rows} }
}

{
    package TokApp::Model::AuthToken;
    use Punk::Model;
    table 'auth_tokens';
    field id      => { type => 'integer' };
    field user_id => { type => 'integer' };
    field kind    => { type => 'string' };
    field digest  => { type => 'string' };
    field expires => { type => 'integer' };
}
{
    package TokApp;
    use Punk;
    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'AuthToken';
    auth token_model => 'AuthToken';

    post '/issue' => sub {
        my ($c) = @_;
        my $t = $c->issue_token($c->param('uid') // 1,
                                $c->param('kind') // 'verify',
                                $c->param('ttl')  // 3600);
        $c->json({ token => $t });
    };
    post '/take' => sub {
        my ($c) = @_;
        my @kinds = split /,/, ($c->param('kinds') // 'verify');
        my $row = $c->take_token($c->param('token'), @kinds);
        $c->json({ took => $row ? $row->{kind} : undef,
                   user => $row ? $row->{user_id} : undef });
    };
    get '/count' => sub {
        my ($c) = @_;
        my $all = $c->model('AuthToken')->all;
        $c->json({ n => scalar @{ $all->{rows} } });
    };
}

my $t = Punk::Test->new('TokApp');

# ---- issue and take ------------------------------------------------------------

$t->post_ok('/issue')->status_is(200);
my $tok = $t->json->{token};
is(length $tok, 43, 'the plaintext token is the 43-char url-safe form');
$t->get_ok('/count')->json_is('/n' => 1);

$t->post_ok('/take', form => { token => $tok })
  ->json_is('/took' => 'verify')
  ->json_is('/user' => 1, 'a valid take returns the row');
$t->get_ok('/count')->json_is('/n' => 0, 'and the token is gone');

$t->post_ok('/take', form => { token => $tok })
  ->json_is('/took' => undef, 'a second take of the same token fails');

# ---- a wrong-kind probe burns the token ----------------------------------------

$t->post_ok('/issue', form => { kind => 'reset' });
my $reset = $t->json->{token};
$t->post_ok('/take', form => { token => $reset, kinds => 'verify' })
  ->json_is('/took' => undef, 'the wrong kind is refused');
$t->get_ok('/count')->json_is('/n' => 0,
    'and the token was spent anyway - probing burns it');
$t->post_ok('/take', form => { token => $reset, kinds => 'reset' })
  ->json_is('/took' => undef, 'so it cannot then be used properly');

# ---- multi-kind take (the reset-or-invite endpoint) ----------------------------

$t->post_ok('/issue', form => { kind => 'invite', ttl => 3600 });
my $inv = $t->json->{token};
$t->post_ok('/take', form => { token => $inv, kinds => 'reset,invite' })
  ->json_is('/took' => 'invite', 'a multi-kind take accepts either');

# ---- expiry --------------------------------------------------------------------

$t->post_ok('/issue', form => { kind => 'verify', ttl => 1 });
my $stale = $t->json->{token};
sleep 2;
$t->post_ok('/take', form => { token => $stale })
  ->json_is('/took' => undef, 'an expired token fails');
$t->get_ok('/count')->json_is('/n' => 0, 'and was deleted in passing');

# ---- issuing again invalidates the older same-kind token -----------------------

$t->post_ok('/issue', form => { kind => 'verify' });
my $first = $t->json->{token};
$t->post_ok('/issue', form => { kind => 'verify' });
my $second = $t->json->{token};
$t->get_ok('/count')->json_is('/n' => 1,
    're-issuing leaves exactly one live token of the kind');
$t->post_ok('/take', form => { token => $first })
  ->json_is('/took' => undef, 'the older link is dead');
$t->post_ok('/take', form => { token => $second })
  ->json_is('/took' => 'verify', 'the newest one works');

# ---- a different kind survives a re-issue --------------------------------------

$t->post_ok('/issue', form => { kind => 'verify' });
$t->post_ok('/issue', form => { kind => 'reset' });
$t->get_ok('/count')->json_is('/n' => 2,
    'kinds are independent: a reset does not kill a verify');

# ---- storage holds digests only ------------------------------------------------

{
    $t->post_ok('/issue', form => { kind => 'verify' });
    my $plain = $t->json->{token};
    my ($backend_rows) = do {
        no warnings 'once';
        # reach into the worker-cached instance through the app registry
        my $app = TokApp::punk_app();
        my $m = $app->model_instance('AuthToken');
        $m->backend->_raw;
    };
    my @digests = map { $_->{digest} } values %$backend_rows;
    ok(!(grep { $_ eq $plain } @digests),
        'the plaintext token never reaches storage');
    ok((grep { $_ eq Punk::Auth::Password::token_digest($plain) } @digests),
        'its sha256 digest is what the table holds');
}

# ---- misuse croaks -------------------------------------------------------------

{
    package NoTok;
    use Punk;
    session secret => 'k';
    auth session_key => 'user_id';
    post '/i' => sub { $_[0]->issue_token(1, 'verify', 60) };
    package main;
    my $n = Punk::Test->new('NoTok');
    $n->post_ok('/i')->status_is(500)
      ->content_like(qr/token_model/, 'issue without token_model names the fix');
}

done_testing;
