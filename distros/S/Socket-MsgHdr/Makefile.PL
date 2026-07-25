use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $mm_version = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Socket::MsgHdr',
    VERSION_FROM      => 'lib/Socket/MsgHdr.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Socket/MsgHdr.pm',
    LICENSE           => 'perl_5',
    AUTHOR            => [ 'Mike Pomraning <mjp@cpan.org>', 'Felipe Gasper <felipe@cpan.org>' ],
	($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Socket-MsgHdr.git',
                web => 'https://github.com/FGasper/p5-Socket-MsgHdr',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Socket-MsgHdr/issues',
            },
        },
    },
);
