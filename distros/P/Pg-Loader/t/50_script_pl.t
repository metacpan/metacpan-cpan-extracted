use Test::More 'no_plan';
use Expect;

my $dir     = $ENV{PWD} =~ m#\/t$#  ? '../script' : 'script';
my $tgt     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

my @pl    = <$dir/*.pl>;

$Expect::Log_Stdout = 0;
my $e;
for (@pl) {
	$e = new Expect;
	ok $e->spawn( $_, '-h') or die $!;
	note $_ ;
	ok $e->expect(2,'Display documentation'),'-h' ;
	$e->soft_close;

	$e = new Expect;
	ok $e->spawn( $_, "--version") or die $!;
	ok $e->expect(2,'-re',qr/\d.\d{2}/), 'version' ;
	$e->soft_close;
}
