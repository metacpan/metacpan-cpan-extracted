use strict;
use warnings;
use Test::More;

BEGIN {
    package My::Parser;
    use Exporter 'import';
    our @EXPORT = ('foo', 'bar');

    use Parse::Keyword {
        foo => \&parse_foo,
        bar => \&parse_bar,
    };

    sub foo {}

    sub parse_foo {
        lex_read_space;
        die unless lex_peek eq '{';
        parse_block(1)->();
        return (sub {}, 1);
    }

    sub bar { $::body = $_[0] }

    sub parse_bar {
        lex_read_space;
        die unless lex_peek eq '{';
        my $body = parse_block;
        return (sub { $body }, 1);
    }

    $INC{'My/Parser.pm'} = __FILE__;
}

use My::Parser;

my $bar;
my $baz = 5;

foo {
    bar { $baz }
}

is($::body->(), 5);

done_testing;
