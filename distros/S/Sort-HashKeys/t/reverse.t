use Test::More;

BEGIN {
    use_ok 'Sort::HashKeys';
}

my %hash;

for (1...10) {
    my @chars = ("a".."z");
    my $string;
    $string .= $chars[rand @chars] for 1..8;

    $hash{$string} = $_;
}

my @is = Sort::HashKeys::reverse_sort(%hash);
my @should_be = map { ($_, $hash{$_}) } reverse sort keys %hash;

is @is, @should_be;
for (0..$#is-1) {
    is $is[$_], $should_be[$_];
}

done_testing;
