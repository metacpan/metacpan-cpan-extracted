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

my %params = (
    NAME          => 'Panda::Lib',
    VERSION_FROM  => 'lib/Panda/Lib.pm',
    ABSTRACT_FROM => 'lib/Panda/Lib.pod',
    PREREQ_PM     => {'Panda::Export' => 0, 'Time::HiRes' => 0},
    TEST_REQUIRES => {'Test::Fatal' => 0, 'JSON::XS' => 0},
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    TYPEMAPS      => ['t/src/testmap'],
    BIN_DEPS      => 'Panda::XS',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
        TYPEMAPS => {'typemap' => ''},
    },
    CCFLAGS  => '-Wall -Wextra',
    OPTIMIZE  => '-g0 -O2',
    #CC => 'clang++',
);

if ($ENV{TEST_FULL}) {
    ($params{DEFINE}||='') .= ' -DTEST_FULL';
    push @{$params{SRC}||=[]}, 't/src';
}

write_makefile(%params);

