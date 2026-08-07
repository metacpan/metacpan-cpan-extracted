#!perl
use 5.010;
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

put('wrap.tmpl',  '<w t="{% title %}">{% content %}</w>');
put('wrap2.tmpl', '<W2>{% content %}</W2>');
put('plain.tmpl', 'no content here');
put('page.tmpl',  'P:{% title %}');
put('winc.tmpl',  '<i>{% include page.tmpl %}|{% content %}</i>');

my $data = { title => 'T' };

sub engine {
    my ($wrapper) = @_;
    Template::Stencil::_engine_new($dir, $wrapper, 0, 1, 256);
}

# Engine-level wrapper; wrapper sees the same root data.
{
    my $e = engine('wrap.tmpl');
    is(Template::Stencil::_engine_render($e, 'page.tmpl', $data),
       '<w t="T">P:T</w>', 'engine wrapper composes');
    is(Template::Stencil::_engine_render($e, 'S:{% title %}', $data),
       '<w t="T">S:T</w>', 'string page under wrapper');
    Template::Stencil::_engine_free($e);
}

# Per-render override and disable.
{
    my $e = engine('wrap.tmpl');
    is(Template::Stencil::_engine_render($e, 'page.tmpl', $data,
                                         { wrapper => 'wrap2.tmpl' }),
       '<W2>P:T</W2>', 'per-render wrapper override');
    is(Template::Stencil::_engine_render($e, 'page.tmpl', $data,
                                         { wrapper => undef }),
       'P:T', 'per-render wrapper disable');
    is(Template::Stencil::_engine_render($e, 'page.tmpl', $data),
       '<w t="T">P:T</w>', 'engine default still applies after');
    Template::Stencil::_engine_free($e);
}

# No engine wrapper: per-render opt adds one.
{
    my $e = engine(undef);
    is(Template::Stencil::_engine_render($e, 'page.tmpl', $data),
       'P:T', 'no wrapper by default');
    is(Template::Stencil::_engine_render($e, 'page.tmpl', $data,
                                         { wrapper => 'wrap.tmpl' }),
       '<w t="T">P:T</w>', 'opt-in wrapper');
    Template::Stencil::_engine_free($e);
}

# A wrapper without {% content %} is refused.
{
    my $e = engine('plain.tmpl');
    eval { Template::Stencil::_engine_render($e, 'page.tmpl', $data) };
    like($@, qr/wrapper .*plain\.tmpl.* has no \{% content %\}/,
         'contentless wrapper refused');
    Template::Stencil::_engine_free($e);
}

# Rendering a template with {% content %} as the page croaks.
{
    my $e = engine(undef);
    eval { Template::Stencil::_engine_render($e, 'wrap.tmpl', $data) };
    like($@, qr/no content template/, 'content outside wrapper croaks');
    Template::Stencil::_engine_free($e);
}

# Wrapper and page includes compose freely.
{
    my $e = engine('winc.tmpl');
    is(Template::Stencil::_engine_render($e,
        'B({% include page.tmpl %})', $data),
       '<i>P:T|B(P:T)</i>', 'wrapper include + page include');
    Template::Stencil::_engine_free($e);
}

# Wrapper loop over root data (the draft wrapper shape).
put('jsw.tmpl',
    '{% for s in js %}<script src="{% s %}"></script>{% end %}{% content %}');
{
    my $e = engine('jsw.tmpl');
    is(Template::Stencil::_engine_render($e, 'X', { js => [qw(a b)] }),
       '<script src="a"></script><script src="b"></script>X',
       'wrapper loops over root data');
    Template::Stencil::_engine_free($e);
}

done_testing;
