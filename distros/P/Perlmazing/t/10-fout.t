use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing qw(fout slurp);
use utf8;

my $filename = 'fout_test.txt';
unlink $filename;

is -e $filename, undef, "Test file doesn't exist.";
is -f $filename, undef, "Test file doesn't exist.";

my $data = 'Hello world! 😀';
$data .= "\n\n";
$data .= 'This is a test. ¡Estamos probándolo!';
$data .= "\r\n";
$data .= 'テスト終了。';

fout $filename, $data, 'utf8';

is -e $filename, 1, 'fout created a file';
is -f $filename, 1, 'fout created a file';

my $written_data = slurp $filename, 'utf8';

is $data eq $written_data, 1, 'Written data is a match.';