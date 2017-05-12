#
# This file is part of PerlIO-via-Timeout
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package PerlIO::via::Timeout;
$PerlIO::via::Timeout::VERSION = '0.32';
# ABSTRACT: a PerlIO layer that adds read & write timeout to a handle

require 5.008;
use Time::HiRes;
use strict;
use warnings;
use Carp;
use Errno qw(EBADF EINTR ETIMEDOUT);

use Exporter 'import'; # gives you Exporter's import() method directly

our @EXPORT_OK = qw(read_timeout write_timeout enable_timeout disable_timeout timeout_enabled);

our %EXPORT_TAGS = (all => [@EXPORT_OK]);


sub _get_fd {
    # params: FH
    $_[0] or return;
    my $fd = fileno $_[0];
    defined $fd && $fd >= 0
      or return;
    $fd;
}

my %fd2prop;

sub _fh2prop {
    # params: self, $fh
    my $prop = $fd2prop{ my $fd = _get_fd $_[1]
                         or croak 'failed to get file descriptor for filehandle' };
    wantarray and return ($prop, $fd);
    return $prop;
}

sub PUSHED {
    # params CLASS, MODE, FH
    $fd2prop{_get_fd $_[2]} = { timeout_enabled => 1, read_timeout => 0, write_timeout => 0};
    bless {}, $_[0];
}

sub POPPED {
    # params: SELF [, FH ]
    delete $fd2prop{_get_fd($_[1]) or return};
}

sub CLOSE {
    # params: SELF, FH
    delete $fd2prop{_get_fd($_[1]) or return -1};
    close $_[1] or -1;
}

sub READ {
    # params: SELF, BUF, LEN, FH
    my ($self, undef, $len, $fh) = @_;

    # There is a bug in PerlIO::via (possibly in PerlIO ?). We would like
    # to return -1 to signify error, but doing so doesn't work (it usually
    # segfault), it looks like the implementation is not complete. So we
    # return 0.
    my ($prop, $fd) = __PACKAGE__->_fh2prop($fh);

    my $timeout_enabled = $prop->{timeout_enabled};
    my $read_timeout    = $prop->{read_timeout};

    my $offset = 0;
    while ($len) {
        if ( $timeout_enabled && $read_timeout && $len && ! _can_read_write($fh, $fd, $read_timeout, 0)) {
            $! ||= ETIMEDOUT;
            return 0;
        }
        my $r = sysread($fh, $_[1], $len, $offset);
        if (defined $r) {
            last unless $r;
            $len -= $r;
            $offset += $r;
        }
        elsif ($! != EINTR) {
            # There is a bug in PerlIO::via (possibly in PerlIO ?). We would like
            # to return -1 to signify error, but doing so doesn't work (it usually
            # segfault), it looks like the implementation is not complete. So we
            # return 0.
            return 0;
        }
    }
    return $offset;
}

sub WRITE {
    # params: SELF, BUF, FH
    my ($self, undef, $fh) = @_;

    my ($prop, $fd) = __PACKAGE__->_fh2prop($fh);

    my $timeout_enabled = $prop->{timeout_enabled};
    my $write_timeout   = $prop->{write_timeout};

    my $len = length $_[1];
    my $offset = 0;
    while ($len) {
        if ( $len && $timeout_enabled && $write_timeout && ! _can_read_write($fh, $fd, $write_timeout, 1)) {
            $! ||= ETIMEDOUT;
            return -1;
        }
        my $r = syswrite($fh, $_[1], $len, $offset);
        if (defined $r) {
            $len -= $r;
            $offset += $r;
            last unless $len;
        }
        elsif ($! != EINTR) {
            return -1;
        }
    }
    return $offset;
}

