# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::FS;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

# Blocks resp from unistd.h, stdio.h, limits.h
my @constants;
my @access = qw/access/;

my @stat  = qw/stat lstat
  S_ISDIR S_ISCHR S_ISBLK S_ISREG S_ISFIFO S_ISLNK S_ISSOCK S_ISWHT S_IFMT
  S_IFBLK S_IFCHR S_IFDIR S_IFIFO S_IFLNK S_IFMT S_IFREG S_IFSOCK S_ISGID
  S_ISUID S_ISVTX/;

my @perms = qw/S_IRGRP S_IROTH S_IRUSR S_IRWXG S_IRWXO S_IRWXU
  S_IWGRP S_IWOTH S_IWUSR S_IXGRP S_IXOTH S_IXUSR/;

sub S_ISDIR($)  { ($_[0] & S_IFMT()) == S_IFDIR()}
sub S_ISCHR($)  { ($_[0] & S_IFMT()) == S_IFCHR()}
sub S_ISBLK($)  { ($_[0] & S_IFMT()) == S_IFBLK()}
sub S_ISREG($)  { ($_[0] & S_IFMT()) == S_IFREG()}
sub S_ISFIFO($) { ($_[0] & S_IFMT()) == S_IFIFO()}
sub S_ISLNK($)  { ($_[0] & S_IFMT()) == S_IFLNK()}
sub S_ISSOCK($) { ($_[0] & S_IFMT()) == S_IFSOCK()}
sub S_ISWHT($)  { ($_[0] & S_IFMT()) == S_IFWHT()}  # FreeBSD

# POSIX.xs defines L_ctermid L_cuserid L_tmpname: useless!

# Blocks resp from sys/stat.h, unistd.h, utime.h, sys/types
my @functions = qw/
 mkfifo mknod stat lstat rename
 access lchown
 utime
 major minor makedev
 /;

our @IN_CORE     = qw(utime mkdir stat lstat rename);

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , access    => \@access
 , stat      => \@stat
 , tables    => [ qw/%access %stat/ ]
 , perms     => \@perms
 );

my ($fsys, %access, %stat);

BEGIN {
    $fsys = fsys_table;
    push @constants, keys %$fsys;

    # initialize the :access export tag
    push @access, grep /_OK$/, keys %$fsys;
    my %access_subset;
    @access_subset{@access} = @{$fsys}{@access};
    tie %access,  'POSIX::1003::ReadOnlyTable', \%access_subset;

    # initialize the :fsys export tag
    push @stat, grep /^S_/, keys %$fsys;
    my %stat_subset;
    @stat_subset{@stat} = @{$fsys}{@stat};
    tie %stat, 'POSIX::1003::ReadOnlyTable', \%stat_subset;
}


sub lchown($$@)
{   my ($uid, $gid) = (shift, shift);
    my $successes = 0;
    POSIX::lchown($uid, $gid, $_) && $successes++ for @_;
    $successes;
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fsys->{$name};
    sub() {$val};
}

1;
