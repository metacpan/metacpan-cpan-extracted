# Exit if we're on Windows. This should play nice for CPAN testers
my $running_on_windows = $^O eq 'MSWin32' || $^O eq 'cygwin';
die qq(OS unsupported\n) if $running_on_windows;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Parse-Debian-PackageDesc',
    'VERSION_FROM'      => 'lib/Parse/Debian/PackageDesc.pm',
    'PREREQ_PM'         => {
                            'Test::Deep' => 0.093,
                           },
    ABSTRACT_FROM       => 'lib/Parse/Debian/PackageDesc.pm',
    AUTHOR              => 'Esteban Manchado Velázquez <estebanm@opera.com>',
);
