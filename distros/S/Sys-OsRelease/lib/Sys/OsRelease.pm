# Sys::OsRelease
# ABSTRACT: read operating system details from standard /etc/os-release file
# Copyright (c) 2022 by Ian Kluft
# Open Source license Perl's Artistic License 2.0: <http://www.perlfoundation.org/artistic_license_2_0>
# SPDX-License-Identifier: Artistic-2.0

# This module must be maintained for minimal dependencies so it can be used to build systems and containers.

## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where conflicting Perl::Critic rules want package and strictures each before the other
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package Sys::OsRelease;
$Sys::OsRelease::VERSION = '0.2.0';
use Config;
use Carp qw(carp croak);

# the instance - use Sys::OsRelease->instance() to get it
my %_instances = ();

# default search path and file name for os-release file
my @std_search_path = qw(/etc /usr/lib /run/host);
my $std_file_name = "os-release";

# defined attributes from FreeDesktop's os-release standard - this needs to be kept up-to-date with the standard
my @std_attrs = qw(NAME ID ID_LIKE PRETTY_NAME CPE_NAME VARIANT VARIANT_ID VERSION VERSION_ID VERSION_CODENAME
    BUILD_ID IMAGE_ID IMAGE_VERSION HOME_URL DOCUMENTATION_URL SUPPORT_URL BUG_REPORT_URL PRIVACY_POLICY_URL
    LOGO ANSI_COLOR DEFAULT_HOSTNAME SYSEXT_LEVEL);

# OS ID strings which are preferred as common if found in ID_LIKE
my %common_id = (
    fedora => 1,
    debian => 1,
);

# call destructor when program ends
END {
    foreach my $class (keys %_instances) {
        $class->clear_instance();
    }
    undef %_instances;
}

#
# singleton management methods
# These can be imported by another class by using the import_singleton() method. That was done for Sys::OsPackage,
# to avoid copying those methods.  But other classes with a similar need to minimize module dependencies which already
# use Sys::OsRelease can do this too.
#

# alternative method to initiate initialization without returning a value
sub init
{
    my ($class, @params) = @_;
    $class->instance(@params);
    return;
}

# new method calls instance
sub new
{
    my ($class, @params) = @_;
    return $class->instance(@params);
}

# singleton class instance
sub instance
{
    my ($class, @params) = @_;

    # initialize if not already done
    if (not defined $_instances{$class}) {
        $_instances{$class} = $class->_new_instance(@params);
    }

    # return singleton instance
    return $_instances{$class};
}

# test if instance is defined for testing
sub defined_instance
{
    my $class = shift;
    return ((defined $_instances{$class}) and $_instances{$class}->isa($class)) ? 1 : 0;
}

# clear instance for exit-cleanup or for re-use in testing
sub clear_instance
{
    my $class = shift;
    if ($class->defined_instance()) {
        # clean up anything that the destructor will miss, such as auto-generated methods
        if ($class->can("_cleanup_instance")) {
            $class->_cleanup_instance();
        }

        # dereferencing will destroy singleton instance
        undef $_instances{$class};
    }
    return;
}

# allow other classes which cooperate with Sys::OsRelease to import our singleton-management methods
# This helps maintain minimal prerequisites among modules working to set up Perl on containers or new systems.
sub import_singleton
{
    my $class = shift;
    my $caller_class = caller;

    # export singleton-management methods to caller class
    foreach my $method_name (qw(init new instance defined_instance clear_instance)) {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        *{$caller_class."::".$method_name} = \&{__PACKAGE__."::".$method_name};
    }
    return;
}

#
# os-release data access methods
#

# access module constants
sub std_search_path { return @std_search_path; }
sub std_attrs { return @std_attrs; }

# fold case for case-insensitive matching
my $can_fc = CORE->can("fc"); # test fc() once and save result
sub fold_case
{
    my $str = shift;

    # use fc if available, otherwise lc to support older Perls
    return $can_fc ?  $can_fc->($str) : lc($str);
}

