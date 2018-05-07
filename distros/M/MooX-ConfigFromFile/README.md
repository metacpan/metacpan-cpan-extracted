# NAME

MooX::ConfigFromFile - Moo eXtension for initializing objects from config file

<div>
    <a href="https://travis-ci.org/perl5-utils/MooX-ConfigFromFile"><img src="https://travis-ci.org/perl5-utils/MooX-ConfigFromFile.svg?branch=master" alt="Travis CI"/></a>
    <a href='https://coveralls.io/github/perl5-utils/MooX-ConfigFromFile?branch=master'><img src='https://coveralls.io/repos/github/perl5-utils/MooX-ConfigFromFile/badge.svg?branch=master' alt='Coverage Status'/></a>
</div>

# SYNOPSIS

    package Role::Action;

    use Moo::Role;

    has operator => ( is => "ro" );

    package Action;

    use Moo;
    use MooX::ConfigFromFile; # imports the MooX::ConfigFromFile::Role

    with "Role::Action";

    sub operate { return say shift->operator; }

    package OtherAction;

    use Moo;

    with "Role::Action", "MooX::ConfigFromFile::Role";

    sub operate { return warn shift->operator; }

    package QuiteOtherOne;

    use Moo;

    # consumes the MooX::ConfigFromFile::Role but load config only once
    use MooX::ConfigFromFile config_singleton => 1;

    with "Role::Action";

    sub _build_config_prefix { "die" }

    sub operate { return die shift->operator; }

    package main;

    my $action = Action->new(); # tries to find a config file in config_dirs and loads it
    my $other = OtherAction->new( config_prefix => "warn" ); # use another config file
    my $quite_o = QuiteOtherOne->new(); # quite another way to have an individual config file

# DESCRIPTION

This module is intended to easy load initialization values for attributes
on object construction from an appropriate config file. The building is
done in [MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role) - using MooX::ConfigFromFile ensures
the role is applied.

For easier usage, with 0.004, several options can be passed via _use_ resulting
in default initializers for appropriate role attributes:

- `config_prefix`

    Default for ["config\_prefix" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#config_prefix).

- `config_prefixes`

    Default for ["config\_prefixes" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#config_prefixes). Ensure when use
    this flag together with [MooX::Cmd](https://metacpan.org/pod/MooX::Cmd) to load `MooX::ConfigFromFile` before
    `MooX::Cmd`.

- `config_prefix_map_separator`

    Default for ["config\_prefix\_map\_separator" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#config_prefix_map_separator).

        package Foo;

        # apply role MooX::ConfigFromFile::Role and override default for
        # attribute config_prefix_map_separator
        use MooX::ConfigFromFile config_prefix_map_separator => "~";

        ...

- `config_extensions`

    Default for ["config\_extensions" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#config_extensions).

- `config_dirs`

    Default for ["config\_dirs" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#config_dirs).
    Same warning regarding modifying this attribute applies here:
    Possible, but use with caution!

        package Foo;

        use MooX::ConfigFromFile config_dirs => [qw(/opt/foo/etc /home/alfred/area/foo/etc)];

        ...

- `config_files`

    Default for ["config\_files" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#config_files).

    Reasonable when you want exactly one config file in development mode.
    For production code it is highly recommended to override the builder.

- `config_singleton`

    Flag adding a wrapper [around](https://metacpan.org/pod/Class::Method::Modifiers#around-method-s-sub)
    the _builder_ of ["loaded\_config" in MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role#loaded_config) to ensure a
    config is loaded only once per class. The _per class_ restriction results
    from applicable modifiers per class (and singletons are per class).

- `config_identifier`

    Default for ["config\_identifier" in MooX::File::ConfigDir](https://metacpan.org/pod/MooX::File::ConfigDir#config_identifier).

        package Foo;

        # apply role MooX::ConfigFromFile::Role and override default for
        # attribute config_identifier - means to look e.g. in /etc/foo/
        use MooX::ConfigFromFile config_identifier => "foo";

        ...

- `config_hashmergeloaded`

    Consumes role [MooX::ConfigFromFile::Role::HashMergeLoaded](https://metacpan.org/pod/MooX::ConfigFromFile::Role::HashMergeLoaded) directly after
    [MooX::ConfigFromFile::Role](https://metacpan.org/pod/MooX::ConfigFromFile::Role) has been consumed.

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-moox-configfromfile at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-ConfigFromFile](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-ConfigFromFile).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::ConfigFromFile

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-ConfigFromFile](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-ConfigFromFile)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MooX-ConfigFromFile](http://annocpan.org/dist/MooX-ConfigFromFile)

- CPAN Ratings

    [http://cpanratings.perl.org/d/MooX-ConfigFromFile](http://cpanratings.perl.org/d/MooX-ConfigFromFile)

- Search CPAN

    [http://search.cpan.org/dist/MooX-ConfigFromFile/](http://search.cpan.org/dist/MooX-ConfigFromFile/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2013-2018 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
