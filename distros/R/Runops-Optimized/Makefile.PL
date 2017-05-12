use 5.014;
use Config;
use ExtUtils::MakeMaker;

# The platforms sljit supports. Of things CPAN testers seem to test this is
# basically everything but SPARC...
unless($Config{archname} =~ /i[3456]86|x86_64|darwin|ppc|mips/i) {
    warn "This module requires x86/x86_64/arm/ppc/mips.\n";
    exit 0;
}

if($Config{usemultiplicity}) {
    warn "This module only works on non-multiplicity perls for now\n";
    exit 0;
}

my $debug = "";
s/^DEBUG=(.*)//i && ($debug = $1 ? "-DDEBUG -DSLJIT_VERBOSE" : "") for @ARGV;

WriteMakefile(
    NAME          => 'Runops::Optimized',
    AUTHOR        => 'David Leadbeater <dgl@dgl.cx>',
    VERSION_FROM  => 'lib/Runops/Optimized.pm',
    ABSTRACT_FROM => 'lib/Runops/Optimized.pm',
    LICENSE       => 'perl',
    META_MERGE    => {
        resources => {
            repository => 'https://github.com/dgl/Runops-Optimized'
        }
    },
    CCFLAGS       => "-DSLJIT_CONFIG_AUTO $debug",
    INC           => "-Isljit",
    OBJECT        => "Optimized.o unroll.o sljit/sljitLir.o",
);

sub MY::postamble {<<'EOF';
# MakeMaker doesn't have a correct rule for code in subdirectories

Optimized.c: copy-sljit

copy-sljit: sljit/sljitLir.o
	cp sljitLir.o sljit
EOF
}
