# http://bit.ly/cpanfile
# http://bit.ly/cpanfile_version_formats
requires 'perl', '5.008005';
requires 'strict';
requires 'Module::Pluggable::Object';
requires 'Test::More';
requires 'Test::SharedFork';

on 'configure' => sub {
    requires 'Module::Build' , '0.38';
    requires 'FindBin';
    requires 'File::Spec';
};

on 'develop' => sub {
    requires 'Test::Perl::Critic';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod';
};