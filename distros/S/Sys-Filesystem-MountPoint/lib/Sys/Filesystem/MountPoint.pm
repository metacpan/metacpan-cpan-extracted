package Sys::Filesystem::MountPoint;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA $DEBUG $errstr $_f);
use Exporter;
use Carp;
use Sys::Filesystem;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(path_to_mount_point is_mount_point dev_to_mount_point to_mount_point);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub debug { $DEBUG or return 1; print STDERR "@_" }

# Sys::Filesystem object
sub _f { $_f ||= (Sys::Filesystem->new or confess("Can't init Sys::Filesystem???")) }


sub is_mount_point { 
   $_[0] or confess('missing arg');
   ( grep { $_[0] eq $_ } _f->filesystems ) ? $_[0] : undef;   
}



sub path_to_mount_point {
   my $arg = $_[0] or confess("missing arg");

   require Cwd; # deffinitely resolve symlinks!!!
   my $abs = Cwd::abs_path($arg)
      or $errstr = "Cant resolve '$arg' with Cwd::abs_path()"
      and return;

   debug("resolved to '$abs'");

   
   my $subpath = $abs;
   while($subpath){
      debug("testing subpath : $subpath");      
      
      is_mount_point($subpath) and return $subpath;
      
      last if $subpath eq '/'; # we hit root but not FS mnt (just in case).

      $subpath=~s/^\/[^\/]+$/\// # change /this to /         
         or $subpath=~s/\/[^\/]+$// ;# change /this/that to /this      
   }

   $errstr="Can't get mount point for $abs";
   return;
}


sub dev_to_mount_point {
   my $arg = $_[0] or confess("missing arg");

   for my $mnt ( _f->filesystems ){
      (_f->device($mnt) eq $arg) and return $mnt;      
   }
   $errstr="Can't find mount point for $arg";
   return;
}



sub to_mount_point {
   my $arg = $_[0] or confess("missing arg");   
   is_mount_point($arg) || dev_to_mount_point($arg) || path_to_mount_point($arg);
}





1;

__END__

=pod

=head1 NAME

Sys::Filesystem::MountPoint - shortcuts to resolve paths and devices to mount points

=head1 SYNOPSIS

   use Sys::Filesystem::MountPoint ':all';
   
   # BY PATH -------------------------
   my $path_arg = '/home/renee/public_html/jeepers';

   my $mount_point_result_a
      = path_to_mount_point( $path_arg );

   is_mount_point( $mount_point_result_a ) 
      or die("this should not happen");
   



   # BY DEV -------------------------
   my $dev_arg  = '/dev/sdb1';

   my $mount_point_result_b 
      = dev_to_mount_point( $dev_arg );

   is_mount_point( $mount_point_result_b ) 
      or die("this should not happen");




   if( $mount_point_result_b eq $mount_point_result_a ){
      print "It appears $arg_path is in device $dev_arg\n"
         ."Because they both have mount point $mount_point_result_a\n";
   }


=head1 DESCRIPTION

What if you have a path of a file on disk, and you want to know what that file's mount point is?
Or a device, and you want to resolve it? These are shortcuts to get that kind of info.

=head1 SUBS

No subs are exported by default.

=head2 is_mount_point()

Argument is a path. 
Returns undef on fail.
On success returns original argument.

=head2 dev_to_mount_point()

Argument is a device path.
Returns undef on fail.
On success returns mount point.

=head2 path_to_mount_point()

Argument is a path on disk. 
Returns undef on fail.
On success returns mount point.

=head2 to_mount_point()

Argument is a path, mount point, or device path, returns mount point.
On fail returns undef.

=head2 $errstr

If any of these subs fail, you may consult $errstr.

   to_mount_point('/home/myself/misc') 
      or die($Sys::Filesystem::MountPoint::errstr);

=head1 SEE ALSO

L<Sys::Filesystem>

=head1 CAVEATS

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

