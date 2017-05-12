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

# Perlilog's basic port class
${__PACKAGE__.'::errorcrawl'}='system';

sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);

  puke($self->who()." does not have a parent\n")
    unless (ref($self->get('parent')));

  return $self;
}

sub who {
  my $self = shift;

  my $parent = $self->get('parent');
  my $owned = $self->isobject($parent) ? ' owned by '.$parent->who : '';

  my $sus = $self -> get('perlilog-transient');

  if (not (defined $sus)) {
    return "port \'".$self->get('name')."\'$owned";
  } elsif ($sus eq 'transient') {
    return "(transient) port \'".$self->get('nick')."\'$owned";
  } else {
    return "auto. gen. port \'".$self->get('name')."\'$owned";
  }
}

# We override the setparent method for ports.
sub setparent {
  my ($self, $papa)=@_;
  $self->const('parent', $papa);
  $papa->ppush('ports',$self);
}
