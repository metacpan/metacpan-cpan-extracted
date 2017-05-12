use Test::More 'no_plan';
use Expect;

my $dir     = $ENV{PWD} =~ m#\/t$#  ? '../script' : 'script';
my $tgt     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

my @pl    = <$dir/pcurse>;


$Expect::Log_Stdout = 0;
my $e;
for (@pl) {
	$e = new Expect;
	ok $e->spawn( $_, '--help') or die $!;
	note $_ ;
	ok $e->expect(2,'Thank you for flying Pcurse!'),'--help' ;
	$e->before; exit;;
	$e->soft_close;

	$e = new Expect;
	ok $e->spawn( $_, "--version") or die $!;
	ok $e->expect(2,'-re',qr/version 0.\d{2}/), 'version' ;
	$e->soft_close;
}
