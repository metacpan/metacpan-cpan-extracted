#!perl

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on runtime => sub {
    requires 'Carp'            => 0;
    requires 'Encode'          => 0;
    requires 'Encode::Locale'  => 0;
    requires 'Exporter::Tidy'  => 0;
    requires 'File::Which'     => 0;
    requires 'File::chdir'     => 0;
    requires 'IO::Handle'      => 0;
    requires 'Log::Any'        => 0;
    requires 'Proc::FastSpawn' => 0;
};

on develop => sub {
    requires 'App::githook::perltidy' => 0;
};

on test => sub {
    requires 'Cwd'          => 0;
    requires 'Data::Dumper' => 0;
    requires 'File::Temp'   => 0;
    requires 'File::Spec'   => 0;
    requires 'Test2::V0'    => 0;
};
