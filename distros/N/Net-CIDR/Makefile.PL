use ExtUtils::MakeMaker;
# $Revision: 1.2 $
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'        => 'Sam Varshavchik <sam@email-scan.com>',
    'ABSTRACT_FROM' => 'lib/Net/CIDR.pm',
    'NAME'          => 'Net::CIDR',
    'VERSION_FROM'  => 'lib/Net/CIDR.pm',
    'PREREQ_PM'     => { 'Carp' => 0 },
    'LICENSE'       => 'perl',
    'PL_FILES'      => { 'Net-CIDR.spec.PL' => 'Net-CIDR.spec' },

    'TEST_REQUIRES' => {
        'Test::More'            => '1',
        },

    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        keywords    => ['network'],
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/svarshavchik/Net-CIDR',
                web  => 'https://github.com/svarshavchik/Net-CIDR',
                },
            bugtracker => {
                web    => "https://github.com/svarshavchik/Net-CIDR/issues",
                },
            homepage => 'https://github.com/svarshavchik/Net-CIDR',
            },
        },
);
