use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile 0.06;

WriteMakefile(
    NAME          => 'Perl::PrereqScanner::NotQuiteLite',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Perl/PrereqScanner/NotQuiteLite.pm',
    ABSTRACT_FROM => 'lib/Perl/PrereqScanner/NotQuiteLite.pm',
    LICENSE       => 'perl',
    EXE_FILES => ['bin/scan-perl-prereqs-nqlite'],
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Perl-PrereqScanner-NotQuiteLite',
        },
    },
    test => {TESTS => "t/*.t t/*/*.t t/*/*/*.t"},
);
