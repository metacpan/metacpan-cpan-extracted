#!perl
on configure => sub {
    requires 'File::Spec'          => 0;
    requires 'ExtUtils::MakeMaker' => '6.17';
};

on runtime => sub {
    requires 'perl'         => 5.010;
    requires 'Carp'         => 0;
    requires 'Encode'       => 2.24;
    requires 'Getopt::Long' => 2.37;
    requires 'I18N::Langinfo' if $^O ne 'MSWin32';
    requires 'List::Util'   => 0;
    requires 'Text::Abbrev' => 0;
};

on test => sub {
    requires 'IO::Capture::Stdout' => 0;
    requires 'POSIX'               => 0;
    requires 'Test2::V0'           => 0;
};
