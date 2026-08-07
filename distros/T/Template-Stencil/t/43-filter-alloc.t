#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Template::Stencil;

# Steady-state behaviour of chained built-in filters: no buffer growth
# after warmup, output stable, and an informational cost-per-op diag
# against the unfiltered baseline.

my $data = { v => ' Some Value <here> ' };

my $plain = Template::Stencil::_compile_handle('{% v %}');
my $chain = Template::Stencil::_compile_handle(
    '{% v | trim | upper | lower %}');

# warm up (profiled pre-grow + scratch growth)
Template::Stencil::_run_handle($_, $data) for ($plain) x 5, ($chain) x 5;

my $s0 = Template::Stencil::_stencil_stats();
my $out;
$out = Template::Stencil::_run_handle($chain, $data) for 1 .. 200;
my $s1 = Template::Stencil::_stencil_stats();

is($out, 'some value &lt;here&gt;', 'chained output stable');
is($s1->{buf_grows} - $s0->{buf_grows}, 0,
   'zero buffer grows at steady state with filters');
is($s1->{scratch_allocs} - $s0->{scratch_allocs}, 0,
   'zero scratch-vector allocs (no hash loops here)');

# Informational: per-op cost of one filter vs bare output.
{
    my $n = 50_000;
    my $t0 = Time::HiRes::time();
    Template::Stencil::_run_handle($plain, $data) for 1 .. $n;
    my $base = (Time::HiRes::time() - $t0) / $n;
    my $one = Template::Stencil::_compile_handle('{% v | upper %}');
    Template::Stencil::_run_handle($one, $data) for 1 .. 100;
    $t0 = Time::HiRes::time();
    Template::Stencil::_run_handle($one, $data) for 1 .. $n;
    my $filt = (Time::HiRes::time() - $t0) / $n;
    diag(sprintf 'bare: %.0f ns, upper: %.0f ns (+%.0f%%)',
         $base * 1e9, $filt * 1e9, ($filt / $base - 1) * 100);
    Template::Stencil::_free_handle($one);
}

Template::Stencil::_free_handle($plain);
Template::Stencil::_free_handle($chain);

done_testing;
