#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use File::Raw::JSON qw(file_json_decode);

# before / after request hooks: auth-style short-circuit from before, header
# stamping and response replacement from after, hook error handling, hooks on
# error responses, string hook names, and the Future (->then) chain.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

sub req {
    my ($app, %o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => $o{method} || 'GET',
        PATH_INFO      => $o{path}   || '/',
        QUERY_STRING   => $o{query}  || '',
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} || {} },
    });
}
sub body_json { file_json_decode($_[0][2][0]) }

my %handlers = (
    listPets => sub { [ { id => 1, name => 'rex' } ] },
    getPet   => sub {
        my ($p, $env) = @_;
        { id => 0 + $p->{path}{petId}, name => 'rex',
          user => $env->{'openapi.user'} };
    },
);

# ---- before: auth short-circuit -------------------------------------------------
{
    my $handler_ran = 0;
    my $app = $api->to_app(
        handlers => { %handlers, listPets => sub { $handler_ran++; [] } },
        before   => sub {
            my ($env, $op_id) = @_;
            return [ 401, ['Content-Type' => 'text/plain'], ["denied:$op_id"] ]
                unless ($env->{HTTP_AUTHORIZATION} || '') eq 'Bearer ok';
            $env->{'openapi.user'} = 'alice';   # stash for the handler
            return;                              # continue
        },
    );

    my $r = req($app, path => '/pets');
    is($r->[0], 401, 'before short-circuits without auth');
    is($r->[2][0], 'denied:listPets', 'before saw the operationId');
    is($handler_ran, 0, 'handler never ran');

    $r = req($app, path => '/pets/5',
             env => { HTTP_AUTHORIZATION => 'Bearer ok' });
    is($r->[0], 200, 'authorized request continues');
    is(body_json($r)->{user}, 'alice', 'before stashed into $env for the handler');
}

# ---- before: non-reference returns continue; die is a 500 ------------------------
{
    my $app = $api->to_app(handlers => \%handlers, before => sub { 1 });
    is(req($app, path => '/pets')->[0], 200, 'non-ref before return continues');

    $app = $api->to_app(handlers => \%handlers, before => sub { die "authsplode\n" });
    my $r = req($app, path => '/pets');
    is($r->[0], 500, 'before die is a 500');
    like(body_json($r)->{errors}[0]{message}, qr/authsplode/, 'die message kept');
}

# ---- after: mutate in place / replace / ignore non-triplet ------------------------
{
    my @seen;
    my $app = $api->to_app(handlers => \%handlers, after => sub {
        my ($resp, $env, $op_id) = @_;
        push @seen, "$op_id:$resp->[0]";
        push @{ $resp->[1] }, 'X-Served-By' => 'hook';   # mutate in place
        return 1;                                        # non-triplet: ignored
    });
    my $r = req($app, path => '/pets');
    is($r->[0], 200, 'after non-triplet return keeps the response');
    my %h = @{ $r->[1] };
    is($h{'X-Served-By'}, 'hook', 'after mutated headers in place');
    is_deeply(\@seen, ['listPets:200'], 'after saw op + status');

    $app = $api->to_app(handlers => \%handlers, after => sub {
        [ 418, ['Content-Type' => 'text/plain'], ['teapot'] ];
    });
    $r = req($app, path => '/pets');
    is($r->[0], 418, 'after triplet return replaces the response');
}

# ---- after runs on op-matched errors, not on 404 -----------------------------------
{
    my @codes;
    my $app = $api->to_app(
        handlers => { %handlers, listPets => sub { die "boom\n" } },
        after    => sub { push @codes, $_[0][0]; return },
    );
    req($app, path => '/pets/abc');   # 400 validation
    req($app, path => '/pets');      # 500 handler die
    req($app, path => '/nope');      # 404 - no op, no hook
    is_deeply(\@codes, [400, 500], 'after ran on 400 and 500, not on 404');
}

# ---- string hook names + typo croak ---------------------------------------------------
{
    {
        package My::Hooks;
        sub before { return }
        sub after  { push @{ $_[0][1] }, 'X-Pkg' => 'yes'; return }
    }
    my $app = $api->to_app(handlers => \%handlers,
        before => 'My::Hooks::before', after => 'My::Hooks::after');
    my %h = @{ req($app, path => '/pets')->[1] };
    is($h{'X-Pkg'}, 'yes', 'string hook names resolve');

    my $err;
    eval { $api->to_app(handlers => \%handlers, before => 'No::Such::hook') }
        or $err = $@;
    like($err, qr/'before' hook names no such sub/, 'bad hook name croaks at to_app');
}

# ---- Future returns: hooks + response validation via the ->then chain ------------------
SKIP: {
    skip 'Fetch not installed', 5 unless eval { require Fetch; 1 };

    my $app = $api->to_app(
        handlers => { %handlers, listPets => sub {
            Fetch::Future->done_future(
                [ 200, ['Content-Type' => 'application/json'], ['[{"id":1,"name":"rex"}]'] ]);
        } },
        after => sub { push @{ $_[0][1] }, 'X-Async' => 'yes'; return },
    );
    my $f = req($app, path => '/pets', env => { 'psgi.nonblocking' => 1 });
    ok($f && ref($f) && $f->can('get'), 'nonblocking + after returns a future');
    my $r = $f->get;
    is($r->[0], 200, 'chained future resolves to the triplet');
    my %h = @{ $r->[1] };
    is($h{'X-Async'}, 'yes', 'after hook ran inside the chain');

    # response validation now applies to Future returns too
    my $lying = $api->to_app(
        validate_responses => 1,
        handlers => { %handlers, getPet => sub {
            Fetch::Future->done_future({ wrong => 'shape' });
        } },
    );
    my $vf = req($lying, path => '/pets/1', env => { 'psgi.nonblocking' => 1 });
    my $vr = $vf->get;
    is($vr->[0], 500, 'response validation catches a lying future handler');
    is(body_json($vr)->{errors}[0]{in}, 'response', 'marked in=response');
}

done_testing();
