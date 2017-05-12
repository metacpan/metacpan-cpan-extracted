use Benchmark qw{:all};

my @arr = (1 .. 10004);

#	perl benchmark-data-empty.pl
#								Rate   hash_undef  array_undef  hash_assign array_assign
#	hash_undef   636/s           --         -24%         -28%         -30%
#	array_undef  833/s          31%           --          -5%          -8%
#	hash_assign  881/s          39%           6%           --          -3%
#	array_assign 907/s          43%           9%           3%           --

sub array_assign { my @arr = @_; @arr = (); @arr }
sub array_undef  { my @arr = @_; undef @arr; @arr }
sub hash_assign  { my %hash = @_; %hash = (); %hash }
sub hash_undef   { my %hash = @_; undef %hash; %hash }

do {
	my @res;

	for my $func_name (qw{
		array_assign
		array_undef
		hash_assign
		hash_undef
	}) {
		@res = &$func_name(@arr);
		printf "%-25s size: %d side_effects: %d empty:%d\n", $func_name, scalar @res, ! defined $arr[0], ! defined $res[0];
	}
};

cmpthese(10000, {
	array_assign => sub { array_assign(@arr) },
	array_undef  => sub { array_undef(@arr) },
	hash_assign  => sub { hash_assign(@arr) },
	hash_undef   => sub { hash_undef(@arr) },
});

