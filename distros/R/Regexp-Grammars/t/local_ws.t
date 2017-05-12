use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $parser = qr{
    <code>

    <rule: code>
        <ws: (?: \s++ | <!-- .* --\> )*+  >
        <cmd>  <arg>

    <rule: cmd>
        <ws: \s* | ooo>
        a d d | s u b | m u l

    <token: arg>
        \d++
}xms;

no Regexp::Grammars;

if ('mooouoool <!-- ignore this --> 7' =~ $parser) {
    ok 1 => 'Whitespace overridden';
}
else {
    ok 0 => 'Whitespace overridden';
}


my $test_grammar = do {
    use Regexp::Grammars;
    qr{

        <program>

        <rule: program>
            <ws: (\s++ | \# .*? \n)* >     # One type of comment between statements
            <[statement]> ** ( ; )

        <rule: statement> 
            <ws: (\s*+ |  \#[{] .*? [}]\# )* >   # Another type within statements
            <cmd> <[arg]> ** ( , )

        <token: cmd>
            foo | bar

        <token: arg>
            baz
    }xms;
};

my $text = q{
    foo baz, baz, baz;
    # comment
    bar #{ comment }# baz
};

my $expected_result = {
      "" => "\n    foo baz, baz, baz;\n    # comment\n    bar #{ comment }# baz",
      "program" => {
        "" => "\n    foo baz, baz, baz;\n    # comment\n    bar #{ comment }# baz",
        "statement" => [
          {
            "" => "foo baz, baz, baz",
            "arg" => ["baz", "baz", "baz"],
            "cmd" => "foo",
          },
          { "" => "bar #{ comment }# baz", "arg" => ["baz"], "cmd" => "bar" },
        ],
      },
};

ok $text =~ $test_grammar  => 'Multiple <ws:...>';
is_deeply \%/, $expected_result  => 'Parse is correct';
