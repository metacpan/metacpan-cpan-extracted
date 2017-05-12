requires 'perl' => '5.008005';
requires 'parent' => '0',
requires 'Exporter' => '0',
requires 'XSLoader' => 0.02,
requires 'Devel::CheckCompiler' => 0.02,
requires 'ExtUtils::CBuilder';
requires 'Devel::PPPort' => 3.19,
requires 'File::Basename';
requires 'File::Path';

on 'configure' => sub{
    requires 'Module::Build' => '0.4005';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::Spec::Functions';
    requires 'Capture::Tiny';
    requires 'Cwd::Guard';
    requires 'File::Temp';
    requires 'File::Copy::Recursive';
};

