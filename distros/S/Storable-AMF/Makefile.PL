#!/usr/bin/perl
# vim: ft=perl et ts=8 sw=4 sts=4
use strict;
use ExtUtils::MakeMaker;
use constant MIN_PERL_VERSION => 5.007003;
use Config;

exit if ( @ARGV && $ARGV[0] eq '--stop' );

# Perl 5.7.3 or less not supported
if ( $] < MIN_PERL_VERSION ) {
    print "Perl $] not supported by this module\n";
    exit(0);
}


our %MyModule = (
    PREREQ_PM => { 'XSLoader' => 0.06, },
    ABSTRACT => 'serializing/deserializing AMF0/AMF3 data',
    AUTHOR   => 'Grishaev Anatoliy  <grian@cpan.org>',
    $ExtUtils::MakeMaker::VERSION >= 6.48 ? ( MIN_PERL_VERSION => MIN_PERL_VERSION ) : (),
    $ExtUtils::MakeMaker::VERSION >= 6.46
    ? (
        META_MERGE => {
            resources => {
                'repository' => 'git://github.com/Grian/Storable-AMF.git',
                'license'    => 'http://dev.perl.org/licenses/',
                'homepage'   => 'http://search.cpan.org/dist/Storable-AMF',
                'bugtracker' =>
                  'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Storable-AMF',
            }
        }
      )
    : (),
    $ExtUtils::MakeMaker::VERSION >= 6.31 ? ( LICENSE => 'perl' ) : (),
    NAME         => 'Storable::AMF',
    VERSION_FROM => 'lib/Storable/AMF0.pm',   # finds $VERSION
    INC          => '-I.',                    # e.g., '-I. -I/usr/include/other'
         # Un-comment this if you add C files to link with later:
         # OBJECT            => '$(O_FILES)', # link all the C files too
    OPTIMIZE  => "-O3 -pipe -fomit-frame-pointer ",

);
if ( $Config{osname} =~ /solaris/ or $Config{cc} eq 'cl' ){
    delete $MyModule{OPTIMIZE}
};
if ( $Config{cc} eq 'gcc' ||  $Config{gccversion}) {
    if (0 && $Config{osname}!~m/Win32/i ){
        for ($MyModule{CCFLAGS} ){
                $_ .= ' -Wunused'; 
                $_ .= ' -Wuninitialized'; 
                $_ .= ' -Wall'; 
        #$_  .= ' -Wunreachable-code';
        #$_  .= ' -Wunsafe-loop-optimizations';
        };
    }
    #$MyModule{CCFLAGS} = '-Wunused-variable -Wunused-label -Wunused-function -Wuninitialized -Wunused-value'
}

WriteMakefile(%MyModule);

# -march=opteron -O3 -pipe -fomit-frame-pointer
