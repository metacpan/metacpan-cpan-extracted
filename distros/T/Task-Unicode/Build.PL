use strict;
use warnings;
use Module::Build;

my %requires;

if ($] >= 5.014) {
    $requires{'Unicode::Tussle'} = 0;
}

my $builder = Module::Build->new(
    module_name    => 'Task::Unicode',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    requires => {
        'perl' => '5.10.0',  # minimum Unicode support
        # modules
        'Unicode::CaseFold'         => 0,
        'Unicode::Casing'           => 0,
        'Unicode::Collate::Locale'  => 0,
        'Unicode::GCString'         => 0,
        'Unicode::LineBreak'        => 0,
        'Unicode::Regex::Set'       => 0,
        'Unicode::Stringprep'       => 0,
        'Unicode::UTF8'             => 0,
        'Unicode::Util'             => 0,
        'utf8::all'                 => 0,
        # debugging
        'String::Dump'              => 0,
        'Encode::DoubleEncodedUTF8' => 0,
        # utilities
        'App::Uni'                  => 0,
        %requires,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/task-unicode-pm5.git',
            homepage   => 'https://github.com/patch/task-unicode-pm5',
            bugtracker => 'https://github.com/patch/task-unicode-pm5/issues',
        },
    },
);

$builder->create_build_script;
