use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $desc;
sub TEST { $desc = $_[0] };

@data = map "data $_\n", 1..20;
$data = join "", @data;

TEST "scalar slurp from string";
$str = slurp \$data;
is $str, $data, $desc;

TEST "list slurp from string ";
@str = slurp \$data;
is_deeply \@str, \@data, $desc;

for my $mode (qw( < +< )) {
	TEST "scalar slurp from '$mode', string  ";
	$str = slurp $mode, \$data;
	is $str, $data, $desc;

	TEST "list slurp from '$mode', string ";
	@str = slurp $mode, \$data;
	is_deeply \@str, \@data, $desc;
}
