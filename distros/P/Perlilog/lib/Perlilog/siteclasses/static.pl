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

${__PACKAGE__.'::errorcrawl'}='system';
sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);
    
  $self -> const('static', 1);
  return $self;
}  

sub who {
  my $self = shift;
  return "Static Verilog Obj. \'".$self->get('name')."\'";
}

sub sanity {
  my $self = shift;
  $self->SUPER::sanity(@_);

  my $file = $self -> get('source');
  wrong($self->who." declared without the \'source\' property set\n")
    unless (defined $file);
  wrong($self->who.
	" has property \'source\' set to ".$self->prettyval($file).
	", which is a nonexistent file\n")
    unless (-e $file);
}

sub generate {
  my $self = shift;
  my $file =  $self -> get('source');

  blow("Failed to open \'$file\', the source file of ".
       $self->who()."\n") unless open(FILE, $file);

  $self->const('verilog', join('', <FILE>));
  close FILE;
}
