use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $FILENAME = 'lexfilehandle.t.data';

my $desc;
sub TEST { $desc = $_[0] };

my $FH;

undef $FH; open $FH, '>'.$FILENAME or exit;
print $FH map "data $_\n", 1..20;
close $FH;

undef $FH; open $FH, $FILENAME or exit;
my $pos = tell $FH;

my $data = do { local $/; <$FH> };
seek $FH, 0, 0;
my @data = <$FH>;
close $FH;

undef $FH; open $FH, $FILENAME or exit;

TEST "scalar slurp from lexical filehandle ";
$str = slurp $FH;
is $str, $data, $desc;

undef $FH; open $FH, $FILENAME or exit;

TEST "list slurp from lexical filehandle ";
@str = slurp $FH;
is_deeply \@str, \@data, $desc;

for my $mode (qw( < +< )) {
	undef $FH; open $FH, $FILENAME or exit;

	TEST "scalar slurp from '$mode', lexical filehandle  ";
	$str = slurp $mode, $FH;
	is $str, $data, $desc;

	TEST "scalar slurp from empty lexical filehandle";
	$str = slurp $mode, $FH;
	is $str, "", $desc;

	undef $FH; open $FH, $FILENAME or exit;

	TEST "list slurp from '$mode', lexical filehandle ";
	@str = slurp $mode, $FH;
	is_deeply \@str, \@data, $desc;

	TEST "list slurp from empty lexical filehandle";
	@str = slurp $mode, $FH;
	is_deeply \@str, [], $desc;
}

unlink $FILENAME;
