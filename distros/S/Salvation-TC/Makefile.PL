use ExtUtils::MakeMaker;
use Devel::PPPort;
use Config;

Devel::PPPort::WriteFile();

WriteMakefile (
    NAME => 'Salvation::TC',
    VERSION_FROM => 'lib/Salvation/TC.pm',
    OBJECT => 'helper.o tokenizer.o TC.o',
    CCFLAGS => $Config{ 'ccflags' } . ' -std=c99',
    ABSTRACT => 'Yet another type constraint system',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        boolean => 0,
        'Class::Inspector' => 0,
        'Devel::PartialDump' => 0,
        'List::MoreUtils' => 0,
        'Module::Load' => 0,
        'Scalar::Util' => 0,
        'Time::Piece' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-tc.git',
                web => 'https://github.com/kainwinterheart/salvation-tc',
            },
            bugtracker => 'https://github.com/kainwinterheart/salvation-tc/issues',
        },
    },
);

exit 0;

__END__
