use 5.018;
use Config;
use Panda::Install;

if ($^O eq 'MSWin32' && $Config{myuname} =~ /strawberry/ && !$ENV{TEST_FULL}) {
    my $out = `c++ -v 2>&1`;
    if ($out =~ /--enable-sjlj-exceptions/) {
        die "***************************************************************\n".
            "You are using c++ compiler with SJLJ exceptions enabled.\n".
            "It makes it impossible to use C++ exceptions and perl together.\n".
            "You need to use compiler with DWARF2 or SEH exceptions configured.\n".
            "If you are using Strawberry Perl, install Strawberry 5.26 or higher\n".
            "where they use mingw with SEH exceptions.\n".
            "***************************************************************\n";
    }
}

my $ivbits = $Config{ivsize}*8;

write_makefile(
    NAME          => 'Panda::XS',
    VERSION_FROM  => 'lib/Panda/XS.pm',
    ABSTRACT_FROM => 'lib/Panda/XS.pod',
    CPLUS         => 11,
    SRC           => ['src', $ENV{TEST_FULL} ? 't/src' : ()],
    INC           => '-Isrc',
    DEFINE        => $ENV{TEST_FULL} ? '-DTEST_FULL' : '',
    TYPEMAPS      => ['typemap', "typemap$ivbits", 'testmap'],
    BIN_DEPS      => 'CPP::panda::lib',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {
            'src'                    => '/',
            'src/algorithm_perlsafe' => '/algorithm_perlsafe',
        },
        XSOPT    => '-hiertype',
        TYPEMAPS => {
            'typemap'        => '',
            "typemap$ivbits" => '',
        },
    },
    MIN_PERL_VERSION => '5.18.0', # required for GV_SUPER
    CCFLAGS          => '-Wall -Wextra',
    OPTIMIZE         => '-g0 -O2',
    #CC => 'clang++',
);
