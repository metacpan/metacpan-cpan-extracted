package My::Parser;
use Exporter 'import';
our @EXPORT = ('foo', 'bar');

use Parse::Keyword {
    foo => \&parse_foo,
    bar => \&parse_bar,
};

our $got_code;

sub foo { 1 }
sub parse_foo {
    lex_read_space;
    my $code = parse_block;
    $got_code = $code ? 1 : 0;
    return sub {};
}

sub bar { 1 }
sub parse_bar {
    lex_read_space;
    my $code = eval { parse_block };
    $got_code = $code ? 1 : 0;
    return sub {};
}

1;
