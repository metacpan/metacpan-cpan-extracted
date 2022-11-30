use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %params = (
    NAME => "RL",
    VERSION_FROM => "lib/RL.pm",
    ABSTRACT_FROM  => "lib/RL.pm",
    LIBS => "-lreadline",
    DEFINE => "",
    INC => "",
    EXE_FILES => ["bin/pl"],
    AUTHOR => "Jacob Gelbman <gelbman\@gmail.com>",
    clean => {FILES => "RL-*.tar.gz *.bak"},
);

# MacOS needs to find EXTERN.h and other header files to compile the .xs file.
# It used to just work, but now it doesn't. The closest thing in %Config would
# be the archlib key which on my system is:
#
#     /System/Library/Perl/5.30/darwin-thread-multi-2level
#
# the include path needs to be:
#
#     /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Perl/5.30/darwin-thread-multi-2level/CORE
#
# I also found that for installing on MacOS, you need the most recent version of
# ExtUtils::MakeMaker installed. otherwise the -lreadline part never gets
# inserted into the Makefile.
if ($Config{archlib}) {
    my $file = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/$Config{archlib}/CORE";
    if (-e $file) {
        $params{INC} .= " -I$file";
    }
}

my @requires = (
    "strict" => 0,
    "warnings" => 0,
    "Data::Dumper" => 0,
);

my @test_requires = (
    "Test::More" => 0.88,
);

if ($mm_ver < 6.64) {
    $params{PREREQ_PM} = {@requires, @test_requires};
}
else {
    $params{PREREQ_PM} = {@requires};
    $params{TEST_REQUIRES} = {@test_requires};
}

if ($mm_ver >= 6.31) {
    $params{LICENSE} = "perl";
}

if ($mm_ver >= 6.48) {
    $params{MIN_PERL_VERSION} = 5.006;
}

if ($mm_ver > 6.45) {
    $params{META_MERGE} = {
        "meta-spec" => {version => 2},
        resources => {
            repository => {
                type => "git",
                web => "https://github.com/zorgnax/perlreadline",
                url => "https://github.com/zorgnax/perlreadline.git",
            }
        }
    };
}

WriteMakefile(%params);

