[![Build Status](https://travis-ci.org/avast/MooseX-Getopt-Kingpin.svg?branch=master)](https://travis-ci.org/avast/MooseX-Getopt-Kingpin)
# NAME

MooseX::Getopt::Kingpin - A Moose role for processing command lines options via Getopt::Kingpin

# SYNOPSIS

    ### In your class
    package MyClass {
        use Moose;
        with 'MooseX::Getopt::Kingpin';

        my $lines_default = 10;
        has 'lines' => (
            is            => 'ro',
            isa           => 'Int',
            default       => $lines_default,
            documentation => sub ($kingpin) {
                $kingpin->flag('lines', 'print first N lines')
                  ->default($lines_default)
                  ->short('n')
                  ->int();
            },
        );

        has 'input_file' => (
            is            => 'ro',
            isa           => 'Path::Tiny',
            required      => 1,
            documentation => sub ($kingpin) {
                $kingpin->arg('input_file', 'input_file')
                  ->required
                  ->existing_file();
            },
        );

        has 'other_attr' => (is => 'ro', isa => 'Str');
    };

    my $kingpin = Getopt::Kingpin->new();
    my $other_flag = $kingpin->flag('other_flag', 'this flag do something ...')->bool();
    $kingpin->version($MyClass::VERSION);
    MyClass->new_with_options(
        $kingpin,
        other_attr => 'xxx'
    );

    if $other_flag {
        ...
    }

# DESCRIPTION

This is a role which provides an alternate constructor for creating objects using parameters passed in from the command line.

Thi role use [Getopt::Kingpin](https://metacpan.org/pod/Getopt::Kingpin) as command line processor, MOP and documentation trick.

# METHODS

## new\_with\_options($kingpin, %options)

`$kingpin` instance of [Getopt::Kingpin](https://metacpan.org/pod/Getopt::Kingpin) is required

`%options` - classic Moose options, override options set via kingpin

# SEE ALSO

- [MooseX::Getopt](https://metacpan.org/pod/MooseX::Getopt)

# contributing

for dependency use \[cpanfile\](cpanfile)...

for resolve dependency use \[carton\](https://metacpan.org/pod/Carton) (or carton - is more experimental)

    carton install

for run test use `minil test`

    carton exec minil test

if you don't have perl environment, is best way use docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton install
    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended carton exec minil test

## warning

docker run default as root, all files which will be make in docker will be have root rights

one solution is change rights in docker

    docker run -it -v $PWD:/tmp/work -w /tmp/work avastsoftware/perl-extended bash -c "carton install; chmod -R 0777 ."

or after docker command (but you must have root rights)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR
Jan Seidl <seidl@avast.com>
