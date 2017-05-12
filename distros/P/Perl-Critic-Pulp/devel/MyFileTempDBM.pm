# Copyright 2012 Kevin Ryde.

# MyUniqByInode.pm is shared by various distributions.
#
# MyUniqByInode.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyUniqByInode.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


# sdbm
# /so/perl/perl-5.10.0/ext/SDBM_File/sdbm/sdbm.3
#
# /usr/include/gdbm.h -- single file
# ndbm,odbm using gdbm
#
# db
# 

package MyFileTempDBM;
use strict;
use File::Spec;
use File::Temp 0.19; # version 0.19 for newdir()

sub new {
  my ($class) = @_;
  my $dir = File::Temp->newdir;
  return bless { dirobj   => $dir,
                 filename => File::Spec->catfile ($dir->dirname, 'temp.sdbm'),
               }, $class;

}
sub filename {
  my ($self) = @_;
  return $self->{'filename'};
}
sub dirname {
  my ($self) = @_;
  return $self->{'dirobj'}->dirname;
}
sub DESTROY {
  my ($self) = @_;
  unlink "$self->{'filename'}.dir";
  unlink "$self->{'filename'}.pag";
  unlink "$self->{'filename'}.sdbm_dir";  # on VMS, according to sdbm.h
}

1;
__END__
