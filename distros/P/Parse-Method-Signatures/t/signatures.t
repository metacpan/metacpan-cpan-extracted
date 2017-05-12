use strict;
use warnings;

use Test::More;
use Test::Exception;
use Parse::Method::Signatures;

my @sigs = (
    ['()',                      'empty signature'],
    ['($x)',                    'single required positional'],
    ['($x:)',                   'invocant only'],
    ['($x, $y)',                'two required positionals'],
    ['($x where { $_->isa("Moose") })',
                                'with constraint'],
    ['($x where { $_->isa("Moose") } where { $_->does("Gimble") })',
                                'multiple constraints'],
    ['(Str $name)',             'typed positional'],
    ['(Int $x, Str $y)',        'multiple typed positionals'],
    ['(Animal|Human $affe)',    'type constraint alternative'],
    ['(Some::Class $x)',        'type constraint with colon'],
    ['(Some2Class $x)',         'type constraint with number in middle'],
    ['(SomeClass2 $x)',         'type constraint with number at end'],
    ['(Tuple[Int,Str] $x)',     'parameterized types'],
    ['(Str|Tuple[Int,Str] $x)', 'parameterized with alternative'],
    ['($: $x, $y, $z)',         'dummy invocant'],
    ['($, $, $x)',              'dummy positionals'],
    ['($x, @)',                 'dummy list'],
    ['(:$x)',                   'optional named'],
    ['(:$x!)',                  'required named'],
    ['(Str :$x)',               'named with type constraint'],
    ['($x, $y, :$z)',           'positional and named'],
    ['($x, $y?, :$z)',          'optional positional and named'],
    ['(:$a, :$b, :$c)',         'multiple named'],
    ['($a, $b, :$c!, :$d!)',    'positional and multiple required named'],
    ['($a?, $b?, :$c, :$d)',    'optional positional and named'],
    ['(:$x! where { 1 })',      'required named with constraint'],
    ['($self: $moo)',           'invocant and positional'],
    ['(:apan($affe))',          'long named'], # called as $obj->foo(apan => $value)
    ['(:apan($affe)!)',         'required long named'],
    ['($self: :$x)',            'named param with invocant'],
    ['($: :$x)',                'named param with dummy invocant'],
    ['($x = 42)',               'positional with default'],
    ['(:$x = 42)',              'named with default'],
    ['($x = "foo")',            'simple string default'],
    ['($x = "foo, bar")',       'string default with comma'],
    ["(\$x = 'foo, bar')",      'single quoted default with comma'],
    ['($x = q"foo")',           'default with q"" quoting'],
    ['($x = q{foo})',           'default with q{} quoting'],
    ['($x = q(foo))',           'default with q() quoting'],
    ['($x = q,foo,)',           'default with q,, quoting'],
    ['($x, $y = $x)',           'default based on other paramter'],
    ['(Str :$who, Int :$age where { $_ > 0 })',
                                'complex with constraint'],
    ['(Str $name, Bool :$excited = 0)',
                                'complex with default'],
    [q#(SomeClass $thing where { $_->can('stuff') })#, 
                                'complex with constraint'],
    [q#(SomeClass $thing where { $_->can('stuff') }: Str $bar = "apan", Int :$baz = 42 where { $_ % 2 == 0 } where { $_ > 10 })#,
                                'complex invocant, defaults and constraints'],
    ['(@x)',                    'positional array'],
    ['($x, @y)',                'positinal scalar and array'],
    ['(%x)',                    'positinal hash'],
    ['($x, %y)',                'positinal scalar and hash'],
    ['([$x, $y])',              'simple array ref unpacking'],
    ['(ArrayRef [$x, $y])',     'simple array ref unpacking with unparameterized type', 'TODO'],
    ['(ArrayRef[] [$x, $y])',   'simple array ref unpacking with empty parameterized type',],
    ['([@x])',                  'array ref unpacking into array'],
    ['([$x, $y, @rest])',       'array ref unpacking into scalars and arrays'],
    ['($x, [$y, $z, @rest])',   'array ref unpacking combined with normal positionals'],
    ['([$y, $z, @rest], $x)',   'array ref unpacking combined with normal positionals'],
    ['([$y, $z, @rest], :$x)',  'array ref unpacking combined with named'],
    ['(:foo([$x, $y, @rest]))', 'named array ref unpacking'],
    ['({%x})',                  'hash ref unpacking into hash'],
    ['(:foo({%x}))',            'labeld hash ref unpacking into hash'],
    ['({:$x, :$y, %rest})',     'hash ref unpacking into scalars and hash'],
    ['($x, {:$y, :$z, %rest})', 'hash ref unpacking combined with normal positionals'],
    ['({:$y, :$z, %rest}, $x)', 'hash ref unpacking combined with normal positionals'],
    ['({:$x, :$y, %r}, :$z)',   'hash ref unpacking combined with named'],
    ['(:foo({:$x, :$y, %r}))',  'named hash ref unpacking'],
    ['(:foo($), :bar(@))',      'named placeholders'],
    ['(Foo[Bar|Baz[Moo]]|Kooh $foo)',
                                'complex parameterized type'],
    ['($foo is coerce)',        'positional with traits (is)'],
    ['($foo does coerce)',      'positional with traits (does)'],
    ['(:$foo is coerce)',       'named with traits (is)'],
    ['(:$foo does coerce)',     'named with traits (does)'],
    ['($foo is copy is ro does coerce)',
                                'multiple traits'],

    ['($x = "foo")',            'string default'],
    ['($x = q"fo)o")',          'string default'],
    ['($x = [ ])',              'simple array default'],
    ['($x = { })',              'simple hash default'],
    ['($x = 0xf)',              'hex default'],
    ['($x = 0xfF)',             'hex default'],
);

