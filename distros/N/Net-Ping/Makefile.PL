use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => 'Net::Ping',
    AUTHOR => [
        'Steve Peters <steve@fisharerojo.org>',
        'Reini Urban <rurban@cpan.org>',
        'Matthew Musgrove <mr.muskrat@gmail.com>',
        'Karl Williamson <khw@cpan.org>',
        'Brian Fraser <fraserbn@gmail.com>',
        'Mark Gardner <mjgardner@cpan.org>',
    ],
    VERSION_FROM  => 'lib/Net/Ping.pm',
    ABSTRACT_FROM => 'lib/Net/Ping.pm',
    PL_FILES      => { 'README.md.PL' => 'README.md' },
    PREREQ_PM     => {
        'Socket'      => '2.007',
        'Test::More'  => 0,
        'Time::HiRes' => 0,
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Text::Template'      => '1.10',
    },
    INSTALLDIRS => 'perl',
    dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES => 'Net-Ping-*' },
    test       => { TESTS => 't/*.t t/zz_legacy/*.t', },
    SIGN       => 1,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/rurban/net-ping.git',
                web  => 'https://github.com/rurban/net-ping',
            },
        },
    },
);

package MY;

sub depend {
  "
release : dist
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags
"
}

