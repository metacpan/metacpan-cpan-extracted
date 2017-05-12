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

package PerlIO::via::EscStatus::ShowNone;
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
    print STDERR "pushed ", Data::Dumper::Dumper ([$class,$mode,$fh]);
  }
  return bless { parser => PerlIO::via::EscStatus::Parser->new
               }, $class;
}

*UTF8 = \&PerlIO::via::EscStatus::UTF8;
*FLUSH = \&PerlIO::via::EscStatus::FLUSH;

sub WRITE {
  my ($self, $buf, $fh) = @_;
  my ($status, $output) = $self->{'parser'}->parse($buf);
  print $fh $output or return -1;
  return length($buf);
}

1;
__END__

=head1 NAME

PerlIO::via::EscStatus::ShowNone - suppress all status lines

=head1 SYNOPSIS

 use PerlIO::via::EscStatus::ShowNone;
 binmode (STDOUT, ':via(EscStatus::ShowNone)') or die;

=head1 DESCRIPTION

C<EscStatus::ShowNone> is a variant of the EscStatus layer which doesn't
show any status lines coming through the stream at all, only the ordinary
output.  This can be used for a batch mode or non-interactive mode in a
program.

Of course for batch mode it's also possible simply not to print statuses in
the first place.  You can decide whether it's easier to check a mode flag at
the print, or push a layer to strip what's printed.  A layer may be easier
for suppressing prints from a library or independent parts of a program.

See F<examples/shownone.pl> in the PerlIO-via-EscStatus sources for a
complete program using ShowNone.

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
