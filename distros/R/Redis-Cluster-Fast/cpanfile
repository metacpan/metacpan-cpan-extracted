requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'configure' => sub {
    requires 'File::Which';
    requires 'File::chdir';
    requires 'Module::Build::XSUtil', '>=0.02';
};

on 'develop' => sub {
    requires 'IO::CaptureOutput';
    requires 'Scope::Guard';
    requires 'Sub::Retry';
    requires 'Test::LeakTrace';
    requires 'Test::SharedFork';
    requires 'Test::Valgrind';
};