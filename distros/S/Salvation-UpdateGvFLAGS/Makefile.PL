use ExtUtils::MakeMaker;
use Devel::PPPort;
use Config;

Devel::PPPort::WriteFile();

WriteMakefile (
    NAME => 'Salvation::UpdateGvFLAGS',
    VERSION_FROM => 'lib/Salvation/UpdateGvFLAGS.pm',
    OBJECT => 'UpdateGvFLAGS.o',
    CCFLAGS => $Config{ 'ccflags' } . ' -std=c99',
    ABSTRACT => 'GvFLAGS updated',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        B => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-updategvflags.git',
                web => 'https://github.com/kainwinterheart/salvation-updategvflags',
                bugtracker => 'https://github.com/kainwinterheart/salvation-updategvflags/issues',
            },
        },
    },
);

exit 0;

__END__
