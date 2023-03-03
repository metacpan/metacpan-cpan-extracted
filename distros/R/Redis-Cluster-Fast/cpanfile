requires 'perl', '5.008001';

on 'test' => sub {
    requires 'IO::CaptureOutput';
    requires 'Scope::Guard';
    requires 'Sub::Retry';
    requires 'Test::LeakTrace';
    requires 'Test::More', '0.98';
    requires 'Test::SharedFork';
    requires 'Test::Valgrind';
};

on 'configure' => sub {
    requires 'Devel::CheckBin';
    requires 'File::Spec';
    requires 'File::Which';
    requires 'File::chdir';
    requires 'Module::Build::XSUtil', '>=0.02';
};