# Copyright 2007, 2008, 2010 Kevin Ryde

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

package PerlIO::via::EscStatus;
use strict;
use warnings;
use Carp;
use Scalar::Util;

our $VERSION = 0;

use constant DEBUG => 0;

my $global;

# use Devel::StackTrace;
#   print STDERR Devel::StackTrace->new->as_string;

# my %packagename_to_obj;
#   $packagename_to_obj{$packagename} = $self;

use Data::Dumper;

sub new {
  my ($class) = @_;
  my $self = { shown  => 0, status => '' };
  my $newclass = 'PerlIO::via::EscStatus::Instance::' . ($self + 0);
  eval "package $newclass;";
  { no strict 'refs';
    @{"${newclass}::ISA"} = ('PerlIO::via::EscStatus::Instance');
    ${"${newclass}::self"} = $self;
    Scalar::Util::weaken (${"${newclass}::self"});
  }
  bless $self, $newclass;

  return $self;
}

sub PUSHED {
  croak "don't push PerlIO::via::EscStatus, get an instance and push \$tt->layer_string";
}


package PerlIO::via::EscStatus::Instance;
use strict;
use warnings;
use Term::Size;
use Text::Tabs ();
use List::Util qw(min max);

use constant DEBUG => PerlIO::via::EscStatus::DEBUG;

sub DESTROY {
  my ($self) = @_;
  if (DEBUG) { print STDERR "destroy $self\n"; }
  require Symbol;
  Symbol::delete_package (ref $self);
}

sub layer_string {
  my ($self) = @_;
  return ':via(' . ref($self) . ')';
}

sub PUSHED {
  my ($class, $mode, $fh) = @_;
  if (DEBUG) {
    require Data::Dumper;
    print STDERR "pushed ", Data::Dumper::Dumper ([$class,$mode,$fh]);
  }
  my $self = do { no strict 'refs';
                  ${"${class}::self"} };
  if (DEBUG) {
    require Data::Dumper;
    print STDERR "self ", Data::Dumper::Dumper(\$self);
  }
  push @{$self->{'fh_list'}}, $fh;
  return $self;
}

sub POPPED {
  my ($self, $fh) = @_;
  if (DEBUG) { print STDERR "pop $self\n"; }
  $self->set_status(undef);
  my $fh_list = $self->{'fh_list'};
  @$fh_list = grep {$_ != $fh} @$fh_list;
}

sub CLOSE {
  my ($self, $fh) = @_;
  if (DEBUG) { print STDERR "close $self\n"; }
  my $ret = $self->set_status(undef) ? 0 : -1;
  my $fh_list = $self->{'fh_list'};
  @$fh_list = grep {$_ != $fh} @$fh_list;
  return $ret;
}

# return true if ok
sub set_status {
  my ($self, $str) = @_;
  if (! defined $str) { $str = ''; }

  if (DEBUG) {
    require Data::Dumper;
    print STDERR "set_status ", Data::Dumper::Dumper ($self);
  }

  my $fh = $self->{'fh_list'}->[0];
  if (! $fh) { return 1; }

  $str =~ s/\n/ /g;
  $str = Text::Tabs::expand ($str);

  my $old_status = $self->{'status'};
  $self->{'status'} = $str;
  if ($old_status eq $str || ! $self->{'shown'}) { return 1; }


  $self->{'shown'} = (length($str) != 0);
  print $fh $str, (' ' x max (0, length($old_status) - length($str))),
    "\r" or return 0;
  _flush ($fh) or return 0;
  return 1;
}

sub WRITE {
  my ($self, $buf, $fh) = @_;
  my $flush = 0;

  if (my $status = $self->{'status'}) {
    my $tty_width
      = ($self->{'tty_width'} ||= (Term::Size::chars($fh) || 80));
    $status = substr ($status, 0, $tty_width-1);

    if ($self->{'shown'}) {
      # ensure status text is overwritten
      my $status_len = length ($status);
      my $pos = index ($buf, "\n");
      if ($pos < 0) {
        if (length_with_tabs($buf) < $status_len) {
          $buf = (' ' x $status_len) . "\r" . $buf;
        }
      } else {
        my $pre = substr($buf,0,$pos);
        my $spaces = max (0, length($status) - length_with_tabs($pre));
        $buf = $pre . (' ' x $spaces) . substr($buf,$pos);
      }
      $self->{'shown'} = 0;
    }

    if (substr($buf,-1,1) eq "\n") {
      $buf .= $status . "\r";
      $self->{'shown'} = 1;
      $flush = 1;
    }
  }
  print $fh $buf or return 0;
  if ($flush) {
    _flush ($fh) or return 0;
  }
  return length($buf);
}

sub _flush {
  my ($fh) = @_;
  if ($fh->can('flush')) {
    return $fh->flush;
  } else {
    my $old_fh = select $fh;
    if (! $|) {
      $| = 1;
      $| = 0;
    }
    select $old_fh;
    return 1;
  }
}

sub length_with_tabs {
  my ($str) = @_;
  $str = Text::Tabs::expand ($str);
  return length($str);
}

1;
__END__

=head1 NAME

PerlIO::via::EscStatus - layer for carriage-return status display

=head1 SYNOPSIS

 use PerlIO::via::EscStatus;
 binmode (STDOUT, ':via(PerlIO::via::EscStatus)') or die;

 PerlIO::via::EscStatus->set_status ('20% finished');
 print "A message here.\n";
 PerlIO::via::EscStatus->set_status ('30% finished');
 print "Another message here.\n";

=head1 DESCRIPTION

EscStatus prints a status line on a dumb terminal using carriage return
("\r").  Each new status overwrites the old, and any current status is
erased before letting normal output go through, so it's not obscured.

The status is not printed until a newline is reached in the normal output,
so if the normal output is coming in dribs and drabs it's only when the line
is finished that the status is shown.

=head1 FUNCTIONS

=over 4

=item C<< PerlIO::via::EscStatus->set_status ($str) >>

Set the status string to be displayed, with an empty string or C<undef> for
no status at all.

=back

=head1 SEE ALSO

L<PerlIO::via>

=cut
