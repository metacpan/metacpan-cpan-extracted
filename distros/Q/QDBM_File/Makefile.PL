use strict;
use warnings;
use ExtUtils::MakeMaker;

my $INC  = '-I.';
my $LIBS = '-lqdbm';
my $DEFINE;

$| = 1;

for (;;) {

    print "Please specify qdbm library link type:\n\n";
    print "  1> static lib\n";
    print "  2> dynamic lib (dll)\n";
    print "\n";
    print "libqdbm link type: [1]: ";

    my $in = <STDIN>;
    chomp($in);

    if ($in eq "" or $in =~ /^[1s]/i) {
        print "\nlibqdbm linked as static lib (QDBM_STATIC defined).\n\n";
        $DEFINE = '-DQDBM_STATIC';
        last;
    }
    elsif ($in =~ /^[2d]/i) {
        print "\nlibqdbm linked as dynamic lib.\n\n";
        $DEFINE = '';
        last;
    }

}

WriteMakefile(
    NAME          => 'QDBM_File',
    AUTHOR        => 'Toshiyuki Yamato <toshiyuki.yamato@gmail.com>',
    VERSION_FROM  => 'lib/QDBM_File.pm',
    ABSTRACT_FROM => 'lib/QDBM_File.pm',
    INC           => $INC,
    LIBS          => [$LIBS],
    DEFINE        => $DEFINE,
    XSOPT         => '-noprototypes',
    (
        (ExtUtils::MakeMaker->VERSION() gt '6.30')
            ? ('LICENSE' => 'perl')
            : ()
    ),
    PREREQ_PM => {
        'Test::More' => 0,
    },
);
