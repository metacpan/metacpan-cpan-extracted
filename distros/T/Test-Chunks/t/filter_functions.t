use Test::Chunks;

filters {
    foo => 'upper',
    bar => 'lower',
};

plan tests => 2 * chunks;

run_is 'foo', 'upper';
run_is 'bar', 'lower';

sub upper { uc(shift) }
sub Test::Chunks::Filter::lower { shift; lc(shift) }

__END__
===
--- foo
So long, and thanks for all the fish!
--- bar
So long, and thanks for all the fish!
--- upper
SO LONG, AND THANKS FOR ALL THE FISH!
--- lower
so long, and thanks for all the fish!
