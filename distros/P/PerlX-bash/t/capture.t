use Test::Most 0.25;

use PerlX::bash;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;


my $proglet = 'print "A 1\nB  2\n\nC 3\n"';

# capture as string
my $str = bash \string => "$^X -e '$proglet'";
is $str, "A 1\nB  2\n\nC 3\n", "bash \\string captures to scalar";

# capture as lines
my @lines = bash \lines => "$^X -e '$proglet'";
cmp_deeply [@lines], ["A 1", "B  2", "", "C 3"], "bash \\lines captures to array";

# in scalar context, you just get the first line
my $line = bash \lines => "$^X -e '$proglet'";
is $line, "A 1", "bash \\lines in scalar context captures first line";

# capture as words
my @words = bash \words => "$^X -e '$proglet'";
cmp_deeply [@words], [qw< A 1 B 2 C 3 >], "bash \\words captures to array";

# capture as words but use $IFS
{
	local $ENV{IFS} = ":\n";
	my @words = bash \words => 'echo $PATH';		# this is the $PATH env var (note single quotes)
	cmp_deeply [@words], [split(':', $ENV{PATH})], 'bash \\words uses $IFS';
}

# likewise for scalar context with words
my $word = bash \words => "$^X -e '$proglet'";
cmp_deeply $word, 'A', "bash \\words in scalar context captures first word";


# check for errors
throws_ok { bash \bmoogle => 'exit' } qr/unrecognized capture specification/, 'proper error on unknown';
throws_ok { bash \string => \lines => 'exit' } qr/multiple capture specifications/, 'proper error on multiple';


done_testing;