# initialize a new instance
sub _new_instance
{
    my ($class, @params) = @_;

    # enforce class lineage - _new_instance() should be overloaded by other classes that import singleton methods
    if (not $class->isa(__PACKAGE__)) {
        croak "_new_instance() should be overloaded by calling class: "
            .(ref $class ? ref $class : $class)." is not a ".__PACKAGE__;
    }

    # obtain parameters from array or hashref
    my %obj;
    if (scalar @params > 0) {
        if (ref $params[0] eq 'HASH') {
            $obj{_config} = $params[0];
        } else {
            $obj{_config} = {@params};
        }
    }

    # locate os-release file in standard places
    my $osrelease_path;
    my @search_path = ((exists $obj{_config}{search_path}) ? @{$obj{_config}{search_path}} : @std_search_path);
    my $file_name = ((exists $obj{_config}{file_name}) ? $obj{_config}{file_name} : $std_file_name);
    foreach my $search_dir (@search_path) {
        if (-r "$search_dir/$file_name") {
            $osrelease_path = $search_dir."/".$file_name;
            last;
        }
    }

    # If we found os-release on this system, read it
    # otherwise leave everything empty and platform() method will use Perl's $Config{osname} as a summary value
    if (defined $osrelease_path) {
        # save os-release file path
        $obj{_config}{osrelease_path} = $osrelease_path;

        # read os-release file
        ## no critic (InputOutput::RequireBriefOpen)
        if (open my $fh, "<", $osrelease_path) {
            while (my $line = <$fh>) {
                chomp $line; # remove trailing nl
                if (substr($line, -1, 1) eq "\r") {
                    $line = substr($line, 0, -1); # remove trailing cr
                }

                # skip comments and blank lines
                if ($line =~ /^ \s+ #/x or $line =~ /^ \s+ $/x) {
                    next;
                }

                # read attribute assignment lines
                if ($line =~ /^ ([A-Z0-9_]+) = "(.*)" $/x
                    or $line =~ /^ ([A-Z0-9_]+) = '(.*)' $/x
                    or $line =~ /^ ([A-Z0-9_]+) = (.*) $/x)
                {
                    next if $1 eq "_config"; # don't overwrite _config
                    $obj{fold_case($1)} = $2;
                }
            }
            close $fh;
        }
    }

    # bless instance and generate accessor methods
    my $obj_ref = bless \%obj, $class;
    $obj_ref->_gen_accessors();

    # instantiate object
    return $obj_ref;
}

# helper function to allow methods to get the instance ref when called via the class name
sub class_or_obj
{
    my $coo = shift;

    # return the instance
    return ((ref $coo) ? $coo : $coo->instance());
}

# clean up data in an instance before feeding it to the destructor
sub _cleanup_instance
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # enforce class lineage - _cleanup_instance() should be overloaded by other classes that import singleton methods
    if (not $self->isa(__PACKAGE__)) {
        croak "_new_instance() should be overloaded by calling class: "
            .(ef $self)." is not a ".__PACKAGE__;
    }

    # clear accessor functions
    foreach my $acc (keys %{$self->{_config}{accessor}}) {
        $self->_clear_accessor($acc);
    }
    return;
}

# determine platform type
sub platform
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);
    
    # if we haven't already saved this result, compute and save it
    if (not $self->has_config("platform")) {
        if ($self->has_attr("id")) {
            $self->config("platform", $self->id);
        }
        if ($self->has_attr("id_like")) {
            # check if the configuration has additional common IDs which should be recognized if seen in ID_LIKE
            if ($self->has_config("common_id")) {
                my $cids = $self->config("common_id");
                my @cids = (ref $cids eq "ARRAY") ? (@{$cids}) : (split /\s+/x, $cids);
                foreach my $cid (@cids) {
                    $common_id{$cid} = 1;
                }
            }

            # check ID_LIKE for more common names which should be used instead of ID
            foreach my $like (split /\s+/x, $self->id_like) {
                if (exists $common_id{$like}) {
                    $self->config("platform", $like);
                    last;
                }
            }
        }

        # if platform is still not set, use Perl's osname config as a summary value
        if (not $self->has_config("platform")) {
            $self->config("platform", $Config{osname});
        }
    }
    return $self->config("platform");
}

# get location of the os-release file found on this system
# return undef if the file was not found
sub osrelease_path
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);
    if (exists $self->{_config}{osrelease_path}) {
        return $self->{_config}{osrelease_path};
    }
    return;
}

# attribute existence checker
sub has_attr
{
    my ($class_or_obj, $key) = @_;
    my $self = class_or_obj($class_or_obj);
    return ((exists $self->{fold_case($key)}) ? 1 : 0);
}

