use 5.006;
use strict;
use warnings;

use Sub::Multi::Tiny::SigParse; # DUT

use Data::PowerSet 'powerset';
use Test::Fatal;
use Test::More;

use constant {
    true => !!1,
    false => !!0,
};

# Reduce typing
sub _p {
    Sub::Multi::Tiny::SigParse::Parse(join ' ', @_)
}

# Line number as a string
sub _l {
    my (undef, undef, $line) = caller;
    return "line $line";
}

# Bit strings

# Note: for debugging:
#use Data::Dumper;
#diag 'AST: ' . join '', unpack('H*', $ast->{seen});
#diag 'Expected: ' . join '', unpack('H*', $WTP);

my %B;  # To hold all the bit strings in convenient form
{
    my $powerset = powerset(qw(NAMED POS TYPE WHERE));  # alphabetical order
    foreach my $p (@$powerset) {
        my $key = join '', map { substr $_, 0, 1 } @$p;
        $B{$key} = '';
        vec($B{$key}, eval("Sub::Multi::Tiny::SigParse::SEEN_$_"), 1) = 1
            foreach @$p;
    }
}

my $ast;
# Success case - empty signature
$ast = _p '';
is_deeply $ast, {parms=>[], seen=>''}, _l;

# Some success cases - positional parameters

$ast = _p '$foo';
is_deeply $ast, {parms=>[{name=>'$foo', named=>false, reqd=>true}],
                seen=>$B{P}}, _l;

$ast = _p 'Int $foo';
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo', named=>false, reqd=>true}],
                seen=>$B{PT}}, _l;

$ast = _p '$foo where { $_ > 0 }';
is_deeply $ast, {parms=>[{name=>'$foo', where=>'{ $_ > 0 }', named=>false,
                reqd=>true}], seen=>$B{PW}}, _l;

$ast = _p 'Int $foo where { $_ > 0 }';
is_deeply $ast,
    {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>false,
                reqd=>true}], seen=>$B{PTW}},
    _l;

$ast = _p "  \n\t" . 'Int $foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }',
        named=>false, reqd=>true}], seen=>$B{PTW}}, _l;

# Some success cases - named parameters
$ast = _p ':$foo';
is_deeply $ast, {parms=>[{name=>'$foo', named=>true, reqd=>false}],
    seen=>$B{N}}, _l;

$ast = _p 'Int :$foo';
is_deeply $ast, {parms=>[{type=>'Int', name=>'$foo', named=>true, reqd=>false}],
    seen=>$B{NT}}, _l;

$ast = _p ':$foo where { $_ > 0 }';
is_deeply $ast, {parms=>[{name=>'$foo', where=>'{ $_ > 0 }', named=>true,
        reqd=>false}], seen=>$B{NW}}, _l;

$ast = _p 'Int :$foo where { $_ > 0 }';
is_deeply $ast,
    {parms=>[{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>true,
            reqd=>false}], seen=>$B{NTW}},
    _l;

$ast = _p "  \n\t" . 'Int :$foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, {parms=>[
        {type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>true,
            reqd=>false}
    ], seen=>$B{NTW}}, _l;

# Success with both
$ast = _p '$foo, :$bar';
is_deeply $ast, {parms=>[
        {name=>'$foo', named=>false, reqd=>true},
        {name=>'$bar', named=>true, reqd=>false},
    ], seen=>$B{NP}}, _l;

$ast = _p '$foo, :$bar,';   # With trailing comma
is_deeply $ast, {parms=>[
        {name=>'$foo', named=>false, reqd=>true},
        {name=>'$bar', named=>true, reqd=>false},
    ], seen=>$B{NP}}, _l;

$ast = _p "  \n\t" . 'String $bar, Int :$foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, {parms=>[
        {type=>'String', name=>'$bar', named=>false, reqd=>true},
        {type=>'Int', name=>'$foo', where=>'{ $_ > 0 }', named=>true, reqd=>false}],
    seen=>$B{NPTW}}, _l;

# Optional/reqd
$ast = _p '$foo?';
is_deeply $ast, {parms=>[{name=>'$foo', named=>false, reqd=>false}],
                    seen=>$B{P}}, _l;

$ast = _p ':$foo!';
is_deeply $ast, {parms=>[{name=>'$foo', named=>true, reqd=>true}],
                    seen=>$B{N}}, _l;

# Some failure cases
like exception { _p '   {x} $foo,  @abar  , 42[bar] %something {long one}' },
    qr/could not understand TYPE/ , _l;

like exception { _p ' {x}' }, qr/end of input/, _l;

done_testing;
