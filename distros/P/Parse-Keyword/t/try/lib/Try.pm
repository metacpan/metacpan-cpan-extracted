package Try;
use strict;
use warnings;

use Try::Tiny ();

use Parse::Keyword { try => \&try_parser };
use Exporter 'import';

our @EXPORT = ('try');

sub try {
    my ($try, $catch, $finally) = @_;

    &Try::Tiny::try(
        $try,
        ($catch   ? (&Try::Tiny::catch($catch))     : ()),
        ($finally ? (&Try::Tiny::finally($finally)) : ()),
    );
}

sub try_parser {
    my ($try, $catch, $finally);

    lex_read_space;

    die "syntax error" unless lex_peek eq '{';
    $try = parse_block;

    lex_read_space;

    if (lex_peek(6) =~ /^catch\b/) {
        lex_read(5);
        lex_read_space;
        die "syntax error" unless lex_peek eq '{';
        $catch = parse_block;
    }

    lex_read_space;

    if (lex_peek(8) =~ /^finally\b/) {
        lex_read(7);
        lex_read_space;
        die "syntax error" unless lex_peek eq '{';
        $finally = parse_block;
    }

    return (sub { ($try, $catch, $finally) }, 1);
}

1;