# attribute read-only accessor
sub get
{
    my ($class_or_obj, $key) = @_;
    my $self = class_or_obj($class_or_obj);
    return $self->{fold_case($key)};
}

# attribute existence checker
sub has_config
{
    my ($class_or_obj, $key) = @_;
    my $self = class_or_obj($class_or_obj);
    return ((exists $self->{_config}{$key}) ? 1 : 0);
}

# config read/write accessor
sub config
{
    my ($class_or_obj, $key, $value) = @_;
    my $self = class_or_obj($class_or_obj);
    if (defined $value) {
        $self->{_config}{$key} = $value;
    }
    return $self->{_config}{$key};
}

# generate accessor methods for all defined and standardized attributes
# private internal method
sub _gen_accessors
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # generate read-only accessors for attributes actually found in os-release
    foreach my $key (sort keys %{$self}) {
        next if $key eq "_config"; # protect special/reserved attribute
        $self->_gen_accessor($key);
    }

    # generate undef accessors for standardized attributes which were not found in os-release
    foreach my $std_attr (@std_attrs) {
        next if $std_attr eq "_config"; # protect special/reserved attribute
        my $fc_attr = fold_case($std_attr);
        next if $self->has_attr($fc_attr);
        $self->_gen_accessor($fc_attr);
    }
    return;
}

# generate accessor
# private internal method
sub _gen_accessor
{
    my ($class_or_obj, $name) = @_;
    my $self = class_or_obj($class_or_obj);
    my $class = (ref $self) ? (ref $self) : $self; 
    my $method_name = $class."::".$name;

    # mark accessor flag in configuration so it can be deleted for cleanup (mainly for testing)
    if (not exists $self->{_config}{accessor}) {
        $self->{_config}{accessor} = {};
    }

    # generate accessor as read-only or undef depending whether it exists in the running system
    if (exists $self->{$name}) {
        # generate read-only accessor for attribute which was found in os-release
        $self->{_config}{accessor}{$name} = sub { return $self->{$name} };
    } else {
        # generate undef accessor for standard attribute which was not found in os-release
        $self->{_config}{accessor}{$name} = sub { return; };
    }

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    *{$method_name} = $self->{_config}{accessor}{$name};
    return;
}

