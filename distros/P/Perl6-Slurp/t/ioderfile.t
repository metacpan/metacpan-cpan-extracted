use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $FILENAME = 'ioderfile.t.data';

package IO::DerFile;
use base 'IO::File';

package main;

my $desc;
sub TEST { $desc = $_[0] };

my $FH;

$FH = IO::DerFile->new('>'.$FILENAME) or exit;
print $FH map "data $_\n", 1..20;
close $FH;

$FH = IO::DerFile->new($FILENAME) or exit;
my $pos = $FH->tell;

my $data = do { local $/; <$FH> };
$FH->seek(0, 0);
my @data = <$FH>;
$FH->close;

$FH = IO::DerFile->new($FILENAME) or exit;

TEST "scalar slurp from IO::DerFile object ";
$str = slurp $FH;
is $str, $data, $desc;

$FH = IO::DerFile->new($FILENAME) or exit;

TEST "list slurp from IO::DerFile object ";
@str = slurp $FH;
is_deeply \@str, \@data, $desc;

for my $mode (qw( < +< )) {
	$FH = IO::DerFile->new($FILENAME) or exit;

	TEST "scalar slurp from '$mode', IO::DerFile object  ";
	$str = slurp $mode, $FH;
	is $str, $data, $desc;

	TEST "scalar slurp from empty IO::DerFile object";
	$str = slurp $mode, $FH;
	is $str, "", $desc;

	$FH = IO::DerFile->new($FILENAME) or exit;

	TEST "list slurp from '$mode', IO::DerFile object ";
	@str = slurp $mode, $FH;
	is_deeply \@str, \@data, $desc;

	TEST "list slurp from empty IO::DerFile object";
	@str = slurp $mode, $FH;
	is_deeply \@str, [], $desc;
}

unlink $FILENAME;
