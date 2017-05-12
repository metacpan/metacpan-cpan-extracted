# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.

package PerlIO::via::EscStatus::ShowAll;
use 5.008;
use strict;
use warnings;
use PerlIO::via::EscStatus;
use PerlIO::via::EscStatus::Parser;

our $VERSION = 11;

use constant DEBUG => 0;

sub PUSHED {
  my ($class, $mode, $fh) = @_;
  if (DEBUG) {
    require Data::Dumper;
    print STDERR "ShowAll pushed ", Data::Dumper::Dumper ([$class,$mode,$fh]);
  }
  return bless { partial => '' }, $class;
}

*UTF8 = \&PerlIO::via::EscStatus::UTF8;
*FLUSH = \&PerlIO::via::EscStatus::FLUSH;

sub WRITE {
  my ($self, $buf, $fh) = @_;
  my $ret_ok = length ($buf);
  if (DEBUG) { print STDERR "ShowAll write $ret_ok\n"; }

  $buf = $self->{'partial'} . $buf;

  # complete sequences
  $buf =~ s/\e_EscStatus\e\\//g;

  my $pos
    = ($buf =~ PerlIO::via::EscStatus::Parser::ESCSTATUS_STR_PARTIAL_REGEXP()
       ? $-[0] # start of match
       : length ($buf));
  $self->{'partial'} = substr ($buf, $pos); # match onwards
  $buf = substr ($buf, 0, $pos);            # prematch

  print $fh $buf or return -1;
  return $ret_ok;
}

1;
__END__

=head1 NAME

PerlIO::via::EscStatus::ShowAll - print all status lines

=head1 SYNOPSIS

 use PerlIO::via::EscStatus::ShowAll;
 binmode (STDOUT, ':via(EscStatus::ShowAll)') or die;

=head1 DESCRIPTION

This is a variant of the EscStatus layer which prints all status lines
coming through the stream, just with a newline each.  The effect is that
instead of each new status overwriting the previous they all display,
scrolling up the screen.  This is mainly intended for development or
diagnostic use.

With the current EscStatus output format this layer merely strips the
EscStatus "APC" intro control sequence and lets the rest go straight
through.  If your terminal doesn't mind miscellaneous APC sequences then it
might even be readable with no filtering at all.

See F<examples/showall.pl> in the PerlIO-via-EscStatus sources for a
complete program using ShowAll.

=head1 SEE ALSO

L<PerlIO::via::EscStatus>, L<PerlIO::via>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perlio-via-escstatus/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

PerlIO-via-EscStatus is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

PerlIO-via-EscStatus is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
PerlIO-via-EscStatus.  If not, see L<http://www.gnu.org/licenses/>.

=cut
