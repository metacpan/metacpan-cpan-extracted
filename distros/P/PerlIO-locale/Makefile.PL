use 5.008;
use ExtUtils::MakeMaker;
use Config;

unless ($Config{useperlio} eq 'define' and (
        $Config{usesfio} eq 'false' || !defined $Config{usesfio}
)) {
    die <<BARF;
You need perl 5.8.0 or later, configured to use perlio (and not to use sfio).
BARF
}

WriteMakefile(
    AUTHOR => 'Leon Timmermans <leont@cpan.org>, Rafael Garcia-Suarez <rgs@consttype.org>',
    NAME => 'PerlIO::locale',
    PREREQ_PM => {
        'PerlIO::encoding' => 0,
        'Test::More' => 0,
        'I18N::Langinfo' => 0,
    },
    VERSION_FROM => 'locale.pm',
    LICENSE => 'perl',
    clean => { FILES => "foo" },
);
