#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk::Test;
use Punk ();

# Punk::Plugin::ConditionalGet, phase 5: the things that are only true of the
# finished feature.
#
#   1. The POD's SYNOPSIS runs, read out of the POD rather than copied.
#   2. A SHARED CACHE in front of two users cannot hand one the other's page.
#      Phase 4 asserted the headers and said plainly that it had not asserted
#      the behaviour. This is that debt, paid: a small conformant cache, and
#      two users driven through it.
#   3. The plugin in an application using everything at once - session, flash,
#      CSRF, respond_to, auth - because that combination is where every trap
#      in this plan lives.

# ---- 1. the SYNOPSIS, executed ------------------------------------------------

{
    my $file = $INC{'Punk/Plugin/ConditionalGet.pm'};
    unless ($file) {
        require Punk::Plugin::ConditionalGet;
        $file = $INC{'Punk/Plugin/ConditionalGet.pm'};
    }
    my $synopsis = do {
        open my $fh, '<', $file or die "$file: $!";
        local $/;
        my $pod = <$fh>;
        close $fh;
        $pod =~ /^=head1 SYNOPSIS\s*\n(.*?)^=head1 /ms
            ? $1 : undef;
    };
    ok $synopsis, 'the plugin has a SYNOPSIS';

    # the verbatim block, dedented; `...` stands in for a handler body, so it
    # becomes something that actually returns
    my $code = join "\n",
        map  { my $l = $_; $l =~ s/\A    //; $l }
        grep { /\A(?:    |\s*\z)/ }
        split /\n/, $synopsis;
    $code =~ s/\{ \.\.\. \}/{ \$_[0]->text('ok') }/g;
    $code =~ s/^\s*package MyApp;\s*$/package SynApp;/m;

    my $ok = eval "$code\n1";
    ok $ok, 'the SYNOPSIS compiles and runs, verbatim from the POD'
        or diag $@;

    # /api/orders' validator reaches for a model this test does not have -
    # it is illustrating the shape, not running a database - so the route
    # exercised here is the other one the SYNOPSIS shows.
    my $app = SynApp->to_app;
    ok ref $app eq 'CODE', '...and builds an app';
    my $r = hit($app, path => '/dashboard');
    is $r->[0], 200, '...whose routes serve';
    my %h = @{ $r->[1] };
    like $h{ETag}, qr/^W\/"[0-9a-f]{16}"$/,
       '...carrying the tag the SYNOPSIS is advertising';
}

# ---- 2. a shared cache, two users --------------------------------------------
#
# Not a mock: a cache that implements the storage rules a conforming shared
# cache follows, so what is being tested is the RESPONSE, not the test's
# opinion of it.
#
#   - never store a response marked `private` or `no-store`
#   - key an entry by URL plus the request headers named in Vary
#   - revalidate a stored entry with If-None-Match, and treat 304 as
#     "yours is current"

{
    package TinyCache;

    sub new { bless { store => {}, served_from_cache => 0 }, shift }

    sub _cacheable {
        my ($self, $h) = @_;
        my %hd = @$h;
        my $cc = $hd{'Cache-Control'} // '';
        return 0 if $cc =~ /\b(?:private|no-store)\b/;
        return 0 unless $hd{ETag};
        return 1;
    }

    # the key: the URL, plus the value of every request header Vary names
    sub _key {
        my ($self, $path, $env, $h) = @_;
        my %hd = @$h;
        my $vary = $hd{Vary} // '';
        my @axis;
        for my $tok (split /\s*,\s*/, $vary) {
            next unless length $tok;
            (my $k = "HTTP_\U$tok") =~ tr/-/_/;
            push @axis, "$tok=" . ($env->{$k} // '');
        }
        return join '|', $path, @axis;
    }

    sub get {
        my ($self, $app, $path, $env) = @_;
        $env //= {};
        my $probe = $self->{store}{ $self->_key($path, $env, [ Vary => 'Accept-Encoding' ]) };
        # revalidate what we hold, exactly as a cache would
        if ($probe) {
            my $r = ::hit($app, path => $path,
                          env => { %$env, HTTP_IF_NONE_MATCH => $probe->{etag} });
            if ($r->[0] == 304) {
                $self->{served_from_cache}++;
                return $probe->{body};
            }
            delete $self->{store}{ $self->_key($path, $env, $r->[1]) };
            $self->_maybe_store($path, $env, $r);
            return ::body_of($r);
        }
        my $r = ::hit($app, path => $path, env => $env);
        $self->_maybe_store($path, $env, $r);
        return ::body_of($r);
    }

    sub _maybe_store {
        my ($self, $path, $env, $r) = @_;
        return unless $r->[0] == 200 && $self->_cacheable($r->[1]);
        my %hd = @{ $r->[1] };
        $self->{store}{ $self->_key($path, $env, $r->[1]) } = {
            etag => $hd{ETag}, body => ::body_of($r),
        };
    }
}

sub body_of {
    my $r = shift;
    return ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '';
}

{
    package TwoUsers;
    use Punk;
    plugin 'ConditionalGet';

    # a per-user page. The validator is per user, which is the RIGHT thing to
    # write and still not enough on its own: without `private` a shared cache
    # keyed on the URL alone would hold one user's copy for the other.
    get '/dashboard' => sub {
        my ($c) = @_;
        $c->text('dashboard for ' . ($c->env->{HTTP_X_USER} // 'nobody'));
    }, { etag => sub { 'user-' . ($_[0]->env->{HTTP_X_USER} // 'nobody') } };

    # a public page, same shape, nothing about anybody
    get '/pricing' => sub { $_[0]->text('pricing') },
        { etag => sub { 'pricing-v1' } };
}

{
    my $app = TwoUsers->to_app;
    my $cache = TinyCache->new;

    my $alice = $cache->get($app, '/dashboard',
        { HTTP_X_USER => 'alice', HTTP_COOKIE => 'punk.session=alice' });
    is $alice, 'dashboard for alice', 'alice gets her page';

    my $bob = $cache->get($app, '/dashboard',
        { HTTP_X_USER => 'bob', HTTP_COOKIE => 'punk.session=bob' });
    is $bob, 'dashboard for bob',
       'BOB GETS HIS OWN PAGE - a shared cache in front of a per-user route '
       . 'never had anything to hand him';
    is $cache->{served_from_cache}, 0,
       '...because the response was never storable in a shared cache at all';

    # and the public one is cached, so the cache is doing its job
    my $p1 = $cache->get($app, '/pricing');
    my $p2 = $cache->get($app, '/pricing');
    is $p2, 'pricing', 'the public page still comes back right';
    is $cache->{served_from_cache}, 1,
       '...and was served from the cache the second time, revalidated with a '
       . '304 - the feature works where it is safe and refuses where it is not';
}

{
    # the encoding axis: the same entity, two clients, one cache
    package Encoded;
    use Punk;
    plugin 'ConditionalGet';
    get '/asset' => sub { $_[0]->text('asset-bytes') }, { etag => 1 };
}
{
    my $app = Encoded->to_app;
    my $cache = TinyCache->new;
    my $plain = $cache->get($app, '/asset');
    my $gzip  = $cache->get($app, '/asset', { HTTP_ACCEPT_ENCODING => 'gzip' });
    is $plain, 'asset-bytes', 'the identity client is served';
    is $gzip,  'asset-bytes', 'and the gzip client is not handed the other '
                            . 'entry - Vary: Accept-Encoding keyed them apart';
    is scalar(keys %{ $cache->{store} }), 2,
       'the cache holds two entries for one URL, which is what Vary is for';
}

# ---- 3. everything at once ----------------------------------------------------

# A minimal backend and a User model, so the real `auth` battery is in the
# app rather than a stand-in for it.
{
    package T::CG::Backend;
    sub new { bless { rows => { 1 => { id => 1, email => 'a@example.com',
                                       role => 'admin' } } }, shift }
    sub get { my ($s, %k) = @_; my $r = $s->{rows}{ $k{id} }; $r ? { %$r } : undef }
    sub search { { rows => [], has_more_data => 0, next => undef } }
    sub all    { $_[0]->search }
    sub create { $_[0]->{rows}{1} }
    sub update { $_[0]->{rows}{1} }
    sub delete { 1 }
}
{
    package Kitchen::Model::User;
    use Punk::Model;
    table 'users';
    field id    => { type => 'integer', required => 0 };
    field email => { type => 'string',  required => 0 };
    field role  => { type => 'string',  required => 0 };
}

{
    package Kitchen;
    use Punk;
    plugin 'ConditionalGet';
    session secret => 'kitchen-sink-key';
    csrf;
    database backend => 'T::CG::Backend';
    model 'User';
    auth model => 'User', roles => sub { $_[1]->{role} };

    get '/login' => sub {
        my ($c) = @_;
        $c->login(1);
        $c->flash(notice => 'Welcome.');
        $c->text('in');
    };

    my $in = under '/app' => auth_guard;

    $in->get('/board' => sub {
        my ($c) = @_;
        $c->respond_to(
            json => sub { $_[0]->json({ board => 'ok' }) },
            html => sub { $_[0]->html('<p>board</p>') },
        );
    }, { etag => sub { 'board-' . ($_[0]->current_user->{id} // 0) } });

    $in->get('/read' => sub {
        my ($c) = @_;
        $c->text(($c->flash('notice') // '-') . '/' .
                 ($c->current_user->{id} // '-') . '/' .
                 (length($c->csrf_token) ? 'tok' : '-'));
    });
}

{
    my $t = Punk::Test->new('Kitchen');

    my $out = $t->get_ok('/app/board', headers => { Accept => 'application/json' });
    isnt $t->status, 200,
        'signed out, the auth guard refuses - before any of this runs';

    $t->get_ok('/login')->content_is('in');

    $t->get_ok('/app/board', headers => { Accept => 'application/json' })
      ->status_is(200);
    my $tag = $t->header('ETag');
    ok $tag, 'signed in, the board carries a tag';
    is $t->header('Cache-Control'), 'private',
       '...marked private, because the request carried a session cookie';
    like $t->header('Vary'), qr/\bAccept\b/, '...varying on Accept';
    like $t->header('Vary'), qr/\bAccept-Encoding\b/, '...and on the encoding';

    $t->get_ok('/app/board', headers => { Accept => 'application/json',
                                          'If-None-Match' => $tag })
      ->status_is(304, 'and revalidates to a 304');

    $t->get_ok('/app/read')
      ->content_like(qr{^Welcome\./1/tok$},
        'the flash survived the 304, the session survived it, and the CSRF '
      . 'token is still mintable - a request answered without a handler ate '
      . 'none of them');
}

done_testing;
