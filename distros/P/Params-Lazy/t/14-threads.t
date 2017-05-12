use strict;
use warnings;

use Config;
# Test::More needs threads pre-loaded to work properly.
use if $Config{useithreads}, 'threads';
use Test::More;

BEGIN {
    if (! $Config{'useithreads'}) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
}

use Params::Lazy delay => q(^), delay_thr => q(^);
sub delay {
    my $f       = shift;
    my $against = [ [(11) x 5], [11..15], [11..15] ];
    my @thrs    = map { async { force $f } } 1..5;
    my @results = map { $_->join() } @thrs;
    use Data::Dumper;
    is_deeply(\@results, $against->[0], "can delay an argument force it in a different thread") or diag(Dumper(\@results));
    
    my ($thr) = threads->create(sub { map { my $x = force $f; $x } 1..5 });
    @results = $thr->join();
    is_deeply(\@results, $against->[1], "can force an argument multiple times in a thread");
    
    my ($thr2)  = threads->create(sub { map { force $f } 1..5 });
    @results    = $thr2->join();
    is_deeply(\@results, $against->[2], "async { map { force \$f } 1..5 } doesn't return the same temp");
}
sub delay_thr {
    my $f = shift;
    
    my $thr1   = force $f; # Force scalar context
    my ($thr2) = force $f; # Force list context
    
    my $r = join "|", map { $_->join() } $thr1, $thr2;
    is($r, "delayed: 10|delayed: 10", "can delay thread creation");
}

my $foo = 10;
delay ++$foo;
is($foo, 10, "the original \$foo does not change");

use Params::Lazy run_delayed_in_thread => q(^);
sub run_delayed_in_thread {
    my $d = shift;
    return threads->create(sub { force $d })->join();
}

my $ret;

$foo = "foo";
$ret = run_delayed_in_thread $foo .= 10;
is($ret, 'foo10', 'run_delayed_in_thread $foo .= 10');
is($foo, "foo", "foo hasn't changed");

sub Foo::bar { "I am foobar" }
is(
    run_delayed_in_thread(Foo->bar()),
    "I am foobar",
    "method named works"
);

BEGIN {
    SKIP: {
        skip('BEGIN {delay %^H} works but attempts to free scalars prematurely', 1);
        $^H{foobar} = "also foobar";
        my $ret = run_delayed_in_thread $^H{foobar};
        is($ret,"also foobar", "delaying access to the hints hash works");
    }
}

$ret = sub {
    run_delayed_in_thread $foo .= 10;
}->();
is($ret, 'foo10', 'sub {run_delayed_in_thread $foo .= 10}->()');
is($foo, "foo", "foo hasn't changed");

sub {
    my $foo = "foo";
    my $ret = run_delayed_in_thread $foo .= 10;
    is($ret, 'foo10', 'run_delayed_in_thread $foo .= 10');
    is($foo, "foo", "foo hasn't changed");
}->();

$ret = sub {
    run_delayed_in_thread $foo .= $_[0];
}->(10);
is($ret, 'foo10', 'sub { run_delayed_in_thread $foo .= 10 }');

sub {
    my $fus = 10;

    my $sub = sub { "delayed: $fus" };

    delay_thr(threads->create($sub));
    delay_thr async { "delayed: $fus" };
    
}->("not grabbing anything from the stack");

# Same tests than in t/03-Lazy.t, but duplicated here to check
# that if combined with threading the program doesn't crash
use Params::Lazy delay_cr => q(^);
sub delay_cr { return force shift }

my $fus = 10;
my $fus_sub = delay_cr sub { "fus: $fus" };
is(
    $fus_sub->(),
   "fus: 10",
   "can delay coderef creation outside of a sub"
);

my $fus_const_sub = delay_cr sub () { $fus };
is(
    $fus_const_sub->(),
   10,
   "can delay a constant coderef creation outside of a sub"
);
    
SKIP: {
    skip("Crashes in 5.8", 2) if $] < 5.010;

sub {
    my $fus_sub = delay_cr sub { "fus: $fus" };
    is(
        $fus_sub->(),
        "fus: 10",
        "can delay coderef creation inside a sub"
    );

    my $fus_const_sub = delay_cr sub () { $fus };
    is(
        $fus_const_sub->(),
        10,
        "can delay a constant coderef creation inside a sub"
    );

}->();
}

my $sub = sub { "delayed: $fus" };
delay_thr(threads->create($sub));
delay_thr async { "delayed: 10" };

sub delay_at {
    my @orig     = @_;
    @_ = 11..15;
    
    delay shift @_;
    is_deeply(\@_, [11..15], "\@_ + threads doesn't modify the caller's \@_");
}

sub delay_local_at {
    my @orig     = @_;
    my @new_args = 11..15;
    local *_     = \@new_args;
    
    delay shift @_;
    is_deeply(\@_, [11..15], "local \@_ + threads doesn't modify the caller's \@_");
}

delay_at("orig1", "orig2");
delay_local_at("orig1", "orig2");

done_testing;
