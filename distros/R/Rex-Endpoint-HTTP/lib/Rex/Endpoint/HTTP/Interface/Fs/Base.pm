#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::Fs::Base;
   
use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub ls {
   my ($self, $path) = @_;

   my @ret;
   opendir(my $dh, $path) or die($!);
   while(my $entry = readdir($dh)) {
      next if($entry eq "." || $entry eq "..");
      push(@ret, $entry);
   }
   closedir($dh);

   return @ret;
}

sub is_dir {
   my ($self, $path) = @_;

   if(-d $path) {
      return 1;
   }
   else {
      return 0;
   }
}

sub is_file {
   my ($self, $file) = @_;

   if(-f $file) {
      return 1;
   }
   else {
      return 0;
   }
}

sub unlink {
   my ($self, $path) = @_;

   CORE::unlink($path) or die($!);
            
   return 1;
}

sub mkdir {
   my ($self, $path) = @_;
   
   CORE::mkdir($path) or die($!);

   return 1;
}

sub stat {
   my ($self, $path) = @_;

   if(my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
               $atime, $mtime, $ctime, $blksize, $blocks) = CORE::stat($path)) {

         my %ret;

         $ret{'mode'}  = sprintf("%04o", $mode & 07777); 
         $ret{'size'}  = $size;
         $ret{'uid'}   = $uid;
         $ret{'gid'}   = $gid;
         $ret{'atime'} = $atime;
         $ret{'mtime'} = $mtime;

         return \%ret;
   }

   die("Not found");
}

sub is_readable {
   my ($self, $path) = @_;

   if(-r $path) {
      return 1;
   }

   return 0;
}

sub is_writable {
   my ($self, $path) = @_;

   if(-w $path) {
      return 1;
   }

   return 0;
}

sub readlink {
   my ($self, $path) = @_;

   my $link = CORE::readlink($path) or die($!);

   return $link;
}

sub rename {
   my ($self, $old, $new) = @_;

   CORE::rename($old, $new) or die($!);

   return 1;
}

sub glob {
   my ($self, $glob) = @_;

   my @ret = CORE::glob($glob);

   return @ret;
}

sub upload {
   my ($self, $path, $upload) = @_;

   open(my $fh, ">", $path) or die($!);
   print $fh $upload->slurp;
   close($fh);

   return 1;
}

sub download {
   my ($self, $path) = @_;

   if(! -f $path) {
      die("File not found.");
   }

   my $content = eval { local(@ARGV, $/) = ($path); <>; };

   return $content;
}

sub ln {
   my ($self, $from, $to) = @_;

   if(-f $to) {
      CORE::unlink($to) or die($!);
   }

   CORE::symlink($from, $to) or die($!);

   return 1;
}

sub rmdir {
   my ($self, $path) = @_;

   system("rm -rf " . $path);

   if($? == 0) {
      return 1;
   }

   die("Error deleting directory.");
}

sub chown {
   my ($self, $user, $file, $options) = @_;

   my $recursive = "";
   if(exists $options->{"recursive"} && $options->{"recursive"} == 1) {
      $recursive = " -R ";
   }

   system("chown $recursive $user $file");

   if($? == 0) {
      return 1;
   }

   die("Error changing ownership of file");
}

sub chgrp {
   my ($self, $group, $file, $options) = @_;

   my $recursive = "";
   if(exists $options->{"recursive"} && $options->{"recursive"} == 1) {
      $recursive = " -R ";
   }

   system("chgrp $recursive $group $file");

   if($? == 0) {
      return 1;
   }

   die("Error chaning group ownership of file");
}

sub chmod {
   my ($self, $mode, $file, $options) = @_;

   my $recursive = "";
   if(exists $options->{"recursive"} && $options->{"recursive"} == 1) {
      $recursive = " -R ";
   }

   system("chmod $recursive $mode $file");

   if($? == 0) {
      return 1;
   }

   die("Error changing file permission");
}

sub cp {
   my ($self, $source, $dest) = @_;

   system("cp -R $source $dest");

   if($? == 0) {
      return 1;
   }

   die("Error copying file");
}

1;
