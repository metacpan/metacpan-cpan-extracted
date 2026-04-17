use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'TUI::Vision',
    AUTHOR           => 'J. Schneider',
    VERSION_FROM     => 'lib/TUI/Vision.pm',
    ABSTRACT         => 'Perl TUI Framework (Turbo Vision 2.0 Port)',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',

    PREREQ_PM => {},

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/brickpool/tvision.git',
                web  => 'https://github.com/brickpool/tvision',
            },
        },

        provides => {
            'TUI::Vision' 
                => { file => 'lib/TUI/Vision.pm', version => '2.0.0' },
            'TUI::App' 
                => { file => 'lib/TUI/App.pm', version => '2.0.0' },
            'TUI::Dialogs'
                => { file => 'lib/TUI/Dialogs.pm', version => '2.0.0' },
            'TUI::Drivers'
                => { file => 'lib/TUI/Drivers.pm', version => '2.0.0' },
            'TUI::Gadgets'
                => { file => 'lib/TUI/Gadgets.pm', version => '2.0.0' },
            'TUI::Memory'
                => { file => 'lib/TUI/Memory.pm', version => '2.0.0' },
            'TUI::MsgBox'
                => { file => 'lib/TUI/MsgBox.pm', version => '2.0.0' },
            'TUI::Objects' 
                => { file => 'lib/TUI/Objects.pm', version => '2.0.0' },
            'TUI::StdDlg'
                => { file => 'lib/TUI/StdDlg.pm', version => '2.0.0' },
            'TUI::TextView'
                => { file => 'lib/TUI/TextView.pm', version => '2.0.0' },
            'TUI::Validate'
                => { file => 'lib/TUI/Validate.pm', version => '2.0.0' },
            'TUI::Views'
                => { file => 'lib/TUI/Views.pm', version => '2.0.0' },
            'TUI::toolkit'
                => { file => 'lib/TUI/toolkit.pm', version => '2.0.0' },
        },
    },

    $^O =~ /win/i ? (
        dist => {
            TARFLAGS => '-cvzf',
            COMPRESS => 'perl -MExtUtils::Command -e test_f',
            POSTOP   => 'perl -MExtUtils::Command -e mv $(DISTVNAME).tar '
            . '$(DISTVNAME).tar$(SUFFIX)'
        },
    ) : (),
    clean => { FILES => 'TUI-Vision-*', },
);
