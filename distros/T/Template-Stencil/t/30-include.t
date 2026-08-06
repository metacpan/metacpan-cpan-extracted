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
    open my $fh, '>', "$dir/$name" or die "$dir/$name: $!";
    print $fh $content;
    close $fh;
}

sub engine { Template::Stencil::_engine_new($dir, undef, 0, 1, 256) }
sub render_e {
    my ($e, $tmpl, $data, @opts) = @_;
    Template::Stencil::_engine_render($e, $tmpl, $data, @opts);
}

# Includes share the enclosing scope: loop vars, set binds, root data.
put('item.tmpl', '[{% i %}/{% loop.index %}/{% tag %}/{% root %}]');
put('list.tmpl',
    '{% set tag = "T" %}{% for i in items %}{% include item.tmpl %}{% end %}');
{
    my $e = engine();
    is(render_e($e, 'list.tmpl', { items => [qw(a b)], root => 'R' }),
       '[a/0/T/R][b/1/T/R]',
       'include sees loop vars, set binds and root data');
    Template::Stencil::_engine_free($e);
}

# Nested includes, and .tmpl inference for include names.
put('outer.tmpl', 'O({% include middle %})');
put('middle.tmpl', 'M({% include inner.tmpl %})');
put('inner.tmpl', 'I:{% v %}');
{
    my $e = engine();
    is(render_e($e, 'outer', { v => 'x' }), 'O(M(I:x))',
       'nested includes with .tmpl inference');
    Template::Stencil::_engine_free($e);
}

# Missing include names the including template and the include site.
put('broken.tmpl', "line one\n  {% include nope.tmpl %}");
{
    my $e = engine();
    eval { render_e($e, 'broken.tmpl', {}) };
    like($@, qr/\Qbroken.tmpl\E:2:3: cannot find include 'nope\.tmpl'/,
         'missing include: includer name + line:col');
    Template::Stencil::_engine_free($e);
}

# Include cycles are link-time errors naming the cycle.
put('a.tmpl', 'A{% include b.tmpl %}');
put('b.tmpl', 'B{% include a.tmpl %}');
{
    my $e = engine();
    eval { render_e($e, 'a.tmpl', {}) };
    like($@, qr/include cycle: .*b\.tmpl -> .*a\.tmpl/,
         'cycle error names the cycle');
    Template::Stencil::_engine_free($e);
}

# Self-include is the smallest cycle.
put('selfy.tmpl', '{% include selfy.tmpl %}');
{
    my $e = engine();
    eval { render_e($e, 'selfy.tmpl', {}) };
    like($@, qr/include cycle/, 'self-include is a cycle');
    Template::Stencil::_engine_free($e);
}

# String templates can include files too.
{
    my $e = engine();
    is(render_e($e, 'S:{% include inner.tmpl %}', { v => 'q' }), 'S:I:q',
       'string template includes a file');
    Template::Stencil::_engine_free($e);
}

# An include used twice by the same template.
put('twice.tmpl', '{% include inner.tmpl %}+{% include inner.tmpl %}');
{
    my $e = engine();
    is(render_e($e, 'twice.tmpl', { v => 'z' }), 'I:z+I:z',
       'same include twice');
    Template::Stencil::_engine_free($e);
}

# Include inside a conditional only runs when the branch does.
put('cond.tmpl', '{% if go %}{% include inner.tmpl %}{% end %}!');
{
    my $e = engine();
    is(render_e($e, 'cond.tmpl', { go => 0, v => 'x' }), '!',
       'include in dead branch not executed');
    is(render_e($e, 'cond.tmpl', { go => 1, v => 'x' }), 'I:x!',
       'include in live branch executed');
    Template::Stencil::_engine_free($e);
}

# Runtime error inside an include reports the include's name and line.
put('bad-inner.tmpl', "ok\n{% v.oops %}");
put('bad-outer.tmpl', '{% include bad-inner.tmpl %}');
{
    my $e = Template::Stencil::_engine_new($dir, undef, 1, 1, 256); # strict
    eval { render_e($e, 'bad-outer.tmpl', {}) };
    like($@, qr/\Qbad-inner.tmpl\E:2: undef value for 'v\.oops'/,
         'runtime error names the failing include unit');
    Template::Stencil::_engine_free($e);
}

done_testing;
