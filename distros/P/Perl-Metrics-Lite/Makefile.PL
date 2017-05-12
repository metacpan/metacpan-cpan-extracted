sub readme_markdown_from {
    warn
        "You need to install Module::Install::ReadmeMarkdownFromPod  to generate README";
}

sub author_requires {
    warn
        "You need to install Module::Install::AuthorRequires to install modules author requires";
}
sub author_tests        { }
sub auto_set_repository { }

use inc::Module::Install;

name 'Perl-Metrics-Lite';
perl_version  '5.005';
all_from 'lib/Perl/Metrics/Lite.pm';
readme_markdown_from 'lib/Perl/Metrics/Lite.pm';

requires(
    'Carp'              => 0,
    'File::Basename'    => 0,
    'File::Find'        => 1.01,
    'File::Spec'        => 0,
    'Getopt::Long'      => 0,
    'IO::File'          => 1.14,
    'Readonly'          => 1.03,
    'PPI'               => 1.205,
    'Pod::Usage'        => 0,
    'Module::Pluggable' => 0,
    'Text::ASCIITable'  => 0
);
test_requires(
    'Test::More'           => 0.94,
    'Test::LoadAllModules' => 0.021
);

install_script('bin/measureperl');
install_script('bin/measureperl-checkstyle');
auto_include_deps;
WriteAll;
