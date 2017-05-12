requires 'Cwd';
requires 'File::Spec';
requires 'File::Which';
requires 'File::chdir';
requires 'HTTP::Date';
requires 'IO::Uncompress::Gunzip', '2.055';
requires 'IPC::Open3';
requires 'Plack';
requires 'parent';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
};

on test => sub {
    requires 'File::Copy::Recursive';
};