#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Test;

# The session keyword's edges: every duration unit, a store named 'cache',
# a store that is neither a name nor a hashref, and a session with no secret,
# which is written nowhere and says so.

my $n = 0;
sub compiles {
    my ($body) = @_;
    my $pkg = 'SE' . ++$n;
    my $e = '';
    eval "package $pkg; use Punk; $body; get '/' => sub { \$_[0]->session->{x} = 1; \$_[0]->text('ok') }; 1" or $e = $@;
    eval { $pkg->to_app; 1 } or $e ||= $@ if !$e && $body =~ /store/;
    return ($e, $pkg);
}
for my $d ([ '90s' => 90 ], [ '30m' => 1800 ], [ '2h' => 7200 ], [ '7d' => 604800 ], [ '1w' => 604800 ], [ '3600' => 3600 ]) {
    my ($spelling, $secs) = @$d;
    my ($e, $pkg) = compiles("session secret => 'k', expires => '$spelling'");
    is($e, '', "expires => '$spelling' is accepted");
    my $t = Punk::Test->new($pkg);
    $t->get_ok('/')->status_is(200);
    my $cookie = $t->header('Set-Cookie') // '';
    like($cookie, qr/Max-Age=\Q$secs\E\b/, "and means $secs seconds") if $cookie =~ /Max-Age=/;
}
{
    my ($e) = compiles("session secret => 'k', store => 'cache'");
    like($e, qr/`session store => 'cache'` needs a store to point at, and this application declares none/, 'a store named cache with no cache keyword is refused');
    my $cdir = File::Temp::tempdir(CLEANUP => 1);
    ($e) = compiles("cache pages => { backend => 'file', dir => '$cdir', max_bytes => '1M' }; session secret => 'k', store => 'cache'");
    like($e, qr/`session store => 'cache'` is the default store, and this application declares only named ones/, 'the default store when only named ones exist');
    ($e) = compiles("cache cache => { backend => 'file', dir => '$cdir', max_bytes => '1M' }; session secret => 'k', store => 'cache'");
    like($e, qr/`session store => 'cache'` is the DEFAULT store, but this application also declares one named `cache`/, 'a store that is itself named cache is an ambiguity');
    ($e) = compiles("session secret => 'k', store => []");
    like($e, qr/`session store` takes the name of a store, a hashref/, 'a store that is neither a name nor a hashref is refused');
}
{
    my ($e) = compiles("session expires => '1h'");
    like($e, qr/`session` needs a non-empty secret/, 'a session without a secret is refused at the keyword');
}

done_testing;
