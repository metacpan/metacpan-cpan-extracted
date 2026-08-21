#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk ();

# The one-hashref route form:
#
#     post '/upload' => { cb => 'Web::File#create', max_body => 50_000_000 };
#
# instead of the positional
#
#     post '/upload' => 'Web::File#create', { max_body => 50_000_000 };
#
# Both stay. The split happens at the front door (pk_spec_split, called from
# Punk::App::route), so the router, the compiled records and everything
# downstream see exactly what they always saw. That claim is what the
# equivalence test below actually checks.

sub call {
    my ($app, %a) = @_;
    open my $in, '<', \($a{body} // '');
    my $res = $app->({
        REQUEST_METHOD => $a{method} // 'GET',
        PATH_INFO      => $a{path}   // '/',
        QUERY_STRING   => '',
        SERVER_NAME    => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
        (defined $a{len} ? (CONTENT_LENGTH => $a{len}) : ()),
    });
    my %h = ref $res->[1] eq 'ARRAY' ? @{ $res->[1] } : ();
    my $body = ref $res->[2] eq 'ARRAY' ? join('', @{ $res->[2] }) : '';
    return ($res->[0], $body, \%h);
}

# ---- EQUIVALENCE: the whole claim of the feature ---------------------------

# The same route, the same handler, the same options, two spellings. If these
# ever diverge the feature is broken in a way that a status-code test would
# not see - an option silently dropped on one path still returns 200.
{
    our $handler = sub { $_[0]->text('same') };
    my $pos = do {
        package P1; use Punk;
        post '/x' => $main::handler, { max_body => 10, compress => 0 };
        __PACKAGE__->to_app;
    };
    my $spc = do {
        package S1; use Punk;
        post '/x' => { cb => $main::handler, max_body => 10, compress => 0 };
        __PACKAGE__->to_app;
    };

    my @p = call($pos, method => 'POST', path => '/x', len => 5);
    my @s = call($spc, method => 'POST', path => '/x', len => 5);
    is_deeply [ @s[0, 1] ], [ @p[0, 1] ],
       'both spellings serve the same status and body';
    is $s[2]{'Content-Encoding'}, $p[2]{'Content-Encoding'},
       '...and carry the same compress => 0 opt-out header';

    is +(call($spc, method => 'POST', path => '/x', len => 99))[0], 413,
       'the spec form enforces max_body';
    is +(call($pos, method => 'POST', path => '/x', len => 99))[0], 413,
       '...exactly as the positional form does';
}

# ---- the ALIASING test -----------------------------------------------------

# The one that catches a mutating implementation. A spec built once and
# declared twice must give two working routes, and the caller's hashref must
# come back unmodified. An implementation that deletes `cb` passes every
# other test in this file and fails only this one.
{
    our %spec = ( cb => sub { $_[0]->text('shared') }, max_body => 10 );
    my $app = do {
        package Alias; use Punk;
        get  '/a' => \%main::spec;
        post '/b' => \%main::spec;
        __PACKAGE__->to_app;
    };
    is +(call($app, method => 'GET',  path => '/a'))[1], 'shared',
       'the first route declared from a shared spec works';
    is +(call($app, method => 'POST', path => '/b'))[1], 'shared',
       'and so does the second - the spec was not consumed';
    ok exists $spec{cb}, "the caller's hashref still has its cb";
    is scalar keys %spec, 2, '...and is otherwise unmodified';
    is +(call($app, method => 'POST', path => '/b', len => 99))[0], 413,
       'the shared options reached the second route too';
}

# ---- both target kinds -----------------------------------------------------

{
    my $app = do {
        package Kinds; use Punk;
        get '/code' => { cb => sub { $_[0]->text('coderef') } };
        get '/ctrl' => { cb => 'Thing#show' };
        __PACKAGE__->to_app;
    };
    is +(call($app, path => '/code'))[1], 'coderef', 'cb takes a coderef';
    is +(call($app, path => '/ctrl'))[1], 'from-controller',
       "cb takes 'Controller#method', resolved the same way";
}

# ---- every verb ------------------------------------------------------------

{
    my $app = do {
        package Verbs; use Punk;
        get    '/v' => { cb => sub { $_[0]->text('GET') } };
        post   '/v' => { cb => sub { $_[0]->text('POST') } };
        put    '/v' => { cb => sub { $_[0]->text('PUT') } };
        patch  '/v' => { cb => sub { $_[0]->text('PATCH') } };
        del    '/v' => { cb => sub { $_[0]->text('DELETE') } };
        any    '/w' => { cb => sub { $_[0]->text('ANY') } };
        __PACKAGE__->to_app;
    };
    is +(call($app, method => $_, path => '/v'))[1], $_, "$_ takes the spec form"
        for qw(GET POST PUT PATCH DELETE);
    is +(call($app, method => 'PUT', path => '/w'))[1], 'ANY',
       'any takes the spec form';
}

# ---- scoped verbs ----------------------------------------------------------

# These reach the same Punk::App::route, so they work "for free" - which is
# exactly why it is asserted rather than assumed.
{
    our @SEEN;
    my $app = do {
        package Scoped; use Punk;
        my $scope = under '/admin' => sub { push @main::SEEN, 'guard'; return };
        $scope->get('/panel'  => { cb => sub { $_[0]->text('panel') } });
        $scope->post('/save'  => { cb => sub { $_[0]->text('saved') },
                                   max_body => 10 });
        __PACKAGE__->to_app;
    };
    local @SEEN = ();
    is +(call($app, path => '/admin/panel'))[1], 'panel',
       'a scoped route takes the spec form';
    is_deeply \@SEEN, ['guard'], '...and still runs the scope guard';

    is +(call($app, method => 'POST', path => '/admin/save', len => 99))[0], 413,
       'a scoped spec route honours its own options';
}

# ---- websocket and sse -----------------------------------------------------

# Separate entry points with their own option sets; each got the same split.
{
    my $app = eval {
        package WsSse; use Punk;
        websocket '/ws' => { cb => sub { }, protocols => ['v1'] };
        sse       '/ev' => { cb => sub { }, heartbeat => 30 };
        __PACKAGE__->to_app;
    };
    ok $app, 'websocket and sse accept the spec form' or diag $@;
}

# ---- the croaks ------------------------------------------------------------

sub boot_fails {
    my ($body, $like, $what) = @_;
    my $pkg = 'RS' . int(rand 1e9);
    eval "package $pkg; use Punk; $body; ${pkg}->to_app; 1";
    like $@ || '', $like, $what;
}

boot_fails q{post '/x' => { max_body => 1 }},
    qr/route POST \/x has options but no `cb`/,
    'a spec with no cb croaks, naming the route';

boot_fails q{post '/x' => { cb => undef }},
    qr/has options but no `cb`/,
    'an undef cb croaks too - the shape a typo in a hash produces';

boot_fails q{post '/x' => { cb => sub {1} }, { max_body => 1 }},
    qr/either inside the hashref or after the target, not both/,
    'the mixed form croaks rather than picking a winner';

boot_fails q{post '/x' => { cb => sub {1}, max_bdy => 1 }},
    qr/unknown route option 'max_bdy'/,
    'an unknown key inside the spec still croaks, naming itself';

boot_fails q{websocket '/w' => { protocols => ['v1'] }},
    qr/websocket \/w has options but no `cb`/,
    'websocket names itself in the missing-cb croak';

boot_fails q{sse '/s' => { cb => sub {1}, bogus => 1 }},
    qr/unknown sse option\(s\) bogus/,
    'an unknown sse option still croaks';

# The bad-target message must be the SAME one the positional form gives,
# because it comes from the same resolver - not a second vocabulary.
{
    my ($spec_err, $pos_err);
    eval "package RSa; use Punk; get '/x' => { cb => 'Nope#missing' }; RSa->to_app; 1";
    $spec_err = $@ || '';
    eval "package RSb; use Punk; get '/x' => 'Nope#missing'; RSb->to_app; 1";
    $pos_err = $@ || '';
    for ($spec_err, $pos_err) { s/RS[ab]/PKG/g; s/ at .*//s }
    is $spec_err, $pos_err,
       'an unresolvable cb gives the identical croak to an unresolvable target';
    like $spec_err, qr/does not load|coderef or/,
       '...and it is the resolver saying so';
}

# ---- the positional form is untouched --------------------------------------

{
    my $app = do {
        package Still; use Punk;
        get '/plain' => sub { $_[0]->text('plain') };
        get '/opt'   => sub { $_[0]->text('opt') }, { max_body => 10 };
        __PACKAGE__->to_app;
    };
    is +(call($app, path => '/plain'))[1], 'plain',
       'a bare positional route still works';
    is +(call($app, path => '/opt'))[1], 'opt',
       'a positional route with options still works';
}

done_testing;
