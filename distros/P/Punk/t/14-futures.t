#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Scalar::Util ();
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# A handler may return a Future: on psgi.nonblocking servers the app
# returns a chained Future resolving to a finalized triplet (the server
# awaits it); on blocking servers it is awaited inline.

plan skip_all => 'Future required for these tests'
    unless eval { require Future; 1 };

{
    package FutureApp;
    use Punk;
    hook after_dispatch => sub {
        my ($c, $resp) = @_;
        push @{ $resp->[1] }, 'X-After' => 1;
        return;
    };
    get '/later' => sub { Future->done({ later => 1 }) };
    get '/later-triplet' => sub {
        Future->done([ 202, ['Content-Type' => 'text/plain',
                             'Content-Length' => 4], ['soon'] ]);
    };
    get '/later-fail' => sub { Future->fail("bad news\n") };
    package main;
}

my $app = FutureApp->to_app;

# ---- blocking server: awaited inline ----------------------------------------
{
    my $r = hit($app, path => '/later');
    is(ref $r, 'ARRAY', 'blocking: a plain triplet comes back');
    is(file_json_decode($r->[2][0])->{later}, 1, 'resolved data JSONified');
}

# ---- nonblocking: a Future comes back ---------------------------------------
{
    my $f = hit($app, path => '/later', env => { 'psgi.nonblocking' => 1 });
    ok(Scalar::Util::blessed($f) && $f->can('get'), 'nonblocking: a Future');
    my $r = $f->get;
    is($r->[0], 200, 'resolves to a finalized triplet');
    is(file_json_decode($r->[2][0])->{later}, 1, 'with the JSON body');
    my %h = @{ $r->[1] };
    is($h{'X-After'}, 1, 'after_dispatch ran on resolution');
}
{
    my $f = hit($app, path => '/later-triplet',
        env => { 'psgi.nonblocking' => 1 });
    is($f->get->[0], 202, 'a Future of a triplet passes through');
}
{
    my $f = hit($app, path => '/later-fail',
        env => { 'psgi.nonblocking' => 1 });
    my $r = $f->get;
    is($r->[0], 500, 'a failed Future is a 500');
    like($r->[2][0], qr/bad news/, 'carrying the failure message');
}
{
    my $r = hit($app, path => '/later-fail');
    is($r->[0], 500, 'blocking: a failed Future is a 500 too');
}

# ---- HEAD on a Future route --------------------------------------------------
{
    my $f = hit($app, method => 'HEAD', path => '/later',
        env => { 'psgi.nonblocking' => 1 });
    is($f->get->[2][0], '', 'HEAD strip applies after resolution');
}


# ---- the contract, pinned regardless of the installed Future ---------------
#
# A `then` callback must hand back a FUTURE, not the value it computed.
# Older Future releases enforce that strictly; the one on this box no longer
# does, which is exactly why Punk 0.16 passed here and failed on CPAN
# Testers with "Expected __ANON__(Future.pm line 1140) to return a Future"
# on perls 5.20, 5.22 and 5.24.
#
# StrictFuture reinstates the check locally, so this test fails if the
# wrapping is ever lost again - on any Future version.
{
    package StrictFuture;
    our @ISA = ('Future');
    sub then {
        my ($self, @cbs) = @_;
        my @checked = map {
            my $cb = $_;
            ref $cb eq 'CODE' ? sub {
                my $f = $cb->(@_);
                die "Expected callback to return a Future, got "
                  . (Scalar::Util::blessed($f) || ref($f) || 'a plain value')
                  . "\n"
                    unless Scalar::Util::blessed($f) && $f->isa('Future');
                return $f;
            } : $cb;
        } @cbs;
        return $self->SUPER::then(@checked);
    }
    package main;
}

{
    package StrictApp;
    use Punk;
    get '/ok'   => sub { StrictFuture->done({ strict => 1 }) };
    get '/fail' => sub { StrictFuture->fail("nope\n") };
    package main;
}
{
    my $app = StrictApp->to_app;

    my $f = hit($app, path => '/ok', env => { 'psgi.nonblocking' => 1 });
    my $r = eval { $f->get };
    is($@, '', 'the done callback returns a Future, as `then` requires')
        or diag "died: $@";
    is($r->[0], 200, '...and the response still resolves');
    is(file_json_decode($r->[2][0])->{strict}, 1, '...with its body');

    my $ff = hit($app, path => '/fail', env => { 'psgi.nonblocking' => 1 });
    my $rr = eval { $ff->get };
    is($@, '', 'the fail callback returns a Future too');
    is($rr->[0], 500, '...answering 500 for the failed future');
}


done_testing;
