#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

# The zero-allocation contract at steady state, asserted through the
# deterministic slow-path counters: no buffer grows and no scratch
# vectors once a template's profile is warm, for each render shape.

my $dir = File::Temp::tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/inc.tmpl" or die $!;
print $fh 'I:{% v %}';
close $fh;
open $fh, '>', "$dir/wrap.tmpl" or die $!;
print $fh '[{% content %}]';
close $fh;

my $s = Template::Stencil->new(
    template_dir => $dir,
    stat_ttl     => -1,
    filters      => { f => sub { $_[0] } },
);

my %shapes = (
    'plain output'   => [ '{% v %} and {% w.x %} text', {} ],
    'array loop'     => [ '{% for i in l %}<li>{% i %}</li>{% end %}', {} ],
    'if/set/expr'    => [ '{% set a = v %}{% if a eq "V" && n > 1 %}{% a %}{% end %}', {} ],
    'builtin filters'=> [ '{% v | trim | upper | lower %}{% w.x | default("d") %}', {} ],
    'include'        => [ 'X {% include inc.tmpl %} Y', {} ],
    'wrapper'        => [ '{% v %}', { wrapper => 'wrap.tmpl' } ],
);

my %data = (
    v => 'V', n => 2, w => { x => 'W' },
    l => [ map "item$_", 1 .. 20 ],
);

for my $name (sort keys %shapes) {
    my ($tmpl, $opts) = @{ $shapes{$name} };
    $s->render($tmpl, \%data, $opts) for 1 .. 3;   # warm profile
    my $s0 = Template::Stencil::_stencil_stats();
    $s->render($tmpl, \%data, $opts) for 1 .. 100;
    my $s1 = Template::Stencil::_stencil_stats();
    is($s1->{buf_grows} - $s0->{buf_grows}, 0,
       "$name: zero buffer grows");
    is($s1->{scratch_allocs} - $s0->{scratch_allocs}, 0,
       "$name: zero scratch allocs");
    is($s1->{stats} - $s0->{stats}, 0, "$name: zero stat syscalls");
    is($s1->{compiles} - $s0->{compiles}, 0, "$name: zero compiles");
}

# Hash iteration is the documented exception: exactly one scratch
# vector per hash loop execution, still no buffer grows.
{
    my $tmpl = '{% for k, v in h %}{% k %}{% end %}';
    my %d = (h => { map { $_ => 1 } 'a' .. 'j' });
    $s->render($tmpl, \%d) for 1 .. 3;
    my $s0 = Template::Stencil::_stencil_stats();
    $s->render($tmpl, \%d) for 1 .. 100;
    my $s1 = Template::Stencil::_stencil_stats();
    is($s1->{scratch_allocs} - $s0->{scratch_allocs}, 100,
       'hash loop: one key vector per render (documented)');
    is($s1->{buf_grows} - $s0->{buf_grows}, 0,
       'hash loop: zero buffer grows');
}

done_testing;
