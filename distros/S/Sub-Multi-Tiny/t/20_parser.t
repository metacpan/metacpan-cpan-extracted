use 5.010001;
use strict;
use warnings;

use Sub::Multi::Tiny::SigParse;
use Test::Fatal;
use Test::More;

# Reduce typing
sub _p {
    Sub::Multi::Tiny::SigParse::Parse(join ' ', @_)
}

# Line number as a string
sub _l {
    my (undef, undef, $line) = caller;
    return "line $line";
}

# Some success cases
my $ast;

$ast = _p '$foo';
is_deeply $ast, [{name=>'$foo'}], _l;

$ast = _p 'Int $foo';
is_deeply $ast, [{type=>'Int', name=>'$foo', }], _l;

$ast = _p '$foo where { $_ > 0 }';
is_deeply $ast, [{name=>'$foo', where=>'{ $_ > 0 }'}], _l;

$ast = _p 'Int $foo where { $_ > 0 }';
is_deeply $ast, [{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }'}], _l;

$ast = _p "  \n\t" . 'Int $foo where { $_ > 0 }' . "\t\t\t";
is_deeply $ast, [{type=>'Int', name=>'$foo', where=>'{ $_ > 0 }'}], _l;

# Some failure cases
like exception { _p '   {x} $foo,  @abar  , 42[bar] %something {long one}' },
    qr/could not understand TYPE/ , _l;

like exception { _p ' {x}' }, qr/end of input/, _l;

done_testing;
