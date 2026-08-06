#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

my $dir = File::Temp::tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/w.tmpl" or die $!;
print $fh '[{% content %}]';
close $fh;
open $fh, '>', "$dir/w2.tmpl" or die $!;
print $fh '{{% content %}}';
close $fh;

my $s = Template::Stencil->new(template_dir => $dir);

# Call shapes.
is($s->render('{% v %}', { v => 'm' }), 'm', 'method call');
{
    my $m = 'render';
    is($s->$m('{% v %}', { v => 'd' }), 'd', 'dynamic method name');
}
is(Template::Stencil::render($s, '{% v %}', { v => 'f' }), 'f',
   'function-style call');
is(&Template::Stencil::render($s, '{% v %}', { v => 'a' }), 'a',
   'amp call');

# Data handling.
is($s->render('static'), 'static', 'no data argument');
is($s->render('static', undef), 'static', 'undef data');
eval { $s->render('x', []) };
like($@, qr/data must be a hashref/, 'arrayref data rejected');
eval { $s->render('x', 'str') };
like($@, qr/data must be a hashref/, 'string data rejected');

# Per-render options.
is($s->render('P', {}, { wrapper => 'w.tmpl' }), '[P]',
   'opt-in wrapper');
is($s->render('P', {}, { wrapper => 'w2.tmpl' }), '{P}',
   'wrapper choice');
{
    my $w = Template::Stencil->new(template_dir => $dir,
                                   wrapper => 'w.tmpl');
    is($w->render('P', {}), '[P]', 'engine wrapper');
    is($w->render('P', {}, { wrapper => undef }), 'P',
       'per-render disable');
}
{
    eval { $s->render('{% m %}', {}, { strict => 1 }) };
    like($@, qr/undef value/, 'per-render strict on');
    my $strict = Template::Stencil->new(strict => 1);
    is($strict->render('a{% m %}b', {}, { strict => 0 }), 'ab',
       'per-render strict off');
}
eval { $s->render('x', {}, { junk => 1 }) };
like($@, qr/unknown render option 'junk'/, 'unknown render option');
eval { $s->render('x', {}, []) };
like($@, qr/render options must be a hashref/, 'bad opts type');

# Invocant validation and subclassing.
eval { Template::Stencil::render('notobj', 'x', {}) };
like($@, qr/not a Template::Stencil object/, 'bad invocant');
{
    package My::Stencil;
    our @ISA = ('Template::Stencil');
    sub greet { 'hi' }
}
{
    my $sub = My::Stencil->new(template_dir => $dir);
    isa_ok($sub, 'My::Stencil', 'subclass constructs');
    is($sub->render('{% v %}', { v => 's' }), 's', 'subclass renders');
    is($sub->greet, 'hi', 'subclass methods intact');
}

# can() and independence of results.
can_ok('Template::Stencil', qw(new render));
{
    my $one = $s->render('{% v %}', { v => 'one' });
    my $two = $s->render('{% v %}', { v => 'two' });
    is($one, 'one', 'first result unchanged after second render');
    isnt(\$one, \$two, 'distinct SVs');
}

done_testing;
