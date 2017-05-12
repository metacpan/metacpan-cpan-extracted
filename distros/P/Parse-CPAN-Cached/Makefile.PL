use ExtUtils::MakeMaker;
use 5.008;
my $module_file = 'lib/Parse/CPAN/Cached.pm';
WriteMakefile(
    NAME          => 'Parse::CPAN::Cached',
    AUTHOR        => 'Sysmon <sysmonblog@googlemail.com>',
    ABSTRACT_FROM => $module_file,
    VERSION_FROM  => $module_file,
    PREREQ_PM     => {
        Moose                 => 0,
        CPAN::Mini            => 0.573,
        Path::Class           => 0.16,
        App::Cache            => 0.36,
        Parse::CPAN::Packages => 2.30,
        Parse::CPAN::Authors  => 2.27,
        Parse::CPAN::Whois    => 0,
        Test::Most            => 0, # XXX: should really be a build_requires
    },
    META_MERGE      => {
        resources => {
            license     =>      'http://www.perlfoundation.org/artistic_license_2_0',
            homepage    =>      'http://sysmonblog.co.uk/',
            repository  =>      'http://github.com/minty/parse-cpan-cached/tree/master',
        },
    },
);
