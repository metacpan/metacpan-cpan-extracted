use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 24;
use Perlmazing qw(catdir catfile devnull splitpath splitdir catpath abs2rel rel2abs);
use File::Spec ();

my $path_1 = '/usr/bin/perl';
my $path_2 = 'C:\Windows\System32\\';
my $path_3 = 'C:\Windows\System32';

for my $var ($path_1, $path_2, $path_3) {
	for my $sub (qw(catdir catfile devnull splitpath splitdir catpath abs2rel rel2abs)) {
		my $result_1 = dumped (File::Spec->$sub($var));
		my $result_2 = dumped do {
			no strict 'refs';
			&{$sub}($var);
		};
		is $result_1, $result_2, "Same return for $sub in File::Spec and Perlmazing with argument $var";
	}
}