# clean up accessor
# private internal method
sub _clear_accessor
{
    my ($class_or_obj, $name) = @_;
    my $self = class_or_obj($class_or_obj);
    my $class = (ref $self) ? (ref $self) : $self; 
    if (exists $self->{_config}{accessor}{$name}) {
        my $method_name = $class."::".$name;
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        undef *{$method_name};
        delete $self->{_config}{accessor}{$name};
    }
    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::OsRelease - read operating system details from standard /etc/os-release file

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

non-object-oriented:

  Sys::OsRelease->init();
  my $id = Sys::OsRelease->id();
  my $id_like = Sys::OsRelease->id_like();

object-oriented:

  my $osrelease = Sys::OsRelease->instance();
  my $id = $osrelease->id();
  my $id_like = $osrelease->id_like();

=head1 DESCRIPTION

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

=head2 The os-release Standard

FreeDesktop.Org's os-release standard is at L<https://www.freedesktop.org/software/systemd/man/os-release.html>.

Current attributes recognized by Sys::OsRelease are:
    NAME ID ID_LIKE PRETTY_NAME CPE_NAME VARIANT VARIANT_ID VERSION VERSION_ID VERSION_CODENAME BUILD_ID IMAGE_ID
    IMAGE_VERSION HOME_URL DOCUMENTATION_URL SUPPORT_URL BUG_REPORT_URL PRIVACY_POLICY_URL LOGO ANSI_COLOR
    DEFAULT_HOSTNAME SYSEXT_LEVEL

If other attributes are found in the os-release file, they will be honored.
Folded to lower case, the attribute names are used as keys in an internal hash structure.

=head1 NAME

Sys::OsRelease - read operating system details from standard /etc/os-release file

=head1 METHODS

=over 1

=item init([key => value, ...])

initializes the singleton instance without returning a value.
Parameters are passed to the instance() method.
This method is for cases where method calls will be via the class name, and the program
doesn't need a reference to the instance.

Under normal circumstances no parameters are needed. See instance() for possible parameters.

=item new([key => value, ...])

initializes the singleton instance and returns a reference to it.
Parameters are passed to the instance() method.
This is equivalent to using the instance() method, made available if new() sounds more comfortable.

Under normal circumstances no parameters are needed. See instance() for possible parameters.

=item instance([key => value, ...])

initializes the singleton instance and returns a reference to it.

Under normal circumstances no parameters are needed. Possible optional parameters are as follows:

=over 1

=item common_id

supplies an arrayref to use as a list of additional common strings which should be recognized by the platform()
method, if they occur in the ID_LIKE attribute in the os-release file. By default, "debian" and "fedora" are
regonized by platform() as common names and it will return them instead of the system's ID attribute.

=item search_path

supplies an arrayref of strings with directories to use as the search path for the os-release file.

=item file_name

supplies a string with the basename of the file to look for the os-release file.
Obviously the default file name is "os-release".
Under normal circumstances there is no need to set this.
Currently this is only used for testing, where suffixes are added for copies of various different systems'
os-release files, to indicate which system they came from.

=back

=item platform()

returns a string with the platform type. On systems with /etc/os-release (or os-release in any location
from the standard) this is usually from the ID field.
On systems that use the ID_LIKE field, systems that claim to be like "debian" or "fedora" (always in lower case)
will return those names for the platform.

The list of recognized common platforms can be modified by passing a "common_id" parameter to instance()/new()
with an arrayref containing additional names to recognize as common. For example, "centos" is another possibility. 
It was not included in the default because CentOS is discontinued. Both Rocky Linux and Alma Linux have
ID_LIKE fields of "rhel centos fedora", which will match "fedora" with the default setting, but could be configured
via "common_id" to recognize "centos" since it's listed first in ID_LIKE.

On systems where an os-release file doesn't exist or isn't found, the platform string will fall back to Perl's
$Config{osname} setting for the system.

=item osrelease_path()

returns the path where os-release was found.

The default search path is /etc, /usr/lib and /run/host as defined by the standard.
The search path can be replaced by providing a "search_path" parameter to instance()/new() with an arrayref
containing the directories to search. This feature is currently only used for testing purposes.

=item defined_instance()

returns true if the singleton instance is defined, false if it is not yet defined or has been cleared.

=item has_attr(name)

returns a boolean which is true if the attribute named by the string parameter exists in the os-release data for the
current system.
The attribute name is case insensitive.

=item get(name)

is a read-only accessor which returns the value of the os-release attribute named by the string parameter,
or undef if it doesn't exist.

=item has_config(name)

returns a boolean which is true if Sys::OsRelease contains a configuration setting named by the string parameter.

=item config(name, [value])

is a read/write accessor for the configuration setting named by the string parameter "name".
If no value parameter is provided, it returns the value of the parameter, or undef if it doesn't exist.
If a value parameter is provided, it assigns that to the configuration setting and returns the same value.

=item clear_instance()

removes the singleton instance of the class if it was defined.
Under normal circumstances it is not necessary to call this since the class destructor will call it automatically.
It is currently only used for testing, where it is necessary to clear the instance before loading a new one with
different parameters.

Since this class is based on the singleton model, there is only one instance.
The instance(), new() and init() methods will only initialize the instance if it is not already initialized.

=item import_singleton

The singleton-management methods I<init>, I<new>, I<instance>, I<defined_instance> and I<clear_instance>
can be imported by another class by using the import_singleton() method.
That was done for L<Sys::OsPackage>, to allow it to avoid copying those methods.
But other classes with a similar need to minimize module dependencies which already
use I<Sys::OsRelease> can do this too.
This helps maintain minimal prerequisites among modules working to set up Perl on containers or new systems.

=back

=head1 SEE ALSO

FreeDesktop.Org's os-release standard: L<https://www.freedesktop.org/software/systemd/man/os-release.html>

GitHub repository for Sys::OsRelease: L<https://github.com/ikluft/Sys-OsRelease>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/Sys-OsRelease/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/Sys-OsRelease/pulls>

=head1 LICENSE INFORMATION

Copyright (c) 2022 by Ian Kluft

This module is distributed in the hope that it will be useful, but it is provided “as is” and without any express or implied warranties. For details, see the full text of the license in the file LICENSE or at L<https://www.perlfoundation.org/artistic-license-20.html>.

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Ian Kluft.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# POD documentation
