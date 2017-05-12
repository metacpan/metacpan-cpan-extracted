use 5.010;
use warnings;

use Test::More 'no_plan';

use Regexp::Grammars;

my $base_grammar = qr{
    <grammar: List::Generic>

    <rule: List>
        \(  <[Elem]> ** (,)  \)

    <token: Elem>
        <error: Elem matcher not implemented>
}xms;

# Derived grammar...
qr{
    <grammar: List::Binary>
    <extends: List::Generic>

    <rule: List>
        \[  <[Elem]> ** (,)  \]

    <token: Elem>
        [01]+
}xms;

# Other grammar (for MI)...
qr{
    <grammar: Other>
    <extends: List::Generic>

    <token: Elem>
        [.-]+
}xms;

my $list_of_int = qr{
    <extends: List::Generic>

    <List>

    <token: Elem>
        \d+
}xms;

my $list_of_nonint = qr{
    <extends: List::Generic>

    <List>

    <token: Elem>
        [^\d,]+
}xms;

my $list_without_elem = qr{
    <extends: List::Generic>

    <List>
}xms;

my $list_of_binary = qr{
    <List>

    <extends: List::Binary>
}xms;

my $list_of_binary_or_nonint = qr{
    <extends: List::Binary>

    <List>

    <token: Elem>
        [^\d,]+ 
      | <MATCH=List::Binary::Elem>
}xms;

my $list_of_morse = qr{
    <List>

    <extends: main::Other>      # Elem redefinition from here
    <extends: List::Binary>     # List redefinition from here
                                # (requires C3 resolution to work)
}xms;

no Regexp::Grammars;

{
    local $SIG{__WARN__} = sub {
        my ($errmsg) = @_;
        is $errmsg, "Can't match directly against a pure grammar: <grammar: List::Generic>\n"
                                    => "Can't match against pure grammars";
    };
    ok "" !~ $base_grammar          => "Match against pure grammar failed";
}

ok '(1,2,3)' !~ $list_without_elem         => 'Unrepleaced Elem failed';
is $![0], 'Elem matcher not implemented'   => 'Error message correct';

ok '(1,23,456)' =~ $list_of_int            => 'Polymorphic Elem worked';
is_deeply $/{List}{Elem}, [1,23,456]       => 'Extracted correct data';

ok '(a,bc,def)' =~ $list_of_nonint         => 'Polymorphic Elem worked again';
is_deeply $/{List}{Elem}, ['a','bc','def'] => 'Extracted correct data';

ok '[0,10,010]' =~ $list_of_binary         => '2nd order inheritance worked';
is_deeply $/{List}{Elem}, ['0','10','010'] => 'Extracted correct data';

ok '[0,bc,010]' =~ $list_of_binary_or_nonint => 'Explicit call to overridden worked';
is_deeply $/{List}{Elem}, ['0','bc','010']   => 'Extracted correct data';

ok '[.,-.,..-]' =~ $list_of_morse          => 'Multiple inheritance worked';
is_deeply $/{List}{Elem}, ['.','-.','..-'] => 'Extracted correct data';
