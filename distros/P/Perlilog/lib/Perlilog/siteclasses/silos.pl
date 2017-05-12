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

sub who {
  my $self = shift;
  return "Silos Obj. \'".$self->get('name')."\'";
}

sub makesilosfile {
  my $self = shift;
  my $g = $self->globalobj();

  my $dir=$g->get('filesdir');

  open (FILE, ">$dir/perlilog.spj") || 
    blow("Failed to open project file $dir/perlilog.spj\n");

  print FILE "[Files]\n";
  my $i=0;
  my $f;
  foreach ($g->get('verilogfiles')) {
    ($f)=/.*?([^\/]*)$/;
    print FILE "$i=$f\n";
    $i++;
  }
  print FILE "\n[Settings]\nMode=Debug\n";
  close FILE;
}

