use strict;
use warnings;

use Config;
use File::Spec;
my $sep = $Config{path_sep};

my $rakudo_dir = $ENV{RAKUDO_DIR};

my @libs = $ENV{PERL6LIB} ? split (/$sep/, $ENV{PERL6LIB}) : ();
$ENV{PERL6LIB} = join $sep, 
	File::Spec->catdir('blib', 'lib'), $rakudo_dir, @libs;

my $parrot = File::Spec->catfile($ENV{PARROT_DIR}, 'parrot') . ($^O eq "MSWin32" ? '.exe' : '');
my $rakudo = File::Spec->catfile($ENV{RAKUDO_DIR}, 'perl6.pbc');

(my $file = $0) =~ s/t$/t6/;
system "$parrot $rakudo $file";

