use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Nice::Try',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Nice/Try.pm',
    ABSTRACT_FROM       => 'lib/Nice/Try.pm',
    ABSTRACT            => 'A real Try Catch Block Implementation Using Perl Filter',
    PL_FILES            => {},
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM 			=> {
        'strict'		=> 0,
        'warnings'      => 0,
    	'Exporter'		=> '5.73',
    	'Filter::Util::Call' => '1.59',
    	'List::Util'    => '1.33',
    	'PPI'           => '1.270',
    	'Scalar::Util'	=> '1.50',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.16.0,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Nice-Try-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/Nice-Try.git',
                web         => 'https://git.deguest.jp/jack/Nice-Try',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Nice-Try',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
