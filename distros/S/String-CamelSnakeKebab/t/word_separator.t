use Test::Most;
use String::CamelSnakeKebab;

my $separator = $String::CamelSnakeKebab::WORD_SEPARATOR_PATTERN;

my %tests = (
    "foo bar"    => [qw/foo bar/],
    "foo\n\tbar" => [qw/foo bar/],
    "foo-bar"    => [qw/foo bar/],
    "fooBar"     => [qw/foo Bar/],
    "FooBar"     => [qw/Foo Bar/],
    "foo_bar"    => [qw/foo bar/],
    "FOO_BAR"    => [qw/FOO BAR/],
    "foo1"       => [qw/foo1/],
    "foo1bar"    => [qw/foo1bar/],
    "foo1_bar"   => [qw/foo1 bar/],
    "foo1Bar"    => [qw/foo1 Bar/],
);

cmp_deeply [ split $separator, $_ ] => $tests{$_}, 
    sprintf "%8s -> %s", $_, join " ", @{ $tests{$_} }
        for sort keys %tests;


done_testing;
