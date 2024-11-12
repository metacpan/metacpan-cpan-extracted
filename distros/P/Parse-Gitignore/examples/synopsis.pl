#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Parse::Gitignore;
chdir "$Bin/../" or die $!;
my $gitignore = Parse::Gitignore->new (".gitignore");
for my $file ('examples/synopsis.pl', 'MANIFEST') {
    if ($gitignore->ignored ($file)) {
	print "$file is ignored.\n";
    }
    else {
	print "$file is not ignored.\n";
    }
}
