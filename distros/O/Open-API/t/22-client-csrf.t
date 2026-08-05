#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;

# The client satisfies a CSRF-protected server transparently: with csrf => 1
# it presents the expected Origin, captures the token the server sets, and
# echoes it in the token header on state-changing calls - including across
# rotation. Without it, the same calls are blocked.

plan skip_all => 'Hyperman not installed' unless eval { require Hyperman; 1 };
plan skip_all => 'Fetch not installed'    unless eval { require Fetch; 1 };
require Open::API;
require Open::API::Client;

my $port = do {
    my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die $!;
    my $p = $s->sockport; close $s; $p;
};
my $ORIGIN = "http://127.0.0.1:$port";
my $SPEC   = "t/spec/petstore.json";
my $api    = Open::API->new(spec => $SPEC);

my $pid = fork // die "fork: $!";
if (!$pid) {
    $pid = 0;   # do not let this child's END reap anything
    open STDERR, '>', '/dev/null';
    my %SESS;                 # sid => current csrf token
    my ($sid_seq, $tok_seq) = (0, 0);
    my $api2 = Open::API->new(spec => $SPEC);
    my $app  = $api2->to_app(
        handlers => {
            listPets  => sub { [ 200, ['Content-Type' => 'application/json'], ['[]'] ] },
            createPet => sub { [ 201, ['Content-Type' => 'application/json'], ['{"ok":1}'] ] },
            getPet    => sub { [ 200, ['Content-Type' => 'application/json'], ['{}'] ] },
            deletePet => sub { [ 204, [], [''] ] },
        },
        csrf => {
            origins => [ $ORIGIN ],
            check   => sub {
                my ($submitted, $env) = @_;
                my ($sid) = ($env->{HTTP_COOKIE} || '') =~ /\bsid=([^;]+)/;
                return 0 unless $sid && defined $SESS{$sid};
                return 0 unless defined $submitted && $submitted eq $SESS{$sid};
                my $fresh = 'tok-' . (++$tok_seq);   # rotate on success
                $SESS{$sid} = $fresh;
                return $fresh;                       # framework sets the cookie
            },
        },
        # bootstrap: issue a session + first CSRF token on any response that
        # arrives without one (a safe GET is the usual first call)
        after => sub {
            my ($resp, $env) = @_;
            my ($sid) = ($env->{HTTP_COOKIE} || '') =~ /\bsid=([^;]+)/;
            return if $sid;
            $sid = 's' . (++$sid_seq);
            my $tok = 'tok-' . (++$tok_seq);
            $SESS{$sid} = $tok;
            push @{ $resp->[1] }, 'Set-Cookie' => "sid=$sid; Path=/";
            push @{ $resp->[1] }, 'Set-Cookie' => "csrf=$tok; Path=/; SameSite=Strict";
            return;
        },
    );
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}
END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
for (1 .. 50) {
    last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    select undef, undef, undef, 0.1;
}

# ---- with transparent CSRF ------------------------------------------------------
{
    my $c = Open::API::Client->new(spec => $SPEC, base_url => $ORIGIN,
        cookie_jar => 1, csrf => 1);

    is($c->listPets->get->{status}, 200, 'bootstrap GET (captures the token)');

    my $r = $c->createPet(body => { id => 1, name => 'rex' })->get;
    is($r->{status}, 201, 'POST authorised transparently (Origin + token sent)');

    my $r2 = $c->createPet(body => { id => 2, name => 'rex2' })->get;
    is($r2->{status}, 201, 'second POST works too (token rotation followed)');
}

# ---- without it, the same POST is blocked ---------------------------------------
{
    my $c = Open::API::Client->new(spec => $SPEC, base_url => $ORIGIN,
        cookie_jar => 1);                         # no csrf => 1
    $c->listPets->get;
    is($c->createPet(body => { id => 3, name => 'x' })->get->{status}, 403,
       'without client CSRF support the POST is rejected');
}

done_testing();
