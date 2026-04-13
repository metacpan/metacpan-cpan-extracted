use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Collect all bundled djbsort C source files
my @c_sources = glob("djbsort_src/*.c");
my @objects = map { s/\.c$/.o/r } @c_sources;

# Add the XS-generated object
push @objects, 'DJB.o';

WriteMakefile(
    NAME          => 'Sort::DJB',
    VERSION_FROM  => 'lib/Sort/DJB.pm',
    ABSTRACT_FROM => 'lib/Sort/DJB.pm',
    AUTHOR        => 'djbsort XS bindings',
    LICENSE       => 'gpl_2',
    MIN_PERL_VERSION => '5.010',
    INC           => '-Idjbsort_src',
    OBJECT        => join(' ', @objects),
    OPTIMIZE      => '-O2',
    CCFLAGS       => "$Config{ccflags} -fwrapv",
    XSOPT         => '-noprototypes',
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://sorting.cr.yp.to/',
            repository => {
                type => 'git',
                url  => 'https://sorting.cr.yp.to/',
                web  => 'https://sorting.cr.yp.to/',
            },
        },
        prereqs => {
            runtime => {
                requires => {
                    'perl'     => '5.010',
                    'Exporter' => '0',
                    'XSLoader' => '0',
                },
            },
            test => {
                requires => {
                    'Test::More' => '0.88',
                },
            },
        },
    },
);

# Custom rule to compile djbsort_src/*.c files
sub MY::postamble {
    my $rules = '';
    for my $c (glob("djbsort_src/*.c")) {
        (my $o = $c) =~ s/\.c$/.o/;
        $rules .= <<"RULE";

$o: $c
\t\$(CC) -c \$(PASTHRU_INC) \$(INC) \$(CCFLAGS) \$(OPTIMIZE) \$(CCCDLFLAGS) \$(DEFINE) -o $o $c

RULE
    }
    return $rules;
}
