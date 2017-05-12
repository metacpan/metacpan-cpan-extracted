# NAME

Setup::Project - setup project tool

# SYNOPSIS

## Generate Sample

    cpanm Setup::Project;
    setup-project -p Setup::Project::Template::Amon2Sample package=Sample author=yourname
    cd Sample
    cpanm --installdeps .
    perl -Ilib ./script/run-server

## How to use (using cli)

    cpanm --look Setup::Project;

    cpanm Setup::Project;
    setup-project -p Setup::Project::Template::MyTemplate package=Sample name=Light author=yourname

    tree
    .
    ├── lib
    │   └── Sample
    │       └── Template
    │           └── Light.pm
    └── share
        └── tmpl
                └── Light
                      └── cpanfile
    cpanm -n .
    setup-project -p Sample::Template::Lite ........

## How to use (using sharedir)

    cpanm Setup::Project;
    setup-project -p Setup::Project::Template::MyTemplate package=Sample name=Light author=yourname

    tree
    .
    ├── lib
    │   └── Sample
    │       └── Template
    │           └── Light.pm
    └── share
        └── tmpl
                └── Light
                      └── cpanfile
    cpanm -n .
    setup-project -p Sample::Template::Lite ........

please show

    cpanm --look Setup::Project
    less lib/Setup/Project/Template/Amon2Sample.pm
    tree share/tmpl/Amon2Sample

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <git@hixi-hyi.com>
