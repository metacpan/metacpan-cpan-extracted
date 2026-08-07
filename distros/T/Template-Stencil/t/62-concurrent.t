#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

plan skip_all => 'no real fork on this platform' if $^O eq 'MSWin32';

# Fork model sanity: several children rendering the same configuration
# produce byte-identical output, whether each constructs its own engine
# post-fork or inherits the parent's warm engine.

my $tmpl = '{% for i in items %}[{% i %}:{% loop.index %}]{% end %}'
         . '{% for k, v in h %}{% k %}={% v %};{% end %}{% x | upper %}';
my $data = {
    items => [qw(a b c)],
    h     => { one => 1, two => 2 },
    x     => 'done',
};

sub child_out {
    my ($engine_maker) = @_;
    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $s = $engine_maker->();
        print $s->render($tmpl, $data) for 1 .. 20;
        exit 0;
    }
    my $out = do { local $/; <$rd> };
    close $rd;
    return $out;
}

my $expect = do {
    my $s = Template::Stencil->new;
    my $one = $s->render($tmpl, $data);
    $one x 20;
};

# Post-fork construction (the documented model).
{
    my @outs = map { child_out(sub { Template::Stencil->new }) } 1 .. 4;
    is($outs[$_], $expect, "post-fork child $_ byte-identical")
        for 0 .. 3;
}

# Inherited warm engine (COW memory after fork).
{
    my $shared = Template::Stencil->new;
    $shared->render($tmpl, $data);   # warm the cache pre-fork
    my @outs = map { child_out(sub { $shared }) } 1 .. 4;
    is($outs[$_], $expect, "inherited-engine child $_ byte-identical")
        for 0 .. 3;
    is($shared->render($tmpl, $data) x 20, $expect,
       'parent engine fine after children exit');
}

done_testing;
