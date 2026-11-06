use strict;
use warnings;
use ExtUtils::MakeMaker;

my %pm = (
    'lib/Perl/CodeMap.pm' => '$(INST_LIB)/Perl/CodeMap.pm',
);
for my $asset (qw(template.html app.css app.js prism-core.min.js prism-perl.min.js PRISM-LICENSE.txt)) {
    $pm{"lib/Perl/CodeMap/assets/$asset"} = "\$(INST_LIB)/Perl/CodeMap/assets/$asset";
}
WriteMakefile(
    NAME => 'Perl::CodeMap',
    VERSION_FROM => 'lib/Perl/CodeMap.pm',
    ABSTRACT => 'Offline Perl dependency visualization and source explorer',
    AUTHOR => 'Scott Muller <scott@21h.io>',
    LICENSE => 'mit',
    MIN_PERL_VERSION => '5.020',
    EXE_FILES => ['bin/perl-codemap'],
    PREREQ_PM => {
        'Cwd' => 0,
        'Encode' => 0,
        'ExtUtils::MakeMaker' => 0,
        'File::Basename' => 0,
        'File::Find' => 0,
        'File::Spec' => 0,
        'Getopt::Long' => 0,
        'IPC::Open3' => 0,
        'JSON::PP' => 0,
        'Pod::Usage' => 0,
        'Symbol' => 0,
    },
    TEST_REQUIRES => {
        'Pod::Simple' => 0,
        'Test::More' => 0,
    },
    META_MERGE => {
        recommends => { PPI => '1.291' },
        resources => {
            homepage => 'https://github.com/interrupt21h/perl-codemap',
            repository => { type => 'git', url => 'https://github.com/interrupt21h/perl-codemap.git', web => 'https://github.com/interrupt21h/perl-codemap' },
            bugtracker => { web => 'https://github.com/interrupt21h/perl-codemap/issues' },
        },
    },
    clean => { FILES => 'perl-code-map.html perl-code-map.json' },
);
