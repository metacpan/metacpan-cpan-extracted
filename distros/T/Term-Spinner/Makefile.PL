use inc::Module::Install;

name           'Term-Spinner';
all_from       'lib/Term/Spinner.pm';

requires       'perl'       => 5.006_000;
requires       'Moose'      => '0.21';
build_requires 'Test::More' => '0.47';

# Rebuild README for maintainers
if(-e 'MANIFEST.SKIP') {
    system("pod2text lib/Term/Spinner.pm > README");
}

auto_install;
WriteAll;
