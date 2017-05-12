#
# This file is part of the Perlilog project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

# Perlilog's interface class
${__PACKAGE__.'::errorcrawl'}='system';

sub sustain {
  my $self = shift;
  $self->SUPER::sustain(@_);
  my @ports=$self->get('perlilog-ports-to-connect');
  my ($i, $tmp);

  # We now set the 'mates' property, which is supposed to
  # point at the closest counterpart that the port is connected
  # with. Note that we don't care if 'mates' was already set, but
  # we just set it to our value. This assures that 'mates'
  # will be set according to the pairing that was made at the
  # latest stage, hence the closest one. If this gets messed up,
  # it's probably because some interface class messed up the
  # order of the returned object list.

  for ($i=0; $i<=$#ports; $i++) {
    $tmp = shift @ports;
    $tmp->set('mates', @ports);

    push @ports, $tmp;
  }  
}

sub who {
  my $self = shift;
  my $sus = $self -> get('perlilog-transient');

  if (not (defined $sus)) {
    return "Int. obj. \'".$self->get('name')."\'";
  } elsif ($sus eq 'transient') {
    return "(transient) Int. obj. \'".$self->get('nick')."\'";
  } else {
    return "auto. gen. int. obj. \'".$self->get('name')."\'";
  }
}

sub complete {
  my $self = shift;
  $self->SUPER::complete(@_);

  my $papa = $self->get('parent');
  # If the interface object doesn't have a parent, its parent is the
  # first port's owner's parent.
  unless (ref $papa) {
    my $port;
    foreach $port ($self->get('perlilog-ports-to-connect')) {
      $papa=$port->get('parent')->get('parent');
      last if (ref $papa);
    }
    $self->setparent($papa);
  }
}

# Just a shortcut to core intobjects
sub intobjects {
  my $self = shift;
  return &Perlilog::intobjects(@_);
}

