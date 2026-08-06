#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

my $dir = File::Temp::tempdir(CLEANUP => 1);

# Pairs and hashref forms both construct.
{
    my $a = Template::Stencil->new(template_dir => $dir);
    isa_ok($a, 'Template::Stencil', 'pairs form');
    my $b = Template::Stencil->new({ template_dir => $dir });
    isa_ok($b, 'Template::Stencil', 'hashref form');
    my $c = Template::Stencil->new;
    isa_ok($c, 'Template::Stencil', 'no options');
}

# Every documented option is accepted.
{
    my $s = Template::Stencil->new(
        template_dir => $dir,
        wrapper      => 'w.tmpl',
        filters      => { f => sub { $_[0] } },
        auto_escape  => 1,
        strict       => 0,
        cache        => 1,
        sort_keys    => 1,
        stat_ttl     => 0.5,
        cache_size   => 8,
    );
    isa_ok($s, 'Template::Stencil', 'full option set');
}

# Validation matrix.
eval { Template::Stencil->new(template_dir => "$dir/nope") };
like($@, qr/template_dir .* is not a directory/, 'bad template_dir');
eval { Template::Stencil->new(filters => 'x') };
like($@, qr/filters must be a hashref/, 'bad filters type');
eval { Template::Stencil->new(filters => { f => 'x' }) };
like($@, qr/filter 'f' is not a coderef/, 'bad filter value');
eval { Template::Stencil->new(stat_ttl => 'abc') };
like($@, qr/stat_ttl must be a number/, 'bad stat_ttl');
eval { Template::Stencil->new(cache_size => 0) };
like($@, qr/cache_size must be a positive integer/, 'bad cache_size');
eval { Template::Stencil->new(bogus => 1) };
like($@, qr/unknown option 'bogus'/, 'unknown option');
eval { Template::Stencil->new('odd') };
like($@, qr/odd number of options/, 'odd pairs');

# Option semantics.
{
    my $esc = Template::Stencil->new;
    is($esc->render('{% v %}', { v => '<x>' }), '&lt;x&gt;',
       'auto_escape default on');
    my $raw = Template::Stencil->new(auto_escape => 0);
    is($raw->render('{% v %}', { v => '<x>' }), '<x>',
       'auto_escape => 0 renders raw');
    is($raw->render('{% raw v %}', { v => '<x>' }), '<x>',
       'raw still raw');
}
{
    my $strict = Template::Stencil->new(strict => 1);
    eval { $strict->render('{% missing %}', {}) };
    like($@, qr/undef value for 'missing'/, 'engine-level strict');
}
{
    my $s = Template::Stencil->new(sort_keys => 1);
    is($s->render('{% for k, v in h %}{% k %}{% end %}',
                  { h => { b => 1, a => 2, c => 3 } }),
       'abc', 'sort_keys on');
}

done_testing;
