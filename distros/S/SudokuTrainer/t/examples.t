use strict;
use warnings;

# execute test runs for all Sudoku puzzles in '../Trainer/examples'

use Test::More;

my $trainer = 'script/sudokutrainer.pl';
-e $trainer  or  die "Cannot find $trainer";
my $dirname = 'lib/Games/Sudoku/Trainer/examples';

# CPAN Authors FAQ
use Tk;
my $mw = eval { MainWindow->new };
if (!$mw) { plan( skip_all => "Tk needs a graphical monitor" ); }
use Config;
my $path_to_perl = $Config{perlpath};

my @files = allfilenames($dirname);
@files = grep {/.sudo$/} @files;
@files = grep {-f "$dirname/$_"} @files;
plan tests => scalar @files;

while (my $testfile = shift @files) {
	my $relpath = "$dirname/$testfile";
	next if -d $relpath;
#	my $result = (`perl $trainer --test $relpath`)[-1];
	my $result = (`$path_to_perl $trainer --test $relpath`)[-1];
	chomp $result if defined $result;
    is($result, 'found all', $testfile);
}

# return all file names of a directory (exept '.' and '..')
#
sub allfilenames {
	my ($dirname) = @_;

   -d $dirname  or  die "Cannot find $dirname";
	my $PUZZLEDIR;
	opendir $PUZZLEDIR, $dirname  or  die "Cannot open $dirname";
	my @files = readdir $PUZZLEDIR;
	closedir $PUZZLEDIR  or  die "Cannot close $dirname";
	undef $PUZZLEDIR;

	@files = grep {$_ ne '.'  and  $_ ne '..'} @files;
	return @files;
}

