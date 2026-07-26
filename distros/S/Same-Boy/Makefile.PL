use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my %skip = map { ; "src/Core/$_" => 1 }
    qw(debugger.c sm83_disassembler.c symbol_hash.c cheat_search.c);
my @core = grep { !$skip{$_} } sort glob('src/Core/*.c');

# SameBoy's build normally generates GB_VERSION; supply it directly.
my $GB_VERSION = '1.0.3';

my $extra = qq{-std=gnu11 -DGB_INTERNAL -DNDEBUG -DGB_VERSION=\\"$GB_VERSION\\" }
          . qq{-DGB_DISABLE_DEBUGGER -DGB_DISABLE_CHEAT_SEARCH};

my %WriteMakefileArgs = (
    NAME             => 'Same::Boy',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Same/Boy.pm',
    ABSTRACT_FROM    => 'lib/Same/Boy.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro            => { TARFLAGS => '--format=ustar -c -v -f' },
    CCFLAGS          => join(' ', $Config{ccflags} // (), $extra),
    INC              => '-Isrc -Isrc/Core',
    XS               => { 'Boy.xs' => 'Boy.c' },
    C                => ['Boy.c', @core],
    OBJECT           => join(' ', 'Boy$(OBJ_EXT)',
                                  map { (my $o = $_) =~ s/\.c$/\$(OBJ_EXT)/; $o } @core),
    EXE_FILES        => ['bin/termboy.pl'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Same-Boy-* Boy.c Boy.o Boy.bs src/Core/*.o' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

# MakeMaker's default .c$(OBJ_EXT) suffix rule compiles $*.c without -o $@,
# so objects for sources in src/Core/ would land in the top dir instead of
# next to their source (where OBJECT expects them). Emit explicit per-file
# rules that pass -o $@. Explicit targets keep this portable across makes.
sub MY::postamble {
    my $rules = "\n";
    for my $c (@core) {
        (my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/;
        $rules .= "$o : $c\n"
                . "\t\$(CCCMD) \$(CCCDLFLAGS) \"-I\$(PERL_INC)\" "
                . "\$(PASTHRU_DEFINE) \$(DEFINE) -o \$\@ $c\n\n";
    }
    return $rules;
}
