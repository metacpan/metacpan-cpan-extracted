use Test::More "no_plan";
use IO::File;
BEGIN {use_ok(Perl6::Slurp)};

my $FILENAME = 'iofile.t.data';

my $desc;
sub TEST { $desc = $_[0] };

my $FH;

$FH = IO::File->new('>'.$FILENAME) or exit;
print $FH map "data $_\n", 1..20;
close $FH;

$FH = IO::File->new($FILENAME) or exit;
my $pos = $FH->tell;

my $data = do { local $/; <$FH> };
$FH->seek(0, 0);
my @data = <$FH>;
$FH->close;

$FH = IO::File->new($FILENAME) or exit;

TEST "scalar slurp from IO::File object ";
$str = slurp $FH;
is $str, $data, $desc;

$FH = IO::File->new($FILENAME) or exit;

TEST "list slurp from IO::File object ";
@str = slurp $FH;
is_deeply \@str, \@data, $desc;

for my $mode (qw( < +< )) {
	$FH = IO::File->new($FILENAME) or exit;

	TEST "scalar slurp from '$mode', IO::File object  ";
	$str = slurp $mode, $FH;
	is $str, $data, $desc;

	TEST "scalar slurp from empty IO::File object";
	$str = slurp $mode, $FH;
	is $str, "", $desc;

	$FH = IO::File->new($FILENAME) or exit;

	TEST "list slurp from '$mode', IO::File object ";
	@str = slurp $mode, $FH;
	is_deeply \@str, \@data, $desc;

	TEST "list slurp from empty IO::File object";
	@str = slurp $mode, $FH;
	is_deeply \@str, [], $desc;
}

unlink $FILENAME;
