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

sub attempt {
  my $this = shift;

  # All vars?
  return undef 
    if (grep {ref ne 'vars'} @_);

  my $self = $this->new(nick => 'vars_connection');
  return $self;

}

sub generate {
  my $self = shift;

  # Get the ports to connect...
  my @ports = $self->get('perlilog-ports-to-connect');

  my %conn = ();
  foreach my $port (@ports) {
    my %h = $self->labelID($port);
    { # We disable warnings for this block...
      local $SIG{__WARN__};
      $SIG{__WARN__} = sub { }; # No warnings here, please

      foreach my $label (sort keys %h) {
	$conn{$label} = join(',', (split(',', $conn{$label}), $h{$label}));
      }
    }
  }

  foreach my $label (sort keys %conn) {
    my @IDs = split(',', $conn{$label});
    my $first = shift(@IDs);
    fishy("The label \'$label\' has no counterpart while connecting the following ports:\n".
	  join("\n", map {$self->safewho($_); } @ports)."\n")
      unless @IDs;
    foreach my $second (@IDs) {
      $self->attach($first, $second);
    }
  }
}
