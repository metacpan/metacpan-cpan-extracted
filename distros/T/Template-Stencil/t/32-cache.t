#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub put {
    my ($name, $content) = @_;
    open my $fh, '>', "$dir/$name" or die $!;
    print $fh $content;
    close $fh;
}

sub stats { Template::Stencil::_stencil_stats() }
sub delta {
    my ($before, $key) = @_;
    stats()->{$key} - $before->{$key};
}

put('t.tmpl', 'v1:{% x %}');
my $data = { x => 'X' };

# Repeated file render: one compile, then cache hits.
{
    my $e = Template::Stencil::_engine_new($dir, undef, 0, 1, 256);
    my $s0 = stats();
    Template::Stencil::_engine_render($e, 't.tmpl', $data) for 1 .. 5;
    is(delta($s0, 'compiles'), 1, 'file compiled once for 5 renders');
    cmp_ok(delta($s0, 'cache_hits'), '>=', 4, 'subsequent renders hit');
    Template::Stencil::_engine_free($e);
}

# Repeated string render: one compile.
{
    my $e = Template::Stencil::_engine_new($dir, undef, 0, 1, 256);
    my $s0 = stats();
    Template::Stencil::_engine_render($e, 'S:{% x %}', $data) for 1 .. 5;
    is(delta($s0, 'compiles'), 1, 'string compiled once');
    Template::Stencil::_engine_free($e);
}

# mtime invalidation with stat_ttl => 0 (stat every render).
{
    my $e = Template::Stencil::_engine_new($dir, undef, 0, 0, 256);
    is(Template::Stencil::_engine_render($e, 't.tmpl', $data), 'v1:X',
       'initial content');
    put('t.tmpl', 'v2:{% x %}');
    my $future = time + 5;
    utime $future, $future, "$dir/t.tmpl" or die "utime: $!";
    my $s0 = stats();
    is(Template::Stencil::_engine_render($e, 't.tmpl', $data), 'v2:X',
       'mtime bump recompiles');
    is(delta($s0, 'compiles'), 1, 'exactly one recompile');
    Template::Stencil::_engine_free($e);
    put('t.tmpl', 'v1:{% x %}'); # restore
}

# stat_ttl => -1: never re-stat, changes ignored, zero syscalls.
{
    my $e = Template::Stencil::_engine_new($dir, undef, 0, -1, 256);
    is(Template::Stencil::_engine_render($e, 't.tmpl', $data), 'v1:X',
       'warm render');
    put('t.tmpl', 'CHANGED');
    my $future = time + 10;
    utime $future, $future, "$dir/t.tmpl" or die "utime: $!";
    my $s0 = stats();
    is(Template::Stencil::_engine_render($e, 't.tmpl', $data), 'v1:X',
       'change invisible at ttl -1');
    is(delta($s0, 'stats'), 0, 'zero stat syscalls at steady state');
    is(delta($s0, 'compiles'), 0, 'zero compiles at steady state');
    Template::Stencil::_engine_free($e);
    put('t.tmpl', 'v1:{% x %}');
}

# Bounded string LRU: oldest evicted at capacity.
{
    my $e = Template::Stencil::_engine_new($dir, undef, 0, 1, 2);
    Template::Stencil::_engine_render($e, "s1 {% x %}", $data);
    Template::Stencil::_engine_render($e, "s2 {% x %}", $data);
    Template::Stencil::_engine_render($e, "s3 {% x %}", $data); # evicts s1
    my $s0 = stats();
    Template::Stencil::_engine_render($e, "s3 {% x %}", $data);
    is(delta($s0, 'compiles'), 0, 'recent string still cached');
    Template::Stencil::_engine_render($e, "s1 {% x %}", $data);
    is(delta($s0, 'compiles'), 1, 'evicted string recompiles');
    Template::Stencil::_engine_free($e);
}

# cache => 0 (flag 4): fresh compile every render.
{
    my $e = Template::Stencil::_engine_new($dir, undef, 4, 1, 256);
    my $s0 = stats();
    Template::Stencil::_engine_render($e, 'S:{% x %}', $data) for 1 .. 3;
    is(delta($s0, 'compiles'), 3, 'no-cache compiles each render');
    Template::Stencil::_engine_free($e);
}

# Include revalidation: editing an include takes effect without
# touching the includer (ttl 0).
put('outer.tmpl', 'O:{% include inc.tmpl %}');
put('inc.tmpl', 'old');
{
    my $e = Template::Stencil::_engine_new($dir, undef, 0, 0, 256);
    is(Template::Stencil::_engine_render($e, 'outer.tmpl', $data),
       'O:old', 'include initial');
    put('inc.tmpl', 'new');
    my $future = time + 5;
    utime $future, $future, "$dir/inc.tmpl" or die "utime: $!";
    my $s0 = stats();
    is(Template::Stencil::_engine_render($e, 'outer.tmpl', $data),
       'O:new', 'include edit picked up');
    is(delta($s0, 'compiles'), 1, 'only the include recompiled');
    Template::Stencil::_engine_free($e);
}

done_testing;
