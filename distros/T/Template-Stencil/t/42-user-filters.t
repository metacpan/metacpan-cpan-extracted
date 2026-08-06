#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

my @calls;
my %filters = (
    money => sub { push @calls, [@_]; sprintf '%.2f', $_[0] // 0 },
    rep   => sub { $_[0] x $_[1] },
    boom  => sub { die "kaboom\n" },
    tag   => sub { "<em>$_[0]</em>" },
);

sub engine {
    Template::Stencil::_engine_new(undef, undef, 0, 1, 256, \%filters);
}
sub er {
    my ($e, $tmpl, $data) = @_;
    Template::Stencil::_engine_render($e, $tmpl, $data);
}

# Basic call, return value rendered, args passed.
{
    my $e = engine();
    is(er($e, '{% p | money %}', { p => 3.5 }), '3.50', 'coderef called');
    is_deeply($calls[-1], [3.5], 'value passed as first arg');
    is(er($e, '{% s | rep(3) %}', { s => 'ab' }), 'ababab',
       'numeric literal arg passed');
    is(er($e, '{% s | rep("2") %}', { s => 'x' }), 'xx',
       'string literal arg passed');
    Template::Stencil::_engine_free($e);
}

# User filter output is auto-escaped like any other value.
{
    my $e = engine();
    is(er($e, '{% v | tag %}', { v => 'hi' }),
       '&lt;em&gt;hi&lt;/em&gt;', 'user output escaped');
    is(er($e, '{% raw v | tag %}', { v => 'hi' }), '<em>hi</em>',
       'raw user output raw');
    Template::Stencil::_engine_free($e);
}

# User filters chain with built-ins in both directions.
{
    my $e = engine();
    is(er($e, '{% p | money | upper %}', { p => 1 }), '1.00',
       'user then builtin');
    is(er($e, '{% s | trim | rep(2) %}', { s => ' a ' }), 'aa',
       'builtin then user');
    Template::Stencil::_engine_free($e);
}

# die inside a filter becomes a render error with the filter name and
# template location.
{
    my $e = engine();
    eval { er($e, "line1\n{% v | boom %}", { v => 1 }) };
    like($@, qr/<string>:2: filter 'boom' died: kaboom/,
         'die propagates with name and line');
    Template::Stencil::_engine_free($e);
}

# Unknown filters are compile-time errors listing the registry.
{
    my $e = engine();
    eval { er($e, '{% v | missing_filter %}', { v => 1 }) };
    like($@, qr/unknown filter 'missing_filter' \(registered:/,
         'unknown filter names itself');
    like($@, qr/money/, 'registry listed');
    Template::Stencil::_engine_free($e);
}
{
    my $e = Template::Stencil::_engine_new(undef, undef, 0, 1, 256);
    eval { er($e, '{% v | anything %}', { v => 1 }) };
    like($@, qr/unknown filter 'anything' \(registered: none\)/,
         'no registry says none');
    Template::Stencil::_engine_free($e);
}

# Non-coderef registration croaks at engine construction.
eval {
    Template::Stencil::_engine_new(undef, undef, 0, 1, 256,
                                   { bad => 'not a sub' });
};
like($@, qr/filter 'bad' is not a coderef/, 'bad registration rejected');

# Filters work inside includes (per-unit filter tables).
{
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/inc.tmpl" or die $!;
    print $fh '{% v | money %}';
    close $fh;
    my $e = Template::Stencil::_engine_new($dir, undef, 0, 1, 256,
                                           \%filters);
    is(Template::Stencil::_engine_render($e,
        'X:{% include inc.tmpl %}', { v => 2 }), 'X:2.00',
       'user filter inside include');
    Template::Stencil::_engine_free($e);
}

done_testing;