sub _can_read_write {
    my ($fh, $fd, $timeout, $type) = @_;
    # $type: 0 = read, 1 = write
    my $initial = Time::HiRes::time;
    my $pending = $timeout;
    my $nfound;

    vec(my $fdset = '', $fd, 1) = 1;

    while () {
        if ($type) {
            # write
            $nfound = select(undef, $fdset, undef, $pending);
        } else {
            # read
            $nfound = select($fdset, undef, undef, $pending);
        }
        if ($nfound == -1) {
            $! == EINTR
              or croak(qq/select(2): '$!'/);
            redo if !$timeout || ($pending = $timeout - (Time::HiRes::time -
            $initial)) > 0;
            $nfound = 0;
        }
        last;
    }
    $! = 0;
    return $nfound;
}


sub read_timeout {
    my $prop = __PACKAGE__->_fh2prop($_[0]);
    @_ > 1 and $prop->{read_timeout} = $_[1] || 0, _check_attributes($prop);
    $prop->{read_timeout};
}


sub write_timeout {
    my $prop = __PACKAGE__->_fh2prop($_[0]);
    @_ > 1 and $prop->{write_timeout} = $_[1] || 0, _check_attributes($prop);
    $prop->{write_timeout};
}


sub _check_attributes {
    grep { $_[0]->{$_} < 0 } qw(read_timeout write_timeout)
      and croak "if defined, 'read_timeout' and 'write_timeout' attributes should be >= 0";
}


sub enable_timeout { timeout_enabled($_[0], 1) }


sub disable_timeout { timeout_enabled($_[0], 0) }


sub timeout_enabled {
    my $prop = __PACKAGE__->_fh2prop($_[0]);
    @_ > 1 and $prop->{timeout_enabled} = !!$_[1];
    $prop->{timeout_enabled};
}


sub has_timeout_layer {
    defined (my $fd = _get_fd($_[0]))
      or return;
    exists $fd2prop{$fd};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlIO::via::Timeout - a PerlIO layer that adds read & write timeout to a handle

=head1 VERSION

version 0.32

=head1 SYNOPSIS

  use Errno qw(ETIMEDOUT);
  use PerlIO::via::Timeout qw(:all);
  open my $fh, '<:via(Timeout)', 'foo.html';

  # set the timeout layer to be 0.5 second read timeout
  read_timeout($fh, 0.5);

  my $line = <$fh>;
  if ($line == undef && 0+$! == ETIMEDOUT) {
    # timed out
    ...
  }

=head1 DESCRIPTION

This package implements a PerlIO layer, that adds read / write timeout. This
can be useful to avoid blocking while accessing a handle (file, socket, ...),
and fail after some time.

The timeout is implemented by using C<<select>> on the handle before
reading/writing.

B<WARNING> the handle won't timeout if you use C<sysread> or C<syswrite> on it,
because these functions works at a lower level. However if you're trying to
implement a timeout for a socket, see L<IO::Socket::Timeout> that implements
exactly that.

=head1 FUNCTIONS

=head2 read_timeout

  # set a read timeout of 2.5 seconds
  read_timeout($fh, 2.5);
  # get the current read timeout
  my $secs = read_timeout($fh);

Getter / setter of the read timeout value.

=head2 write_timeout

  # set a write timeout of 2.5 seconds
  write_timeout($fh, 2.5);
  # get the current write timeout
  my $secs = write_timeout($fh);

Getter / setter of the write timeout value.

=head2 enable_timeout

  enable_timeout($fh);

Equivalent to setting timeout_enabled to 1

=head2 disable_timeout

  disable_timeout($fh);

Equivalent to setting timeout_enabled to 0

=head2 timeout_enabled

  # disable timeout
  timeout_enabled($fh, 0);
  # enable timeout
  timeout_enabled($fh, 1);
  # get the current status
  my $is_enabled = timeout_enabled($fh);

Getter / setter of the timeout enabled flag.

=head2 has_timeout_layer

  if (has_timeout_layer($fh)) {
    # set a write timeout of 2.5 seconds
    write_timeout($fh, 2.5);
  }

Returns wether the given filehandle is managed by PerlIO::via::Timeout.

=head1 SEE ALSO

=over

=item L<PerlIO::via>

=back

=head1 THANKS TO

=over

=item Vincent Pit

=item Christian Hansen

=item Leon Timmmermans

=back

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
