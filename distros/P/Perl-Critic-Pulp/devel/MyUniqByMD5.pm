# Copyright 2009, 2010, 2011, 2012 Kevin Ryde.

# MyUniqByMD5.pm is shared by various distributions.
#
# MyUniqByMD5.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyUniqByMD5.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyUniqByMD5;
use strict;
use warnings;
use SDBM_File;
use Digest::MD5;
use MyFileTempDBM;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class) = @_;
  my %hash;
  my $tempdbm = MyFileTempDBM->new;
  my $filename = $tempdbm->filename;
  tie %hash, 'SDBM_File',
    $filename,
      Fcntl::O_RDWR() | Fcntl::O_CREAT(),
          0600
            or die $!;
  return bless { tempdbm => $tempdbm,
                 seen => \%hash,
               }, $class;
}

sub uniq_filename {
  my ($self, $filename) = @_;
  ### uniq_filename(): $filename
  open my $fh, $filename
    or return 1;  # error as if unique
  return $self->uniq_fh ($fh);
}

sub uniq_fh {
  my ($self, $fh) = @_;
  ### uniq_fh(): $fh
  my $md5obj = Digest::MD5->new;
  $md5obj->addfile($fh);
  return $self->uniq_md5 ($md5obj->hexdigest)
}

sub uniq_str {
  my ($self, $str) = @_;
  return $self->uniq_md5 (Digest::MD5::md5 ($str));
}

sub uniq_md5 {
  my ($self, $md5) = @_;
  ### uniq_md5(): $md5

  ### seen: exists $self->{'seen'}->{$md5}
  # if (exists $self->{'seen'}->{$md5}) { print "MyUniqByMD5: suppress\n"; }

  my $seen = $self->{'seen'};
  return (! exists $seen->{$md5}
          && ($seen->{$md5} = 1));
}

1;
__END__

package main;
my $uniq = MyUniqByMD5->new;
print $uniq->uniq_filename('/etc/passwd'),"\n";
print $uniq->uniq_filename('/etc/passwd'),"\n";
exit 0;

