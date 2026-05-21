# Sys-OsRelease
[![Perl](https://github.com/ikluft/Sys-OsRelease/actions/workflows/test-main.yml/badge.svg)](https://github.com/ikluft/Sys-OsRelease/actions/workflows/test-main.yml)

helper library in Perl for reading OS info from FreeDesktop.Org-standard /etc/os-release file

# Presentations

November 3, 2022 at Silicon Valley Perl: [slides](https://github.com/ikluft/Sys-OsPackage/blob/main/doc/pres-2022-11-sys-ospackage.pdf) (PDF)

<a href="https://github.com/ikluft/Sys-OsPackage/blob/main/doc/pres-2022-11-sys-ospackage.pdf"><img src="https://github.com/ikluft/Sys-OsPackage/raw/main/doc/slide1-screenshot-scaled.png"/></a>

# Sys::OsRelease module documentation

Sys::OsRelease - read operating system details from standard /etc/os-release file

## SYNOPSIS

non-object-oriented:

    Sys::OsRelease->init();
    my $id = Sys::OsRelease->id();
    my $id_like = Sys::OsRelease->id_like();

object-oriented:

    my $osrelease = Sys::OsRelease->instance();
    my $id = $osrelease->id();
    my $id_like = $osrelease->id_like();

## DESCRIPTION

Sys::OsRelease is a helper library to read the /etc/os-release file, as defined by FreeDesktop.Org.
The os-release file is used to define an operating system environment,
in widespread use among Linux distributions since 2017 and BSD variants since 2020.
It was started on Linux systems which use the systemd software, but then spread to other Linux, BSD and
Unix-based systems.
Its purpose is to identify the system to any software which needs to know.
It differentiates between Unix-based operating systems and even between Linux distributions.

Sys::OsRelease is implemented with a singleton model, meaning there is only one instance of the class.
Instead of instantiating an object with new(), the instance() class method returns the one and only instance.
The first time it's called, it instantiates it.
On following calls, it returns a reference to the singleton instance.

This module maintains minimal prerequisites, and only those which are usually included with Perl.
(Suggestions of new features and code will largely depend on following this rule.)
That is intended to be acceptable for establishing system or container environments which contain Perl programs.
It can also be used for installing or configuring software that needs to know about the system environment.

### The os-release Standard

FreeDesktop.Org's os-release standard is at [https://www.freedesktop.org/software/systemd/man/os-release.html](https://www.freedesktop.org/software/systemd/man/os-release.html).

Current attributes recognized by Sys::OsRelease are:
    NAME ID ID\_LIKE PRETTY\_NAME CPE\_NAME VARIANT VARIANT\_ID VERSION VERSION\_ID VERSION\_CODENAME BUILD\_ID IMAGE\_ID
    IMAGE\_VERSION HOME\_URL DOCUMENTATION\_URL SUPPORT\_URL BUG\_REPORT\_URL PRIVACY\_POLICY\_URL LOGO ANSI\_COLOR
    DEFAULT\_HOSTNAME SYSEXT\_LEVEL

If other attributes are found in the os-release file, they will be honored.
Folded to lower case, the attribute names are used as keys in an internal hash structure.

## METHODS

- init(\[key => value, ...\])

    initializes the singleton instance without returning a value.
    Parameters are passed to the instance() method.
    This method is for cases where method calls will be via the class name, and the program
    doesn't need a reference to the instance.

    Under normal circumstances no parameters are needed. See instance() for possible parameters.

- new(\[key => value, ...\])

    initializes the singleton instance and returns a reference to it.
    Parameters are passed to the instance() method.
    This is equivalent to using the instance() method, made available if new() sounds more comfortable.

    Under normal circumstances no parameters are needed. See instance() for possible parameters.

- instance(\[key => value, ...\])

    initializes the singleton instance and returns a reference to it.

    Under normal circumstances no parameters are needed. Possible optional parameters are as follows:

    - common\_id

        supplies an arrayref to use as a list of additional common strings which should be recognized by the platform()
        method, if they occur in the ID\_LIKE attribute in the os-release file. By default, "debian" and "fedora" are
        regonized by platform() as common names and it will return them instead of the system's ID attribute.

    - search\_path

        supplies an arrayref of strings with directories to use as the search path for the os-release file.

    - file\_name

        supplies a string with the basename of the file to look for the os-release file.
        Obviously the default file name is "os-release".
        Under normal circumstances there is no need to set this.
        Currently this is only used for testing, where suffixes are added for copies of various different systems'
        os-release files, to indicate which system they came from.

- platform()

    returns a string with the platform type. On systems with /etc/os-release (or os-release in any location
    from the standard) this is usually from the ID field.
    On systems that use the ID\_LIKE field, systems that claim to be like "debian" or "fedora" (always in lower case)
    will return those names for the platform.

    The list of recognized common platforms can be modified by passing a "common\_id" parameter to instance()/new()
    with an arrayref containing additional names to recognize as common. For example, "centos" is another possibility. 
    It was not included in the default because CentOS is discontinued. Both Rocky Linux and Alma Linux have
    ID\_LIKE fields of "rhel centos fedora", which will match "fedora" with the default setting, but could be configured
    via "common\_id" to recognize "centos" since it's listed first in ID\_LIKE.

    On systems where an os-release file doesn't exist or isn't found, the platform string will fall back to Perl's
    $Config{osname} setting for the system.

- osrelease\_path()

    returns the path where os-release was found.

    The default search path is /etc, /usr/lib and /run/host as defined by the standard.
    The search path can be replaced by providing a "search\_path" parameter to instance()/new() with an arrayref
    containing the directories to search. This feature is currently only used for testing purposes.

- defined\_instance()

    returns true if the singleton instance is defined, false if it is not yet defined or has been cleared.

- has\_attr(name)

    returns a boolean which is true if the attribute named by the string parameter exists in the os-release data for the
    current system.
    The attribute name is case insensitive.

- get(name)

    is a read-only accessor which returns the value of the os-release attribute named by the string parameter,
    or undef if it doesn't exist.

- has\_config(name)

    returns a boolean which is true if Sys::OsRelease contains a configuration setting named by the string parameter.

- config(name, \[value\])

    is a read/write accessor for the configuration setting named by the string parameter "name".
    If no value parameter is provided, it returns the value of the parameter, or undef if it doesn't exist.
    If a value parameter is provided, it assigns that to the configuration setting and returns the same value.

- clear\_instance()

    removes the singleton instance of the class if it was defined.
    Under normal circumstances it is not necessary to call this since the class destructor will call it automatically.
    It is currently only used for testing, where it is necessary to clear the instance before loading a new one with
    different parameters.

    Since this class is based on the singleton model, there is only one instance.
    The instance(), new() and init() methods will only initialize the instance if it is not already initialized.

## SEE ALSO

FreeDesktop.Org's os-release standard: [https://www.freedesktop.org/software/systemd/man/os-release.html](https://www.freedesktop.org/software/systemd/man/os-release.html)

GitHub repository for Sys::OsRelease: [https://github.com/ikluft/Sys-OsRelease](https://github.com/ikluft/Sys-OsRelease)

## BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/Sys-OsRelease/issues](https://github.com/ikluft/Sys-OsRelease/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/Sys-OsRelease/pulls](https://github.com/ikluft/Sys-OsRelease/pulls)

## LICENSE INFORMATION

Copyright (c) 2022 by Ian Kluft

This module is distributed in the hope that it will be useful, but it is provided “as is” and without any express or implied warranties. For details, see the full text of the license in the file LICENSE or at [https://www.perlfoundation.org/artistic-license-20.html](https://www.perlfoundation.org/artistic-license-20.html).
