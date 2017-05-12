{ require 5.008 };
use strict;
use warnings FATAL => 'all';

use if $] < 5.014, "Devel::CallChecker";
use if $] < 5.014, "IO::File";

write_header('callchecker0.h', &Devel::CallChecker::callchecker0_h) if $] < 5.014;

sub write_header {
    my ($header, $content) = @_;
    my $fh = IO::File->new($header, 'w') or die $!;
    $fh->print($content) or die $!;
    $fh->close or die $!;
}

1;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Params::Lazy',
    AUTHOR           => q{Brian Fraser <fraserbn@gmail.com>},
    VERSION_FROM     => 'lib/Params/Lazy.pm',
    ABSTRACT_FROM    => 'lib/Params/Lazy.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        "Devel::CallChecker" => 0,
        "IO::File" => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.98,
    },
    PREREQ_PM => {
        "Devel::CallChecker" => 0,
        "XSLoader" => 0,
        "strict" => 0,
        "warnings" => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Params-Lazy-* callchecker0.h' },
    test  => {
        TESTS => "t/*.t"
    }
);
