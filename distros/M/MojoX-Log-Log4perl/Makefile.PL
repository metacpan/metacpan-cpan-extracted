use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Log::Log4perl',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/MojoX/Log/Log4perl.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Log/Log4perl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('MIN_PERL_VERSION' => 5.010001)
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0.94,
        'Mojolicious'   => 2.0,
        'Log::Log4perl' => 1.25,
    },
    META_MERGE      => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Log-Log4perl',
            repository  =>      'http://github.com/garu/MojoX-Log-Log4perl',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Log-Log4perl-*' },
);
