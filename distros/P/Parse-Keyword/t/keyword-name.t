use strict;
use warnings;
use Test::More;

BEGIN {
    package My::Parser;
    use Exporter 'import';
    our @EXPORT = 'foo';

    use Parse::Keyword { foo => \&parse_foo };

    sub foo { $_[0] }
    sub parse_foo {
        my ($keyword) = @_;
        return sub { uc($keyword) };
    }

    $INC{'My/Parser.pm'} = __FILE__;
}

use My::Parser;
is(foo, 'FOO');

done_testing;
