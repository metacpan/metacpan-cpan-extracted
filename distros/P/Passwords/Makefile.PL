use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Passwords',
    AUTHOR           => q{Günter Grodotzki <guenter@perlhipster.com>},
    VERSION_FROM     => 'lib/Passwords.pm',
    ABSTRACT_FROM    => 'lib/Passwords.pm',
    LICENSE          => 'perl_5',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'strict' => 0,
        'warnings' => 0,
        'autodie' => 0,
        'utf8' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'strict' => 0,
        'warnings' => 0,
        'autodie' => 0,
        'utf8' => 0,
    },
    PREREQ_PM => {
        'strict' => 0,
        'warnings' => 0,
        'autodie' => 0,
        'utf8' => 0,
        'Carp' => 0,
        'Crypt::Eksblowfish::Bcrypt'  => '0.009',
        'Data::Entropy::Algorithms'   => '0.007',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Passwords-*' },
    ($ExtUtils::MakeMaker::VERSION >= 6.46 ?
      (META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources => {
          license => 'http://dev.perl.org/licenses/',
          homepage => 'http://www.perlhipster.com/p5-passwords',
          bugtracker => {
            web    => 'https://github.com/lifeofguenter/p5-passwords/issues',
            mailto => 'bugs@perlhipster.com',
          },
          repository => {
            type => 'git',
            url  => 'git://github.com/lifeofguenter/p5-passwords.git', 
            web  => 'https://github.com/lifeofguenter/p5-passwords'
          },
        }
      }) : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48 ?
      (MIN_PERL_VERSION => 5.010) : ()),
);
