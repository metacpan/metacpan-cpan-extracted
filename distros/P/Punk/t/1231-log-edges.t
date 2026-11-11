#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest qw(hit);

# The logger's edges: a level given as a number, clamped at both ends, a
# level name that is not one, a logger method on something that is not a
# logger, a record whose nested values carry control characters and are
# scrubbed, a key that would break a logfmt line, and a value holding a
# backslash.

my @lines;
my $sink = sub { push @lines, @_ };
my $n = 0;
sub app_with {
    my ($level) = @_;
    my $pkg = 'LG' . ++$n;
    my $lvl = defined $level ? "level => $level," : '';
    eval "package $pkg; use Punk; logging $lvl to => \$main::SINK; get '/' => sub { \$_[0]->log->debug('d'); \$_[0]->log->info('i'); \$_[0]->log->warn('w'); \$_[0]->log->error('e'); \$_[0]->log->fatal('f'); \$_[0]->text('ok') }; get '/rec' => sub { \$_[0]->log->warn({ message => 'rec', 'bad key' => 1, 'q\"uote' => 2, back => 'a\\\\b', nest => [ \"x\\x01y\", { deep => \"z\\x1bq\" } ] }); \$_[0]->text('ok') }; $pkg->to_app" or die $@;
}
our $SINK = $sink;
sub levels_logged {
    my ($app) = @_;
    @lines = ();
    hit($app, path => '/');
    return join ',', map { /\[(\w+)\]/ ? $1 : '?' } @lines;
}
is(levels_logged(app_with(q{'warn'})), 'warn,error,fatal', 'a level name sets the threshold');
is(levels_logged(app_with(3)), 'error,fatal', 'a level number does too');
is(levels_logged(app_with(99)), 'fatal', 'a number past the top is the top');
is(levels_logged(app_with(-5)), 'debug,info,warn,error,fatal', 'and one below the bottom is the bottom');
is(levels_logged(app_with(q{'bogus'})), 'info,warn,error,fatal', 'a name that is not a level is info');
is(levels_logged(app_with(undef)), 'info,warn,error,fatal', 'as is no level at all');

{
    my $app = app_with(q{'debug'});
    @lines = ();
    hit($app, path => '/rec');
    my ($line) = grep { /rec/ } @lines;
    ok($line, 'a record logs one line') or diag join '', @lines;
    like($line, qr/bad_key=1/, 'a key with a space is written with an underscore');
    like($line, qr/q_uote=2/, 'and so is one with a quote');
    like($line, qr/back="a\\\\b"/, 'a backslash in a value is escaped');
    unlike($line, qr/[\x01\x1b]/, 'control characters nested in the record do not reach the line');
    like($line, qr/\\x01|\\u0001/, 'they are written out instead');
}
{
    my $e = '';
    eval { Punk::Logger::info('not a logger', 'x'); 1 } or $e = $@;
    like($e, qr/Punk::Logger: not a logger/, 'a logger method on a string is refused');
}

done_testing;
