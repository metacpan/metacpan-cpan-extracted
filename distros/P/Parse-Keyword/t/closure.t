use strict;
use warnings;
use 5.014;
use Test::More;

BEGIN {
    package MyExample;
    $INC{'MyExample.pm'} = __FILE__;
    use base 'Exporter';
    use Parse::Keyword { example => \&_parse_example };
    our @EXPORT = 'example';
    sub example {
        shift->();
    }
    sub _parse_example {
        lex_read_space;
        my $code = parse_block;
        lex_read_space;
        return sub { $code };
    }
}

use MyExample 'example';

is(example { 1 }, 1);
is(example { 2 }, 2);
is(example { 3 }, 3);

for our $package (1..3)
{
    is(example { $package }, $package);
}

for my $lexical (1..3)
{
    local $TODO = "broken";
    is(example { $lexical }, $lexical);
}

sub xxxx {
    my $lexical = shift;
    say example { $lexical };
}

for (1..3) {
    local $TODO = "broken" if $_ > 1;
    is(xxxx($_), $_);
}

is(xxxx(1), 1);
{ local $TODO = "broken";
is(xxxx(2), 2);
is(xxxx(3), 3);
}

for my $x (1..3) {
    local $TODO = "broken" if $x > 1;
    is(xxxx($x), $x);
}

done_testing;
