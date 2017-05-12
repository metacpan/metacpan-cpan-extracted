use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
use Sys::Filesystem::MountPoint qw/path_to_mount_point is_mount_point dev_to_mount_point to_mount_point/;
$cwd = cwd();

ok_part('INTERNAL CHECK');

ok ! is_mount_point('asdfsadf.asdf.asdf.asf/') ;


ok_part("PATHS THAT ARE GOOD");
my @paths = split(/\n/, `find ./ -type f`);
scalar @paths or die("cant setup to test. (This should be a posix box.)");

for my $path (@paths ){
   print STDERR "\nPath: $path\n";
   my $mp = path_to_mount_point($path);
   ok($mp, "mount point $mp");
}

ok_part("BOGUS PATHS");

my @boguspaths = ( time().'/sadkhakjsdhfakjsdhgjahgh4a3h4gh', 'awdfhahh348gh3g/asdgasga/asdgasdg'.time());

for my $path ( @boguspaths ){
   print STDERR "\nBogus path: $path\n";
   ok(  ! path_to_mount_point($path), " cant get mount point." );
   ok( $Sys::Filesystem::MountPoint::errstr, "error string holds : $Sys::Filesystem::MountPoint::errstr");
}




ok_part("DEV TO MOUNT POINT");

opendir(DIR,'/dev') or print STDERR "Cant open /dev for reading, $!\n" and exit;
my @devs = grep { !/^\./ } readdir DIR;
closedir DIR;

my @devswithp;

for (@devs){
   my $dev = "/dev/$_";
   
   my $p = dev_to_mount_point($dev);

   $p or ( print STDERR "$dev:0," and next );

   print STDERR "\nfound mount point for $dev: '$p'\n";
   push @devswithp, $dev;
}
print STDERR "\n\n";
my $count = scalar @devswithp;
ok( $count, "found at least one dev with a mount point: @devswithp");



ok_part("DEV AND PATH ARGS TO MOUNT POINT");

for my $arg ( @devswithp, @paths ){
   my $p = to_mount_point($arg);
   ok($p, "arg: '$arg'\t\tpoint : $p");
}



sub ok_part {
   printf STDERR "\n\n===================\n= PART %s %s\n==================\n\n",
      $_part++, "@_";
}


