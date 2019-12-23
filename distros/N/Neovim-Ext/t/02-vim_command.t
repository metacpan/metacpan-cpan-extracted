#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use File::Slurper qw/read_text/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my ($fh, $filename) = tempfile();
close $fh;

$vim->command('new');
$vim->command("edit $filename");
$vim->input ("\r");
$vim->command("normal itesting\npython\napi");
$vim->command("w");
ok -f $filename;

my $le = "\n";
if ($^O eq 'MSWin32')
{
	$le = "\r\n";
}

is read_text($filename), join ($le, 'testing', 'python', 'api', '');
unlink $filename;

done_testing();
