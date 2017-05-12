package Sys::Filesystem::ID;
use strict;
use Sys::Filesystem;
use LEOCHARRE::DEBUG;
use Exporter;
use vars qw(%FS @FSALL @FSOK $fs @ISA @EXPORT_OK %EXPORT_TAGS $VERSION);
@ISA = qw/Exporter/;
@EXPORT_OK = qw/&abs_id &get_id &create_id %FS @FSOK @FSALL/;
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;

*get_id    = \&_id_by_arg;
*create_id = \&_write_new_idfile_by_arg;
*abs_id    = \&_abs_id_by_arg;

_init();

sub _init {
  
   $fs = new Sys::Filesystem;

   for my $mnt ($fs->filesystems) {       
      my $format = $fs->format($mnt);
      my $dev    = $fs->device($mnt);

      $FS{$mnt} = {
         mnt => $mnt,
         dev => $dev,
         format => $format,
      };      
      debug("found $mnt, dev $dev, format $format");
   }


   # which do we want to use for storage ?

   @FSOK = grep { _format_is_desired($FS{$_}{format}) }  keys %FS;
   @FSALL = keys %FS;

}

sub _format_is_desired {
   my $format = shift;   
   return ( $format=~/^ext\d$/ ? 1 : 0 ); # kind of filesystem
   # we are selecting ext* (ext3, ext2)
}



sub _arg_type {  # is arg a dev or mnt
   my $arg = shift;
   for my $mnt( keys %FS ){
      if ( $arg eq $mnt ){
         return 'mnt';
      }
      if ( $FS{$mnt}{dev} eq $arg ){
         return 'dev';
      }
   }   
   return 'path';
}

sub _arg_to_mount_point { # take mnt or dev, return mnt point
   my $arg = shift;
   my $argtype = _arg_type($arg);

   if ( $argtype eq 'mnt'){
      return $arg;
   }
   elsif ( $argtype eq 'dev'){
      return _find_mount_point_by_dev($arg);
   }
   elsif ( $argtype eq 'path' ){
      return _find_mount_point_by_path($arg);
   }
   else {
      die("not fs: $arg");
   }
}

sub _find_mount_point_by_dev {
   my $arg = shift;
   defined $arg or die('missing dev arg');

   for my $mnt ( keys %FS ){
      if ( $FS{$mnt}->{dev} eq $arg){
         return $mnt;
      }
   }
   return;
}

sub _find_mount_point_by_path {
   my $arg = shift;


   require Cwd; # deffinitely resolve symlinks!!!
   my $abs = Cwd::abs_path($arg)
      or die("cant resolve $arg as path");
   debug("resolved to '$abs'");

   my $subpath = $abs;
   while($subpath){
      debug("subpath : $subpath");      

      return $subpath if exists $FS{$subpath};

      last if $subpath eq '/'; # we hit root but not FS mnt (just in case).


      $subpath=~s/^\/[^\/]+$/\// # change /this to /         
         or $subpath=~s/\/[^\/]+$// ;# change /this/that to /this
      
   }

   die("cant get mount point for path $abs");
}

sub _abs_id_by_arg { # arg is mount pont
   my $arg = shift;
   my $mnt = _arg_to_mount_point($arg) or return;
   return "$mnt/.fsid";
}

sub _id_by_arg {
   my $arg = shift;
   my $abs_id = _abs_id_by_arg($arg) or return;
   my $id = _read_idfile($abs_id) or return;
   return $id;
}

sub _id_string_is_ok {
   +shift =~/^.+$/ ? 1 : 0;   
}

sub _read_idfile {
   my $abs_id = shift;
   -f $abs_id or debug("no abs id on disk: $abs_id") and return;
   local $\;
   open(FILE,'<',$abs_id) or die("cant open $abs_id for reading, $!");
   my $id = <FILE>;
   close FILE;
   $id=~s/^\s+|\s+$//g;
   _id_string_is_ok($id) or die("id string in $abs_id is not ok");
   return $id;
}

sub _generate_new_id {
   
   # get bogus data and then do md5sum of it ??
   my $id = _suggest_id_string();

   debug("length: ". (length $id)." id: $id"); 

   _id_string_is_ok($id) or die("id string generated is not ok [$id]");
   return $id;
}

# override me if wanted
sub _suggest_id_string {
   my $id;
   for( 0 .. 31 ){
      $id .= int rand 9;
   }
   return $id;
}

sub _write_new_idfile_by_arg {
   my $arg = shift;
   my $abs_id = _abs_id_by_arg($arg) or die("cant get abs id for $arg");
   !-f $abs_id or die("cant create '$abs_id', file exists.");

   my $id = _generate_new_id();
   _id_string_is_ok($id) or die("id string generated is not ok [$id]");

   open(FILE,'>',$abs_id) or die("cannot open $abs_id for writing, $!");
   print FILE $id;
   close FILE;

   # set perms, world read, no write
   chmod 0444, $abs_id;
   return $id;
}



1;



__END__

=pod

=head1 NAME 

Sys::Filesystem::ID

=head1 DESCRIPTION

Will read and write an id from a filesystem for data identification purposes.

=head2 HOW IT WORKS

We create a text file at the root of the mounted filesystem in question- an id file.

=head2 MOTIVATION

This can be used to identify hard drives as they move across computers on a network.
If you want to store information about a usb drive in a centralized database.
Then you can move the hard drive (with partitions inside) around and you can track them.

=head1 fsid

A cli (command line interface) application is provided, called fsid, with this 
distribtution.

=head1 SUBS

None exported by default.
This is not an OO interface.

=head2 get_id()

Argument is a device, a mount point, or a file path.
Returns id string or undef if not found. Dies if it can't resolve.

   get_id('/dev/hda1');
   get_id('/mnt/usbdisk');
   get_id('home/myself/Desktop/file1.pdf');

=head2 create_id()

Argument is a device, a mount point, or a file path.
Returns id string or undef if not found. Dies if it can't resolve, or if the id file already
exists.

   create_id('/dev/hda1');
   create_id('/mnt/usbdisk');
   create_id('home/myself/Desktop/file1.pdf');

=head1 OVERRIDING ID GENERATION

The ide generated is a random buncha numbers 32 digits.
If you want to make your own..
Override _suggest_id_string() in this package.

   sub Sys::Filesystem::ID::_suggest_id_string {}

The rule is it must return a string.

=head1 CAVEATS

You must have write access to create a partition id, and read access to see it.
This works on posix only.

=head1 REQUIREMENTS

Sys::Filesystem

=head1 SEE ALSO

L<Sys::Filesystem>
L<fsid>
L<fsidgen>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut




