use strict;
use XS::Install;

my %params = (
    NAME          => 'Protocol::HTTP',
    CPLUS         => 14,
    BIN_DEPS      => ['URI::XS', 'Date', 'Export::XS', 'XS::libboost::mini', 'XS::librangeV3'],
    TEST_REQUIRES => {'Test::More' => 0, 'Test::Fatal' => 0 },
    DEFINE        => $ENV{DEBUG} ? '-DDEBUG' : '',
    SRC           => ['src'],
    INC           => '-Isrc',
    LINK          => '-lz',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra -Wno-implicit-fallthrough -Wno-unused-const-variable',
    test          => {
        SRC                  => 't',
        RECURSIVE_TEST_FILES => 1,
        BIN_DEPS             => 'Test::Catch',
    },
);

if ($ENV{DEV}) {
    my $postamble = '';
    my $gentype = "-G2";
    for (qw/MessageParser.rl CookieParser.rl CookieStorage.rl/) {
        my $file = "src/panda/protocol/http/$_";
        my $cfile = $file;
        $cfile =~ s/\.rl/.cc/;
        $postamble .= "parser : $cfile\n\n";
        $postamble .= "$cfile : $file\n".
                      "\t ragel -C $gentype $file -o $cfile\n\n";
    }
    $params{postamble} .= $postamble;
}

write_makefile(%params);
