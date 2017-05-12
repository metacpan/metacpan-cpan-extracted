package Solaris::MapDev;
use strict;
use Exporter;
use IO::File;
use Symbol;   # Would like to use IO::Dir, but that isn't available in 5.004_04
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION = "0.04";
@ISA = qw(Exporter);
@EXPORT_OK = qw(inst_to_dev dev_to_inst get_inst_names get_dev_names
                mapdev_data_files mapdev_system_files);
%EXPORT_TAGS = ( ALL => [ @EXPORT_OK ] );

# Global flags and data structures
#    $use_system_files - Live system data files used for mapping info
#    $device_to_inst   - /devices entry -> instance name
#    $inst_to_dev      - instance name  -> /dev entry
#    $dev_to_inst      - /dev entry     -> instance name
use vars qw($use_system_files $device_to_inst $inst_to_dev $dev_to_inst);
$use_system_files = 1;   # default - use live system files

################################################################################
# Read /etc/path_to_inst, and build a map from disk and tape /devices entries
# to instance names

sub read_path_to_inst($)
{
my ($path_to_inst) = @_;

my $fh = IO::File->new($path_to_inst, "r")
   || die("Can't open $path_to_inst: $!\n");
while (defined(my $line = $fh->getline()))
   {
   next if ($line =~ /^\s*#/);
   $line =~ s/"//g;
   my ($dev, $inst, $drv) = split(" ", $line);
   if ($drv =~ /^(ss?d|st)$/)
      {
      $device_to_inst->{"/devices$dev"} = "$drv$inst";
      }
   elsif ($drv eq "fd")
      {
      $inst_to_dev->{"$drv$inst"} = "$drv$inst";
      }
   elsif ($drv eq "cmdk")
      {
      $device_to_inst->{"/devices$dev"} = "sd$inst";
      }
   elsif ($drv eq "dad")
      {
      $device_to_inst->{"/devices$dev"} = "dad$inst";
      }
   elsif ($drv eq "atapicd")
      {
      $device_to_inst->{"/devices$dev"} = "atapicd$inst";
      }
   }
$fh->close();
}

################################################################################
# Read in /etc/mnttab and add entries for nfs mount points

sub read_mnttab($)
{
my ($mnttab) = @_;

my $fh = IO::File->new($mnttab, "r") || die("Can't open $mnttab: $!\n");
while (defined(my $line = $fh->getline()))
   {
   next if ($line =~ /^\s*#/);
   my ($special, $fstyp, $opt) = (split(" ", $line))[0,2,3];
   next if ($fstyp ne "nfs");
   $opt =~ s/.*dev=(\w+).*/hex($1) & 0x3ffff/e;
   $inst_to_dev->{"nfs$opt"} = $special;
   }
$fh->close();
}

################################################################################
# Private routine to rebuild the inst_to_dev lookup table.  This is called the
# first time either dev_to_inst or inst_to_dev is called, and also if a device
# cannot be found in the lookup hashes.  It rebuilds $inst_to_dev only, on the
# assumption that we will rarely want to map back from a device to the instance.
# $dev_to_inst is rebuilt when required by dev_to_inst

sub refresh()
{
# Throw away all the current info
$device_to_inst = {};
$inst_to_dev    = {};
$dev_to_inst    = {};

# Read /etc/path_to_inst and /etc/mnttab
read_path_to_inst("/etc/path_to_inst");
read_mnttab("/etc/mnttab");

# Next find all the disk nodes under /dev and /dev/osa if it exists.
# /dev/osa contains extra device nodes not found under /dev for the Symbios
# HW RAID controllers (A1000, A3000).  Note however that if the devices are
# removed, the old info in /dev/osa is not removed, and if any more
# non-Symbios disks are added it will become incorrect.  To get around this, we
# read /dev/osa first if it exists, then /dev.  This will make sure that we get
# the most up-to-date information.
# Also do the same for all the tape devices under /dev/rmt
my ($dir, $dh, $dev, $lnk);
$dh = gensym();
foreach $dir ("/dev/osa/rdsk", "/dev/osa/dev/rdsk", "/dev/rdsk", "/dev/rmt")
   {
   next if (! -d $dir);
   opendir($dh, $dir) || die("Cannot read $dir: $!\n");
   while (defined($dev = readdir($dh)))
      {
      next if ($dev !~ /s0$/ && $dev !~ /^\d+$/);
      $lnk = readlink("$dir/$dev");
      $lnk =~ s!^\.\./\.\.!!;
      $lnk =~ s!:.*$!!;
      if (defined($device_to_inst->{$lnk}))
         {
         if ($dev =~ /s0$/) { $dev =~ s/s0$//; }
         else { $dev = "rmt/$dev" };
         $inst_to_dev->{$device_to_inst->{$lnk}} = $dev;
         }
      }
   closedir($dh);
   }
}

################################################################################
# Use supplied data files as the source of mapping information, instead of the
# current live files.  For details on what's going on, look at refresh

sub mapdev_data_files(%)
{
my %arg = @_;
my $path_to_inst = $arg{path_to_inst}
   || die("No path_to_inst file specified\n");
my $dev_ls = $arg{dev_ls}
   || die("No \"ls -l /dev/...\" files specified\n");
my $mnttab = $arg{mnttab};
$use_system_files = 0;

# Throw away all the current info
$device_to_inst = {};
$inst_to_dev    = {};
$dev_to_inst    = {};

# Scan the path_to_inst and mnttab files
read_path_to_inst($path_to_inst);
read_mnttab($mnttab) if ($mnttab);

my ($dir, $prefix, $dls, $fh, $line, $path, $dev_d, $dev_f, $lnk);
foreach $dir ("/dev/osa/rdsk", "/dev/osa/dev/rdsk", "/dev/rdsk", "/dev/rmt")
   {
   while (($prefix, $dls) = each(%$dev_ls))
      {
      $fh = IO::File->new($dls, "r") || die("Can't open $dls: $!\n");
      $path = $prefix;
      while (defined($line = $fh->getline()))
         {
         # Look for ls -l directory headings
         if ($line =~ /^(?:\.\/)?([\w|\/]+):$/)
            { $path = "$prefix/$1"; }
         # Look for lines that are symlinks to ../../devices
         elsif ($line =~ m!(\S+)\s+->\s+(\.\./\.\./devices\S+)!)
            {
            # Add on the directory prefix if the entry is relative,
            # and remove any "/./" and "dir/../" components
            ($dev_d, $lnk) = ($1, $2);
            $dev_d = "$prefix/$dev_d" if (substr($dev_d, 0, 1) ne "/");
            $dev_d =~ s!/\./!/!g;
            $dev_d =~ s![^/]+/\.\./!!g while ($dev_d =~ /\.\./);

            # Split device path into directory and filename
            ($dev_d, $dev_f) = $dev_d =~ /^(.*)\/(.*)$/;

            # Only process if this is a dir and dev we are interested in
            next if (! ($dev_d eq $dir && $dev_f =~ /^\d+|c\d+t\d+d\d+s0/));

            # Clean up the /device entry
            $lnk =~ s!^\.\./\.\.!!;
            $lnk =~ s!:.*$!!;

            # Record the mapping if it is one we are interested in
            if (defined($device_to_inst->{$lnk}))
               {
               # Tweak the dev name
               if ($dev_f =~ /s0$/) { $dev_f =~ s/s0$//; }
               else { $dev_f = "rmt/$dev_f" };
               $inst_to_dev->{$device_to_inst->{$lnk}} = $dev_f;
               }
            }
         }
      $fh->close();
      }
   }
}

################################################################################
# Switch back to using live system files

sub mapdev_system_files()
{
# Change flag & throw away all the current info
$use_system_files = 1;
$device_to_inst = undef;
$inst_to_dev    = undef;
$dev_to_inst    = undef;
}

################################################################################
# Map an instance name to a device name, rebuilding $inst_to_dev as required

sub inst_to_dev($)
{
my ($inst) = @_;
my ($i, $s);
# Special treatment for disks with slice info
if ($inst =~ /^(ss?d\d+)(?:,(\w))$/ || $inst =~ /^(dad)(?:,(\w))$/)
   {
   $i = $1;
   $s = "s" . (ord($2) - ord("a"));
   }
else
   {
   $i = $inst;
   $s = "";
   }
refresh() if ($use_system_files && ! exists($inst_to_dev->{$i}));
if (exists($inst_to_dev->{$i})) { return("$inst_to_dev->{$i}$s"); }
else { return(undef); }
}

################################################################################
# Map a device name to an instance name, rebuilding $dev_to_inst as required

sub dev_to_inst($)
{
my ($dev) = @_;
my ($d, $s);
# Special treatment for disks with slice info
if ($dev =~ /^(c\d+t\d+d\d+)(?:s(\d))$/)
   {
   $d = $1;
   $s = "," . chr(ord("a") + $2);
   }
else
   {
   $d = $dev;
   $s = "";
   }
if (! defined($inst_to_dev) || ! exists($dev_to_inst->{$d}))
   {
   refresh() if ($use_system_files);
   %$dev_to_inst = reverse(%$inst_to_dev);
   }
if (exists($dev_to_inst->{$d})) { return("$dev_to_inst->{$d}$s"); }
else { return(undef); }
}

################################################################################
# Get a list of all the instance names

sub get_inst_names()
{
refresh() if ($use_system_files && ! defined($inst_to_dev));
return(sort(keys(%$inst_to_dev)));
}

################################################################################
# Get a list of all the device names

sub get_dev_names()
{
refresh() if ($use_system_files && ! defined($inst_to_dev));
return(sort(values(%$inst_to_dev)));
}

################################################################################
1;
__END__

=head1 NAME

Solaris::MapDev - map between instance numbers and device names

=head1 SYNOPSIS

   use Solaris::MapDev qw(inst_to_dev dev_to_inst);
   my $disk = inst_to_dev("sd0");
   my $nfs = inst_to_dev("nfs123");
   my $inst = dev_to_inst("c0t0d0s0");
   mapdev_data_files(path_to_inst => "/copy/of/a/path_to_inst",
                     mnttab => "/copy/of/a/mnttab",
                     dev_ls => { "/dev/rdsk" => "ls-lR/of/dev_dsk",
                                 "/dev/rmt"  => "ls-lR/of/dev_rmt" });
   my $tape = inst_to_dev("st1");

=head1 DESCRIPTION

This module maps both ways between device instance names (e.g. sd0) and /dev
entries (e.g. c0t0d0).  'Vanilla' SCSI disks, SSA disks, A1000, A3000, A3500
and A5000 disks are all catered for, as are tape devices and NFS mounts.

=head1 FUNCTIONS

=head2 inst_to_dev($inst)

Return the device name name given the instance name

=head2 dev_to_inst($dev)

Return the instance name given the device name

=head2 get_inst_names

Return a sorted list of all the instance names

=head2 get_dev_names

Return a sorted list of all the device names

=head2 mapdev_data_files

This tells mapdev to use data held in copies of the real datafiles, rather than
the current "live" files on the system.  This is useful for example when
examining explorer output.  A list of key-value pairs is expected as the
arguments.  Valid keys-value pairs are:

   path_to_inst => "/copy/of/a/path_to_inst",
      A valid path_to_inst file.  This is mandatory.

   mnttab => "/copy/of/a/mnttab",
      A valid /etc/mnttab file.  This is optional - if not
      specified, no information on NFS devices will be displayed.

   dev_ls => { "/dir/path" => "/ls-lR/of/dir/path",
               ... });
      A hash containing path/datafile pairs.  The paths should
      be one of /dev/rdsk, /dev/osa/rdsk, /dev/osa/dev/rdsk or
      /dev/rmt.  The datafiles should be the output of a "ls -l"
      of the specified directory.  A single file containing a
      recursive "ls -Rl" of /dev is also acceptable.

=head2 mapdev_system_files

This tells mapdev to revert to using the current "live" datafiles on the system
- see L<"mapdev_data_files()">

=head1 AUTHOR

Alan Burlison, <Alan.Burlison@uk.sun.com>

=head1 SEE ALSO

L<perl(1)>, F</etc/path_to_inst>, F</dev/osa>, F</dev/rdsk>, F</dev/rmt>,
F</etc/mnttab>

=cut
