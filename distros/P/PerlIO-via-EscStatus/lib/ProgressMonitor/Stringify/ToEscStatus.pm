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


package ProgressMonitor::Stringify::ToEscStatus;
use 5.008;
use strict;
use warnings;
use ProgressMonitor::State qw(STATE_DONE);
use PerlIO::via::EscStatus;

our $VERSION = 11;

use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitor',
  new     => 'new';

# no private instance data to initialize
sub new {
  my ($class, $cfg) = @_;
  return $class->SUPER::_new($cfg, $CLASS);
}

sub render {
  my ($self) = @_;
  my $cfg = $self->_get_cfg;
  my $fh  = $cfg->get_stream;

  my $str;
  if ($self->_get_state == STATE_DONE) {
    $str = '';

  } else {
    $str = $self->_toString (1);          # with messages
    if (my $pos = rindex ($str, "\n")) {  # message part as ordinary print
      print $fh substr ($str, 0, $pos+1);
      $str = substr ($str, $pos+1);
    }
  }
  print $fh PerlIO::via::EscStatus::make_status ($str);
}

sub setErrorMessage {
  my ($self, $msg) = @_;
  $msg = $self->SUPER::setErrorMessage ($msg);
  if ($msg) {
    my $fh = $self->_get_cfg->get_stream;
    print $fh $msg,"\n";
  }
}


package ProgressMonitor::Stringify::ToEscStatusConfiguration;
use strict;
use warnings;
use Scalar::Util;

use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitorConfiguration',
  attrs   => ['stream'];

sub defaultAttributeValues {
  my ($self) = @_;
  my $hashref = $self->SUPER::defaultAttributeValues;
  $hashref = { stream => \*STDOUT,
               %$hashref };

  # override superclass default, since EscStatus truncates itself
  $hashref->{'maxWidth'} = 999_999;

  return $hashref;
}

sub checkAttributeValues {
  my ($self) = @_;
  $self->SUPER::checkAttributeValues;

  my $fh = $self->get_stream;
  if (! Scalar::Util::openhandle ($fh)) {
    X::Usage->throw ('not an open handle');
  }
}

1;
__END__

=head1 NAME

ProgressMonitor::Stringify::ToEscStatus - monitor printing in EscStatus form

=head1 SYNOPSIS

 use PerlIO::via::EscStatus;
 binmode (STDOUT, ':via(EscStatus)') or die;

 use ProgressMonitor::Stringify::ToEscStatus;
 my $mon = ProgressMonitor::Stringify::ToEscStatus->new
   ({ fields => [
        ProgressMonitor::Stringify::Fields::Spinner->new
   ]});

 $mon->prepare;
 $mon->begin;
 $mon->tick; $mon->tick; # etc
 $mon->end;

=head1 CLASS HIERARCHY

C<ToEscStatus> is a subclass of C<AbstractMonitor>,

    ProgressMonitor
      ProgressMonitor::AbstractStatefulMonitor
        ProgressMonitor::Stringify::AbstractMonitor
          ProgressMonitor::Stringify::ToEscStatus

=head1 DESCRIPTION

ToEscStatus implements a ProgressMonitor which prints status lines in
EscStatus form, ready to be shown by an EscStatus layer on the output
stream.

Basically where C<ProgressMonitor::Stringify::ToStream> would do something
like C<< print "\rStatus line" >>, the ToEscStatus instead does

    print make_status("Status line")

giving the output form EscStatus uses.  The contents of the status line are
built by the configured C<ProgressMonitor> field objects in the usual way.
See F<examples/progressmonitor.pl> in the EscStatus sources for a complete
program.

=head1 FUNCTIONS

=over 4

=item C<< ProgressMonitor::Stringify::ToEscStatus->new({key=>value,...}) >>

Create and return a new ToEscStatus progress monitor object.  Configuration
parameters are taken in usual Moose style as a single hashref argument.
This will normally at least include a C<fields> array of objects to do the
rendering.

See L<ProgressMonitor::Stringify::AbstractMonitor> for the base
configuration parameters.  ToEscStatus has the following additional
parameters

=over 4

=item C<stream> (default C<STDOUT>)

A file handle to write to.  The default is standard output, ie. C<\*STDOUT>
(the same as C<ProgressMonitor::Stringify::ToStream>).

ToEscStatus doesn't check what layers are on the stream.  If for instance
you're printing to tty then it's your responsibility to push a
C<PerlIO::via::EscStatus>.  Similarly it's your responsibility to set
C<:utf8> mode or not, as desired.

=back

=back

=head1 SEE ALSO

L<ProgressMonitor>, L<PerlIO::via::EscStatus>, L<Moose>

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
