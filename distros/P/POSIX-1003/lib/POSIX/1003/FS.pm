# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::FS;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my (@constants, @access, @stat, @glob);

# POSIX.xs defines L_ctermid L_cuserid L_tmpname: useless!

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
  , glob      => \@glob
  , tables    => [ qw/%access %stat/ ]
  );

my ($fsys, %access, %stat, %glob);

BEGIN
  { $fsys = fsys_table;
    push @constants, keys %$fsys;

    # initialize the :access export tag
    @access = qw/access/;
    push @access, grep /_OK$|MAX/, keys %$fsys;
    my %access_subset;
    @access_subset{@access} = @{$fsys}{@access};
    tie %access,  'POSIX::1003::ReadOnlyTable', \%access_subset;

    # initialize the :stat export tag
    @stat = qw/stat lstat mkfifo mknod mkdir lchown
        S_ISDIR S_ISCHR S_ISBLK S_ISREG S_ISFIFO S_ISLNK S_ISSOCK S_ISWHT
        /;
    push @stat, grep /^S_I/, keys %$fsys;
    my %stat_subset;
    @stat_subset{@stat} = @{$fsys}{@stat};
    tie %stat, 'POSIX::1003::ReadOnlyTable', \%stat_subset;

    # initialize the :fsys export tag
    @glob = qw/posix_glob fnmatch/;
    push @glob, grep /^(?:GLOB|FNM|WRDE)_/, keys %$fsys;
    my %glob_subset;
    @glob_subset{@glob} = @{$fsys}{@glob};
    tie %glob, 'POSIX::1003::ReadOnlyTable', \%glob_subset;
}


sub S_ISDIR($)  { ($_[0] & S_IFMT()) == S_IFDIR()}
sub S_ISCHR($)  { ($_[0] & S_IFMT()) == S_IFCHR()}
sub S_ISBLK($)  { ($_[0] & S_IFMT()) == S_IFBLK()}
sub S_ISREG($)  { ($_[0] & S_IFMT()) == S_IFREG()}
sub S_ISFIFO($) { ($_[0] & S_IFMT()) == S_IFIFO()}
sub S_ISLNK($)  { ($_[0] & S_IFMT()) == S_IFLNK()}
sub S_ISSOCK($) { ($_[0] & S_IFMT()) == S_IFSOCK()}
sub S_ISWHT($)  { ($_[0] & S_IFMT()) == S_IFWHT()}  # FreeBSD


sub lchown($$@)
{   my ($uid, $gid) = (shift, shift);
    my $successes = 0;
    POSIX::lchown($uid, $gid, $_) && $successes++ for @_;
    $successes;
}


sub posix_glob($%)
{   my ($patterns, %args) = @_;
    my $flags  = $args{flags}
       // $glob{GLOB_NOSORT}|$glob{GLOB_NOESCAPE}|$glob{GLOB_BRACE};
    my $errfun = $args{on_error} || sub {0};

    my ($err, @fns);
    if(ref $patterns eq 'ARRAY')
    {   foreach my $pattern (@$patterns)
        {   my $thiserr = _glob(@fns, $pattern, $flags, $errfun);
            next if !$thiserr || $thiserr==$glob{GLOB_NOMATCH};

            $err = $thiserr;
            last;
        }
    }
    else
    {   $err = _glob(@fns, $patterns, $flags, $errfun);
    }

    if($args{unique} && @fns)
    {   my %seen;
        @fns = grep !$seen{$_}++, @fns;
    }

    $err //= @fns ? $glob{GLOB_NOMATCH} : 0;
    ($err, \@fns);
}


sub fnmatch($$;$)
{   my ($pat, $name, $flags) = @_;
    _fnmatch($pat, $name, $flags//0);
}

#---------

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fsys->{$name};
    sub() {$val};
}

1;
