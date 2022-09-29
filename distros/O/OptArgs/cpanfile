#!perl
on configure => sub {
    requires 'File::Spec'                    => 0;
    requires 'ExtUtils::MakeMaker::CPANfile' => 0;
};

on runtime => sub {
    requires 'Carp'           => 0;
    requires 'Encode'         => 2.24;
    requires 'Exporter::Tidy' => 0;
    requires 'File::Which'    => 0;
    requires 'Getopt::Long'   => 2.37;
    requires 'I18N::Langinfo' if $^O ne 'MSWin32';
    requires 'List::Util'   => 0;
    requires 'Text::Abbrev' => 0;
    requires 'perl'         => 5.006;
};

on develop => sub {
    requires 'App::githook::perltidy' => 'v0.12.0';
};

on test => sub {
    requires 'POSIX'               => 0;
    requires 'IO::Capture::Stdout' => 0;
    requires 'Test::Fatal'         => 0;
    requires 'Test::More'          => 0;
    requires 'Test::Output'        => 0;
};
