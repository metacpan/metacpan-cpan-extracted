# Sys::OsRelease
# ABSTRACT: read operating system details from FreeDesktop.Org standard /etc/os-release file
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
$Sys::OsRelease::VERSION = '0.0.1';
use Carp qw(carp croak);

# the instance - use Sys::OsRelease->instance() to get it
my $_instance;

# default search path and file name for os-release file
my @std_search_path = qw(/etc /usr/lib /run/host);
my $std_file_name = "os-release";

# defined attributes from FreeDesktop's os-release standard - this needs to be kept up-to-date with the standard
my @std_attrs = qw(NAME ID ID_LIKE PRETTY_NAME CPE_NAME VARIANT VARIANT_ID VERSION VERSION_ID VERSION_CODENAME
    BUILD_ID IMAGE_ID IMAGE_VERSION HOME_URL DOCUMENTATION_URL SUPPORT_URL BUG_REPORT_URL PRIVACY_POLICY_URL
    LOGO ANSI_COLOR DEFAULT_HOSTNAME SYSEXT_LEVEL);

# fold case for case-insensitive matching
my $can_fc = CORE->can("fc"); # test fc() once and save result
sub fold_case
{
    my $str = shift;

    # use fc if available, otherwise lc to support older Perls
    return $can_fc ?  $can_fc->($str) : lc($str);
}

# access module data
sub std_search_path { return @std_search_path; }
sub std_attrs { return @std_attrs; }

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

    # enforce class lineage
    if (not $class->isa(__PACKAGE__)) {
        croak "cannot find instance: ".(ref $class ? ref $class : $class)." is not a ".__PACKAGE__;
    }

    # initialize if not already done
    if (not defined $_instance) {
        $_instance = $class->_new_instance(@params);
    }

    # return singleton instance
    return $_instance;
}

# initialize a new instance
sub _new_instance
{
    my ($class, @params) = @_;

    # enforce class lineage
    if (not $class->isa(__PACKAGE__)) {
        croak "cannot find instance: ".(ref $class ? ref $class : $class)." is not a ".__PACKAGE__;
    }

    # obtain parameters from array or hashref
    my %obj;
    if (scalar @params > 0) {
        if (ref $params[0] eq 'HASH') {
            $obj{config} = $params[0];
        } else {
            $obj{config} = {@params};
        }
    }

    # locate os-release file in standard places
    my $osrelease_path;
    my @search_path = ((exists $obj{config}{search_path}) ? @{$obj{config}{search_path}} : @std_search_path);
    my $file_name = ((exists $obj{config}{file_name}) ? $obj{config}{file_name} : $std_file_name);
    foreach my $search_dir (@search_path) {
        if (-r "$search_dir/$file_name") {
            $osrelease_path = $search_dir."/".$file_name;
            last;
        }
    }

    # If we didn't find os-release on this system, this module has no data to start. So don't.
    if (not defined $osrelease_path) {
        return;
    }
    $obj{config}{osrelease_path} = $osrelease_path;

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
                next if $1 eq "config"; # don't overwrite config
                $obj{fold_case($1)} = $2;
            }
        }
        close $fh;
    }
    ## use critic (InputOutput::RequireBriefOpen)

    # bless instance and generate accessor methods
    my $obj_ref = bless \%obj, $class;
    $obj_ref->gen_accessors();

    # instantiate object
    return $obj_ref;
}

# test if instance is defined for testing
sub defined_instance
{
    return ((defined $_instance) and $_instance->isa(__PACKAGE__)) ? 1 : 0;
}

# attribute existence checker
sub has_attr
{
    my ($self, $key) = @_;
    return ((exists $self->{fold_case($key)}) ? 1 : 0);
}

# attribute read-only accessor
sub get
{
    my ($self, $key) = @_;
    return $self->{fold_case($key)} // undef;
}

# attribute existence checker
sub has_config
{
    my ($self, $key) = @_;
    return ((exists $self->{config}{$key}) ? 1 : 0);
}

# config read/write accessor
sub config
{
    my ($self, $key, $value) = @_;
    if (defined $value) {
        $self->{config}{$key} = $value;
    }
    return $self->{config}{$key};
}

# generate accessor methods for all defined and standardized attributes
sub gen_accessors
{
    my $self = shift;

    # generate read-only accessors for attributes actually found in os-release
    foreach my $key (sort keys %{$self}) {
        next if $key eq "config"; # protect special/reserved attribute
        $self->gen_accessor($key);
    }

    # generate undef accessors for standardized attributes which were not found in os-release
    foreach my $std_attr (@std_attrs) {
        next if $std_attr eq "config"; # protect special/reserved attribute
        my $fc_attr = fold_case($std_attr);
        next if $self->has_attr($fc_attr);
        $self->gen_accessor($fc_attr);
    }
    return;
}

# generate accessor
sub gen_accessor
{
    my ($self, $name) = @_;
    my $class = (ref $self) ? (ref $self) : $self; 
    my $method_name = $class."::".$name;

    # mark accessor flag in configuration so it can be deleted for cleanup (mainly for testing)
    if (not exists $self->{config}{accessor}) {
        $self->{config}{accessor} = {};
    }

    # generate accessor as read-only or undef depending whether it exists in the running system
    if (exists $self->{$name}) {
        # generate read-only accessor for attribute which was found in os-release
        $self->{config}{accessor}{$name} = sub { return $self->{$name} // undef };
    } else {
        # generate undef accessor for standard attribute which was not found in os-release
        $self->{config}{accessor}{$name} = sub { return; };
    }

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    *{$method_name} = $self->{config}{accessor}{$name};
    return;
}

# clean up accessor
sub clear_accessor
{
    my ($self, $name) = @_;
    my $class = (ref $self) ? (ref $self) : $self; 
    if (exists $self->{config}{accessor}{$name}) {
        my $method_name = $class."::".$name;
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        undef *{$method_name};
        delete $self->{config}{accessor}{$name};
    }
    return;
}

# clear instance for exit-cleanup or for re-use in testing
sub clear_instance
{
    if (defined $_instance) {
        # clear accessor functions
        foreach my $acc (keys %{$_instance->{config}{accessor}}) {
            $_instance->clear_accessor($acc);
        }

        # dereferencing will destroy singleton instance
        undef $_instance;
    }
    return;
}

# call destructor when program ends
END {
    Sys::OsRelease::clear_instance();
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::OsRelease - read operating system details from FreeDesktop.Org standard /etc/os-release file

=head1 VERSION

version 0.0.1

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
The os-release file is used to define an operating system environment.
It was started on Linux systems which use the systemd software, but then spread to other Linux, BSD and
Unix-based systems.
Its purpose is to identify the system to any software which needs to know.
It differentiates between Unix-based operating systems and even between Linux distributions.

Sys::OsRelease is implemented with a singleton model, meaning there is only one instance of the class.
Instead of instantiating an object with new(), the instance() class method returns the one and only instance.
The first time it's called, it instantiates it.
On following calls, it returns a reference to the existing instance.

This module maintains minimal prerequisites, and only those which are usually included with Perl.
(Suggestions of new features and code will largely depend on following this rule.)
That it intended to make it acceptable for establishing system or container environments which contain Perl programs.
It can also be used for installing or configuring software that needs to know about the system environment.

=head1 NAME

Sys::OsRelease - read operating system details from FreeDesktop.Org standard /etc/os-release file

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
