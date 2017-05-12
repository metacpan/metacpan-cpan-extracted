use Test::Chunks;

delimiters qw($$$ ***);

plan tests => 1 * chunks;

run {
    ok(shift);
};

__END__

$$$
*** foo
this
*** bar
that

$$$

*** foo
hola
*** bar
latre