my @alternative = (
    [q{($param1, # Foo bar
        $param2?)},             '($param1, $param2?)',     'comments in multiline'],
    ['(:$x = "foo")',           '(:$x = "foo")',           'default value stringifies okay'],
    ['($self: $moo)',           '($self: $moo)',           'invocant and positional'],
    ['(Animal | Human $affe)',  '(Animal|Human $affe)',    'type constraint alternative with whitespace'],
    ['(HashRef[foo => Str] $foo)',
                                '(HashRef["foo",Str] $foo)', 'Hash with required key'],
);

my @invalid = (
    ['($x?:)',                  'optional invocant'],
    ['(@x:)',                   'non-scalar invocant'],
    ['(%x:)',                   'non-scalar invocant'],
    ['($x?, $y)',               'required positional after optional one'],
    ['(Int| $x)',               'invalid type alternation'],
    ['(|Int $x)',               'invalid type alternation'],
    ['(@x, $y)',                'scalar after array'],
    ['(@x, @y)',                'multiple arrays'],
    ['(%x, %y)',                'multiple hashes'],
    ['(@, $x)',                 'scalar after array placeholder'],
    ['(:@x)',                   'named array'],
    ['(:%x)',                   'named hash'],
    ['(:@)',                    'named array placeholder'],
    ['(:%)',                    'named hash placeholder'],
    ['(:[@x])',                 'named array ref unpacking without label'],
    ['([:$x, :$y])',            'unpacking array ref to something not positional'],
    ['(:{%x})',                 'named hash ref unpacking without label'],
    ['({$x, $y})',              'unpacking hash ref to something not named'],
    ['($foo where { 1, $bar)',  'unbalanced { in conditional'],
    ['($foo = `pwd`)',          'invalid quote op', "Do we want to allow this"],
    ['($foo = "pwd\')',         'unbalanced quotes'],
    ['(:$x:)',                  'named invocant is invalid'],
    ['($x! = "foo":)',          'default value for invocant is invalid'],
    ['($foo is bar moo is bo)', 'invalid traits'],
    ['(Foo:: Bar $foo)',        'invalid spaces in TC'],
    ['(Foo ::Bar $foo)',        'invalid spaces in TC'],
    ['(@y: $foo)',              'invalid invocant'],
    ['(@y,)',                   'trailing comma'],
    ['($x where [ foo ])',      'no block after where'],
    ['($x does $x)',            'invalid param trait'],
    ['(:foo(Str $x))',          'invalid label contents'],
    # This should probably be valid
    ['($x = $a[0])',            'invalid label contents'],
);

my @no_warn = (
    ['($x where { $_ =~ /foo/ })', 'Regexp without operator' ]
);

plan tests => scalar @sigs * 3 
            + scalar @alternative 
            + scalar @invalid
            + scalar @no_warn
;

test_sigs(sub {
    my ($input, $msg, $todo) = @_;
    my $sig;
    lives_ok {
        $sig = Parse::Method::Signatures->signature($input);
    } $msg;
    isa_ok($sig, 'Parse::Method::Signatures::Sig', $msg);
    TODO: {
        todo_skip $todo, 1 if $todo && !$sig;
        is($sig->to_string, $input, $msg);
    }
}, @sigs);

for my $row (@alternative) {
    my ($in, $out, $msg) = @{ $row };
    lives_and {
        is(Parse::Method::Signatures->signature($in)->to_string, $out, $msg)
    } $msg;
}

test_sigs(sub {
    my ($sig, $msg) = @_;
    dies_ok { Parse::Method::Signatures->signature($sig) } $msg;
}, @invalid);

test_no_warn(@no_warn);

sub test_sigs {
    my ($test, @sigs) = @_;

    for my $row (@sigs) {
        my ($sig, $msg, $todo) = @{ $row };
        TODO: {
            local $TODO = $todo if $todo;
            $test->($sig, $msg, $todo);
        }
    }
}

sub test_no_warn {
    my (@sigs) = @_;

    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= "@_"; };

    for my $row (@sigs) {
        my ($sig, $msg, $todo) = @{ $row };
        TODO: {
            $warnings = "";
            local $TODO = $todo if $todo;
            Parse::Method::Signatures->signature($sig);
            is("", $warnings, $msg || "'$sig' generated no warnings");
        }
    }
}
