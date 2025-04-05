#!perl
on configure => sub {
    requires 'File::Spec'                    => 0;
    requires 'ExtUtils::MakeMaker::CPANfile' => 0;
};

on runtime => sub {
    requires 'perl'           => 5.016;
    requires 'Carp'           => 0;
    requires 'Exporter::Tidy' => 0;
    requires 'Encode::Locale' => 0;
    requires 'File::Which'    => 0;
    requires 'Getopt::Long'   => 2.37;
    requires 'List::Util'     => 0;
    requires 'Text::Abbrev'   => 0;

    if ( $^O eq 'MSWin32' ) {
        requires 'Win32::Console' => 0;
    }
    else {
        requires 'Term::Size::Perl' => 0;
    }
};

on develop => sub {
    requires 'App::githook::perltidy' => 'v0.12.0';
    requires 'Class::Inline'          => 0;
};

on test => sub {
    requires 'POSIX'        => 0;
    requires 'Test2::V0'    => 0;
    requires 'Test::Output' => 0;
};
