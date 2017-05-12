# -*- perl -*-

require 5.008;

use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#
#   This module requires a minimum Perl version of 5.8.0
#   Please upgrade!
#
#######################################
EOD

print "\nConfiguring PPI::HTML::CodeFolder...\n
";

use Config;
my @executables = ();
foreach my $src (qw(mkhtmlcf)) {
    open  SCRIPT,       ">$src.pl" or die "Can't create $src.pl: $!";
    open  SOURCE,        "bin/$src" or die "Missing bin/$src";
    chmod 0755,          "$src.pl";
    push @executables, "$src.pl";
    print SCRIPT "$Config{startperl}\n";
    print SCRIPT $_
        while (<SOURCE>);

    close SCRIPT;
    close SOURCE;
}

my %prereqs = (
    'PPI' => '1.199',
    'PPI::HTML' => '1.07',
    'Module::Mapper' => '1.01',
);

my %opts = (
    'NAME' => 'PPI::HTML::CodeFolder',
    'VERSION_FROM' => 'lib/PPI/HTML/CodeFolder.pm',
    'dist'         => {
        'DIST_DEFAULT' => 'all tardist',
        'SUFFIX'       => 'gz',
        'COMPRESS'     => 'gzip -9vf'
    },
    'EXE_FILES'    => \@executables,
    'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
    'ABSTRACT'     => "PPI::HTML subclass for code folding and compression)",
    'PREREQ_PM'    => \%prereqs,
);

ExtUtils::MakeMaker::WriteMakefile(%opts);
