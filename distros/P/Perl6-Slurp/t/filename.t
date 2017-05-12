use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $FILENAME = 'filename.t.data';

my $desc;
sub TEST { $desc = $_[0] };

open FH, '>'.$FILENAME or exit;
print FH map "data $_\n", 1..20;
close FH;

open FH, $FILENAME or exit;
my $pos = tell *FH;

my $data = do { local $/; <FH> };
seek *FH, 0, 0;
my @data = <FH>;
close FH;

TEST "scalar slurp from $FILENAME in main";
$str = slurp $FILENAME;
is $str, $data, $desc;

TEST "list slurp from $FILENAME in main";
@str = slurp $FILENAME;
is_deeply \@str, \@data, $desc;

for my $mode (qw( < +< )) {
	TEST "scalar slurp from '${mode}$FILENAME' in main";
	$str = slurp "${mode}$FILENAME";
	is $str, $data, $desc;

	TEST "scalar slurp from '$mode $FILENAME' in main";
	$str = slurp "$mode $FILENAME";
	is $str, $data, $desc;

	TEST "scalar slurp from '$mode', $FILENAME' in main";
	$str = slurp $mode, $FILENAME;
	is $str, $data, $desc;

	TEST "list slurp from '${mode}$FILENAME' in main";
	@str = slurp "${mode}$FILENAME";
	is_deeply \@str, \@data, $desc;

	TEST "list slurp from '$mode $FILENAME' in main";
	@str = slurp "$mode $FILENAME";
	is_deeply \@str, \@data, $desc;

	TEST "list slurp from '$mode', $FILENAME in main";
	@str = slurp $mode, $FILENAME;
	is_deeply \@str, \@data, $desc;
}

TEST "scalar slurp from \$_ in main";
for ($FILENAME) {
	$str = slurp;
	is $str, $data, $desc;
}

local $/;
@ARGV = ($FILENAME, $FILENAME);

TEST "scalar slurp from ARGV in main";
$str = slurp;
is $str, $data.$data, $desc;

unlink $FILENAME;
