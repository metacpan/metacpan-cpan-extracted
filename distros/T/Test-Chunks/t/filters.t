use Test::Chunks;

filters 'upper';
plan tests => 2;

run {
    my $chunk = shift;
    is($chunk->one, $chunk->two);
};

my ($chunk) = chunks;
is($chunk->one, "HEY NOW HEY NOW\n");

sub Test::Chunks::Filter::upper {
    my $self = shift;
    return uc(shift);
}

__END__
===
--- one
Hey now Hey Now

--- two
hEY NoW hEY NoW
