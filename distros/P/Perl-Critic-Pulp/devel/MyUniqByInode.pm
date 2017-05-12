# Copyright 2009, 2010, 2011, 2012 Kevin Ryde.

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


package MyUniqByInode;
use strict;
use warnings;
use SDBM_File;
use Fcntl;
use MyFileTempDBM;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class) = @_;
  ### new() ...
  my %hash;
  my $tempdbm = MyFileTempDBM->new;
  my $filename = $tempdbm->filename;
  print
    "tempfiles $filename.pag\n",
      "          $filename.dir\n";
  tie %hash, 'SDBM_File', $filename,
    Fcntl::O_RDWR() | Fcntl::O_CREAT(), 0600
        or die $!;
  return bless { tempdbm => $tempdbm,
                 hash => \%hash,
               }, $class;
}
DESTROY {
  my ($self) = @_;
  my $filename = $self->{'tempdbm'}->filename;
  my $num_keys = scalar(keys %{$self->{'hash'}});
  print "tempfile $filename $num_keys entries, sizes ",
    -s "$filename.pag"," ",
      -s "$filename.dir","\n";
  system "ls -l $filename.*";
}

sub uniq {
  my ($self, $filename_or_handle) = @_;
  ### $filename_or_handle
  
  my ($dev, $ino)
    = (ref $filename_or_handle && $filename_or_handle->can('stat')
       ? $filename_or_handle->stat
       : stat ($filename_or_handle));
  ### $dev
  ### $ino
  
  if (! defined $dev) {
    # error treated as unique
    return 1;
  }

  my $key = "$dev,$ino";
  ### $key

  my $hash = $self->{'hash'};
  ### hash: exists $hash->{$key}
  return (! exists $hash->{$key}
          && ($hash->{$key} = 1));
}

# sub stat_dev_ino {
#   my ($filename) = @_;
#   my ($dev, $ino) = stat ($filename);
#   if (! defined $dev) {
#     # print "Cannot stat: $filename\n";
#     return '';
#   }
#   return "$dev,$ino";
# }

1;
__END__

package main;
my $u = MyUniqByInode->new;
### $u
print $u->uniq('/etc/issue.net'),"\n";
print $u->uniq('/etc/issue.net'),"\n";
print $u->uniq('/etc/issue.net'),"\n";
print $u->uniq('/etc/issue.net'),"\n";
print "keys ",keys $u->{'hash'},"\n";
exit 0;

