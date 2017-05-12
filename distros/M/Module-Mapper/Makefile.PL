# -*- perl -*-

#require 5.008;

use strict;
require ExtUtils::MakeMaker;

print "\nConfiguring Module::Mapper...\n
";

use Config;
my @executables = ();
foreach my $src (qw(mapmodule)) {
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

my %opts = (
    'NAME' => 'Module::Mapper',
    'VERSION_FROM' => 'lib/Module/Mapper.pm',
    'dist'         => {
        'DIST_DEFAULT' => 'all tardist',
        'SUFFIX'       => 'gz',
        'COMPRESS'     => 'gzip -9vf'
    },
    'EXE_FILES'    => \@executables,
    'AUTHOR'       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
    'ABSTRACT'     => 'Find source for module and optionally map to another directory',
    'PREREQ_PM'    => {},
);

ExtUtils::MakeMaker::WriteMakefile(%opts);
