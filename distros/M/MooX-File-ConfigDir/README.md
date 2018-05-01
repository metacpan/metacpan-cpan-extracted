# NAME

MooX::File::ConfigDir - Moo eXtension for File::ConfigDir

<div>
    <a href="https://travis-ci.org/perl5-utils/MooX-File-ConfigDir"><img src="https://travis-ci.org/perl5-utils/MooX-File-ConfigDir.svg?branch=master" alt="Travis CI"/></a>
    <a href='https://coveralls.io/github/perl5-utils/MooX-File-ConfigDir?branch=master'><img src='https://coveralls.io/repos/github/perl5-utils/MooX-File-ConfigDir/badge.svg?branch=master' alt='Coverage Status'/></a>
</div>

# SYNOPSIS

    my App;

    use Moo;
    with MooX::File::ConfigDir;

    1;

    package main;

    my $app = App->new();
    $app->config_identifier('MyProject');

    my @cfgdirs = @{ $app->config_dirs };

    # install support
    my $site_cfg_dir = $app->site_cfg_dir->[0];
    my $vendor_cfg_dir = $app->site_cfg_dir->[0];

# DESCRIPTION

This module is a helper for easily find configuration file locations.
Whether to use this information for find a suitable place for installing
them or looking around for finding any piece of settings, heavily depends
on the requirements.

# ATTRIBUTES

## config\_identifier

Allows to deal with a global unique identifier passed to the functions of
[File::ConfigDir](https://metacpan.org/pod/File::ConfigDir). Using it encapsulates configuration files from the
other ones (e.g. `/etc/apache2` vs. `/etc`).

`config_identifier` can be initialized by specifying it as parameter
during object construction or via inheriting default builder
(`_build_config_identifier`).

## system\_cfg\_dir

Provides the configuration directory where configuration files of the
operating system resides. For details see ["system\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#system_cfg_dir).

## desktop\_cfg\_dir

Provides the configuration directory where configuration files of the
desktop applications resides. For details see ["desktop\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#desktop_cfg_dir).

## xdg\_config\_dirs

Alias for desktop\_cfg\_dir to support
[XDG Base Directory Specification](http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html)

## core\_cfg\_dir

Provides the configuration directory of the Perl5 core location.
For details see ["core\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#core_cfg_dir).

## site\_cfg\_dir

Provides the configuration directory of the Perl5 sitelib location.
For details see ["site\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#site_cfg_dir).

## vendor\_cfg\_dir

Provides the configuration directory of the Perl5 vendorlib location.
For details see ["vendor\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#vendor_cfg_dir).

## singleapp\_cfg\_dir

Provides the configuration directory of `$0` if it's installed as
a separate package - either a program bundle (TSM, Oracle DB) or
an independent package combination (e.g. via [PkgSrc](http://www.pkgsrc.org/)
For details see ["singleapp\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#singleapp_cfg_dir).

## vendorapp\_cfg\_dir

Provides the configuration directory of `$0` if it's installed as
a separate package via a vendor installation as e.g. [PkgSrc](http://www.pkgsrc.org/)
or [Homebrew](https://brew.sh/).
For details see ["vendorapp\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#vendorapp_cfg_dir).

## local\_cfg\_dir

Returns the configuration directory for distribution independent, 3rd
party applications. For details see ["local\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#local_cfg_dir).

## locallib\_cfg\_dir

Provides the configuration directory of the Perl5 [local::lib](https://metacpan.org/pod/local::lib) environment
location.  For details see ["locallib\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#locallib_cfg_dir).

## here\_cfg\_dir

Provides the path for the `etc` directory below the current working directory.
For details see ["here\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#here_cfg_dir).

## user\_cfg\_dir

Provides the users home folder using [File::HomeDir](https://metacpan.org/pod/File::HomeDir).
For details see ["user\_cfg\_dir" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#user_cfg_dir).

## xdg\_config\_home

Returns the user configuration directory for desktop applications.
For details see ["xdg\_config\_home" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#xdg_config_home).

## config\_dirs

Tries to get all available configuration directories as described above.
Returns those who exists and are readable.
For details see ["config\_dirs" in File::ConfigDir](https://metacpan.org/pod/File::ConfigDir#config_dirs).

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-MooX-File-ConfigDir at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-File-ConfigDir](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-File-ConfigDir).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::File::ConfigDir

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-File-ConfigDir](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-File-ConfigDir)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MooX-File-ConfigDir](http://annocpan.org/dist/MooX-File-ConfigDir)

- CPAN Ratings

    [http://cpanratings.perl.org/m/MooX-File-ConfigDir](http://cpanratings.perl.org/m/MooX-File-ConfigDir)

- Search CPAN

    [http://search.cpan.org/dist/MooX-File-ConfigDir/](http://search.cpan.org/dist/MooX-File-ConfigDir/)

# LICENSE AND COPYRIGHT

Copyright 2013-2018 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
