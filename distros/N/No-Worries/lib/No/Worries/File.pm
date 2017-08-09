#+##############################################################################
#                                                                              #
# File: No/Worries/File.pm                                                     #
#                                                                              #
# Description: file handling without worries                                   #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::File;
use strict;
use warnings;
our $VERSION  = "1.5";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries qw($_IntegerRegexp);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate :types);

#
# global variables
#

our($DefaultBufSize);

#
# open() helper
#

sub _open ($$$) {
    my($path, $mode, $opt) = @_;
    my($fh);

    return($opt->{handle}) if $opt->{handle};
    ## no critic 'InputOutput::RequireBriefOpen'
    open($fh, $mode, $path) or dief("cannot open(%s): %s", $path, $!);
    if ($opt->{binmode}) {
        binmode($fh, $opt->{binmode})
            or dief("cannot binmode(%s, %s): %s", $path, $opt->{binmode}, $!);
    } elsif ($opt->{binary}) {
        binmode($fh)
            or dief("cannot binmode(%s): %s", $path, $!);
    }
    return($fh);
}

#
# sysread() helper
#

sub _read ($$$$) {
    my($path, $fh, $data, $bufsize) = @_;
    my($done, $ref, $result);

    $done = -1;
    $ref = $data ? ref($data) : "";
    if ($ref eq "SCALAR") {
        # by reference
        ${ $data } = "";
        while ($done) {
            $done = sysread($fh, ${ $data }, $bufsize, length(${ $data }));
            dief("cannot sysread(%s): %s", $path, $!)
                unless defined($done);
        }
        $result = $data;
    } elsif ($ref eq "CODE") {
        # by code
        while ($done) {
            $result = "";
            $done = sysread($fh, $result, $bufsize);
            dief("cannot sysread(%s): %s", $path, $!)
                unless defined($done);
            $data->($result) if $done;
        }
        $result = $data->("");
    } else {
        # normal
        $result = "";
        while ($done) {
            $done = sysread($fh, $result, $bufsize, length($result));
            dief("cannot sysread(%s): %s", $path, $!)
                unless defined($done);
        }
    }
    return(\$result);
}

#
# syswrite() helper
#

sub _write ($$$$) {
    my($path, $fh, $data, $bufsize) = @_;
    my($ref, $offset, $length, $done, $chunk);

    $offset = 0;
    $ref = ref($data);
    if ($ref eq "SCALAR") {
        # by reference
        $length = length(${ $data });
        while ($length) {
            $done = syswrite($fh, ${ $data }, $bufsize, $offset);
            dief("cannot syswrite(%s): %s", $path, $!)
                unless defined($done);
            $length -= $done;
            $offset += $done;
        }
    } elsif ($ref eq "CODE") {
        # by code
        while (1) {
            $chunk = $data->();
            $length = length($chunk);
            last unless $length;
            $offset = 0;
            while ($length) {
                $done = syswrite($fh, $chunk, $bufsize, $offset);
                dief("cannot syswrite(%s): %s", $path, $!)
                    unless defined($done);
                $length -= $done;
                $offset += $done;
            }
        }
    } else {
        # normal
        $length = length($data);
        while ($length) {
            $done = syswrite($fh, $data, $bufsize, $offset);
            dief("cannot syswrite(%s): %s", $path, $!)
                unless defined($done);
            $length -= $done;
            $offset += $done;
        }
    }
}

#
# common read/write options
#

my %file_rw_options = (
    binary  => { optional => 1, type => BOOLEAN },
    binmode => { optional => 1, type => SCALAR },
    bufsize => { optional => 1, type => SCALAR, regex => $_IntegerRegexp },
    handle  => { optional => 1, type => HANDLE },
);

#
# read from a file
#

my %file_read_options = (%file_rw_options,
    data    => { optional => 1, type => SCALARREF | CODEREF },
);

sub file_read ($@) {
    my($path, %option, $fh, $result);

    $path = shift(@_);
    %option = validate(@_, \%file_read_options) if @_;
    $option{bufsize} ||= $DefaultBufSize;
    $fh = _open($path, "<", \%option);
    $result = _read($path, $fh, $option{data}, $option{bufsize});
    close($fh) or dief("cannot close(%s): %s", $path, $!);
    return(${ $result });
}

#
# write to a file
#

my %file_write_options = (%file_rw_options,
    data    => { optional => 0, type => SCALAR | SCALARREF | CODEREF },
);

sub file_write ($@) {
    my($path, %option, $fh);

    $path = shift(@_);
    %option = validate(@_, \%file_write_options);
    $option{bufsize} ||= $DefaultBufSize;
    $fh = _open($path, ">", \%option);
    _write($path, $fh, $option{data}, $option{bufsize});
    close($fh) or dief("cannot close(%s): %s", $path, $!);
}

#
# module initialization
#

$DefaultBufSize = 1_048_576; # 1MB

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, map("file_$_", qw(read write)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::File - file handling without worries

=head1 SYNOPSIS

  use No::Worries::File qw(file_read file_write);

  # read a file
  $data = file_read($path);

  # idem but with data returned by reference
  file_read($path, data => \$data);

  # write a file
  file_write($path, data => "hello world");

  # idem but with data passed by reference
  file_write($path, data => \"hello world");

=head1 DESCRIPTION

This module eases file handling by providing convenient wrappers around
standard file functions. All the functions die() on error.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item file_read(PATH[, OPTIONS])

read the file at the given path and return its contents; supported options:

=over

=item * C<binary>: treat the file as binary

=item * C<binmode>: binary mode to use

=item * C<bufsize>: buffer size to use for I/O operations

=item * C<data>: return the file contents via this scalar reference or code
reference

=item * C<handle>: file handle to use

=back

=item file_write(PATH[, OPTIONS])

write the given contents to the file at the given path; supported options:

=over

=item * C<binary>: treat the file as binary

=item * C<binmode>: binary mode to use

=item * C<bufsize>: buffer size to use for I/O operations

=item * C<data>: provide the file contents via this scalar, scalar reference
or code reference

=item * C<handle>: file handle to use

=back

=back

=head1 OPTIONS

Both functions support a C<handle> option that can contain a file handle to
use. When given, this handle will be used (and closed at the end of the I/O
operations) as is, without calling binmode() on it (see below).

These functions also support a C<binary> option and a C<binmode> option
specifying how the file handle should be treated with respect to binmode().

If C<binmode> is set, binmode() will be used with the given layer.

If C<binmode> is not set but C<binary> is true, binmode() will be used without
any layer.

If neither C<binmode> nor C<binary> are set, binmode() will not be used. This
is the default.

file_read() can be given a code reference via the C<data> option. Each time
data is read via sysread(), the subroutine will be called with the read data.
At the end of the file, the subroutine will be called with an empty string.

file_write() can be given a code reference via the C<data> option. It should
return data in a way similar to sysread(), returning an empty string to
indicate the end of the data to be written to the file.

=head1 GLOBAL VARIABLES

This module uses the following global variables (none of them being exported):

=over

=item $DefaultBufSize

default buffer size to use for I/O operations if not specified via the
C<bufsize> option (default: 1MB)

=back

=head1 SEE ALSO

L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2017
