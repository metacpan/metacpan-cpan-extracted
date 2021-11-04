#+##############################################################################
#                                                                              #
# File: No/Worries/Dir.pm                                                      #
#                                                                              #
# Description: directory handling without worries                              #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Dir;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries qw($_IntegerRegexp);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate :types);

#
# change the working directory
#

sub dir_change ($) {
    my($path) = @_;

    chdir($path) or dief("cannot chdir(%s): %s", $path, $!);
}

#
# ensure that a directory exists
#

# really make a directory, recursively

sub _mkdir ($$);
sub _mkdir ($$) {
    my($path, $mode) = @_;

    if ($path =~ m{^(.+)/[^/]+$} and not -d $1) {
        _mkdir($1, $mode);
    }
    mkdir($path, $mode)
        or dief("cannot mkdir(%s, %04o): %s", $path, $mode, $!);
}

# public interface

my %dir_ensure_options = (
    mode => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
);

sub dir_ensure ($@) {
    my($path, %option);

    $path = shift(@_);
    %option = validate(@_, \%dir_ensure_options) if @_;
    $option{mode} = oct(777) unless defined($option{mode});
    $path =~ s{/+$}{};
    _mkdir($path, $option{mode}) unless $path eq "" or -d $path;
}

#
# make a directory
#

my %dir_make_options = (
    mode => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
);

sub dir_make ($@) {
    my($path, %option);

    $path = shift(@_);
    %option = validate(@_, \%dir_make_options) if @_;
    $option{mode} = oct(777) unless defined($option{mode});
    mkdir($path, $option{mode})
        or dief("cannot mkdir(%s, %04o): %s", $path, $option{mode}, $!);
}

#
# return the parent directory of the given path
#

sub dir_parent ($) {
    my($path) = @_;

    return(".") if $path eq "";
    $path =~ s{/+$}{};
    return("/") if $path eq "";
    $path =~ s{[^/]+$}{};
    return(".") if $path eq "";
    $path =~ s{/+$}{};
    return("/") if $path eq "";
    return($path);
}

#
# read a directory
#

sub dir_read ($) {
    my($path) = @_;
    my($dh, @list);

    opendir($dh, $path) or dief("cannot opendir(%s): %s", $path, $!);
    @list = grep($_ !~ /^\.\.?$/, readdir($dh));
    closedir($dh) or dief("cannot closedir(%s): %s", $path, $!);
    return(@list);
}

#
# remove a directory
#

sub dir_remove ($) {
    my($path) = @_;

    rmdir($path) or dief("cannot rmdir(%s): %s", $path, $!);
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++,
         map("dir_$_", qw(change ensure make parent read remove)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::Dir - directory handling without worries

=head1 SYNOPSIS

  use No::Worries::Dir
      qw(dir_change dir_ensure dir_make dir_parent dir_read dir_remove);

  # change directory
  dir_change("/tmp");

  # make sure a directory exists (not an error if it exists already)
  dir_ensure("/tmp/some/path", mode => oct(770));

  # make a directory (an error if it exists already)
  dir_make("/tmp/some/path", mode => oct(770));

  # find out the parent directory of some path
  $parent = dir_parent($path);
  dir_ensure($parent);

  # read a directory
  foreach $name (dir_read("/etc")) {
      ...
  }

  # remove a directory
  dir_remove("/tmp/some/path");

=head1 DESCRIPTION

This module eases directory handling by providing convenient wrappers around
standard directory functions. All the functions die() on error.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item dir_change(PATH)

change the working directory to the given path; this is a safe thin wrapper on
top of chdir()

=item dir_ensure(PATH[, OPTIONS])

make sure the given path is an existing directory, creating it (including its
parents) if needed; supported options:

=over

=item * C<mode>: numerical mode to use for mkdir() (default: oct(777))

=back

=item dir_make(PATH[, OPTIONS])

make the given directory; this is a safe thin wrapper on top of mkdir();
supported options:

=over

=item * C<mode>: numerical mode to use for mkdir() (default: oct(777))

=back


=item dir_parent(PATH)

return the parent directory of the given path

=item dir_read(PATH)

read the given directory and return its list of entries except C<.> and C<..>

=item dir_remove(PATH)

remove the given directory (that must exist and be empty); this is a safe thin
wrapper on top of rmdir()

=back

=head1 SEE ALSO

L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
