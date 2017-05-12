use strict;
use warnings;
use Test::More;

BEGIN {
    if (!eval { require Exporter::Lexical }) {
        plan skip_all => "This test requires Exporter::Lexical";
    }
}

BEGIN { plan skip_all => "This doesn't work yet." }

BEGIN {
    package My::Parser;
    use Exporter::Lexical -exports => ['foo'];
    use Parse::Keyword { foo => \&parse_foo };

    sub foo { $_[0]->() }
    sub parse_foo {
        lex_read_space;
        my $code = parse_block;
        return sub { $code };
    }
    $INC{'My/Parser.pm'} = __FILE__;
}

{
    use My::Parser;
    is(foo { my $x = 1; $x + 3 }, 4);
}
eval "foo { 1 }";
like $@, qr/slkfdj/;

done_testing;
