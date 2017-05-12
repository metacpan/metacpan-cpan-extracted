#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($^O eq 'VMS' or $^O eq 'os2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'} 
!GROK!THIS!
# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
#                              -*- Mode: Perl -*- 
# nnml.pl -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Mar 10 10:34:08 1995
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon Mar 24 11:00:47 1997
# Language        : Perl
# Update Count    : 93
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
eval 'exec perl  -S $0 "$@"'
    if 0;

use Cwd;
$home = $ENV{'HOME'} || $ENV{'LOGDIR'} ||
    (getpwuid($<))[7] || die "You're homeless!\n";
chomp($hostname = `hostname`);

use Getopt::Long;

&GetOptions(\%OPT,
            'base=s',
            'dir=s',
            'force',
            'verbose',
            'debug',
           ) || die "Usage: $0 ... \n";

$base = $OPT{base} || "$home/Mail";
$dir  = $OPT{dir}  || $base;
$nov  = '.overview';
$active      = "$base/active";
$active_time = &mtime($active);
$OPT{verbose} = 1 if $OPT{debug};

unless ($base =~ m:^/:) {
  $base = getcwd . '/' . $base;
}

&read_active($active);
&find($dir);
&write_active($active);

exit 0;

sub read_active {
    my($active) = @_;
    my($group,$data);

    print STDERR "read_active\n" if $OPT{debug};
    return unless -e $active;
    open(ACTIVE, "<$active") || die "Could not open $active: $!\n";
    while (<ACTIVE>) {
        ($group,$data) = split(/\s+/,$_,2);
        $ACTV{$group} = $data;
    }
    close ACTIVE;
}

sub write_active {
    my($active) = @_;

    print STDERR "write_active\n" if $OPT{debug};
    rename $active, "$active~";
    open(ACTIVE, ">$active") || die "Could not open $active: $!\n";
    for (sort keys %ACTV) {
        print ACTIVE "$_ $ACTV{$_}";
    }
    close ACTIVE;
}

sub mtime {
    my($file) = @_;

    if ( -e $file ) {
        (stat($file))[9];
    } else {
        0;
    }
}

sub find {
    my($cwd, $topdirm,$topdev,$topino, $topmode, $topnlink, $dir, $name);

    chop($cwd = `pwd`);

    print STDERR "find(", join(',',@_),")\n" if $OPT{debug};
    foreach $topdir (@_) {
	(($topdev,$topino,$topmode,$topnlink) = stat($topdir))
            || (warn("Can't stat $topdir: $!\n"), next);
        #print STDERR "mtime=$mtime\n";
        #print STDERR "$topdir/$nov = ",&mtime("$topdir/$nov"),"\n";
	if (-d _) {
	    if (chdir($topdir)) {
		($dir,$_) = ($topdir,'.');
		$name = $topdir;
		$topdir =~ s,/$,, ;
                &finddir($topdir,$topnlink);
	    } else {
		warn "Can't cd to $topdir: $!\n";
	    }
	}
	else {
	    unless (($dir,$_) = $topdir =~ m#^(.*/)(.*)$#) {
		($dir,$_) = ('.', $topdir);
	    }
	    $name = $topdir;
	    chdir $dir       # && &wanted;  
	}
	chdir $cwd;
    }
}

sub finddir {        
    my($dir,$nlink) = @_;
    my($dev,$ino,$mode,$subcount);
    my($name);
    my($min, $max, $group);
    my($nov) = "$dir/$nov";
    my($nov_time) = &mtime($nov);
    my($dir_time) = &mtime($dir);
    my($update)   = 
        $OPT{force} 
            || $dir_time > $nov_time 
                || $dir_time > $active_time;
    my(@novdb);
    my($num,$data);

    print STDERR "finddir($dir,$nlink) update=$update\n" if $OPT{debug};

    $group = $dir; $group =~ s:^$base/::; $group =~ s:/:.:go;

    opendir(DIR,'.') || (warn "Can't open $dir: $!\n", return);
    local(@filenames) = readdir(DIR);
    closedir(DIR);

    if ($nlink == 2) {        # This dir has no subdirectories.
        return unless $update;
        @novdb = &read_nov($nov);

	for (@filenames) {
	    next if $_ eq '.';
	    next if $_ eq '..';
	    $name = "$dir/$_";
	    $nlink = 0;
	    if ( /^[0-9]*$/ ) {
                $min = $_ if !defined $min || $min >= $_;
                $max = $_ if !defined $min || $max <= $_;
                if ($OPT{force} || ($nov_time < &mtime($_))) {
                    $novdb[$_] = &nov_entry($_, $group);
                    print STDERR ">>>$_, $novdb[$_]\n" if $OPT{debug};
                }
            }
	}
    }
    else {                    # This dir has subdirectories.
        @novdb = &read_nov($nov) if $update;
	$subcount = $nlink - 2;
	for (@filenames) {
	    next if $_ eq '.';
	    next if $_ eq '..';
	    $nlink = $prune = 0;
	    $name = "$dir/$_";
            if ($subcount > 0) {    # Seen all the subdirs?
                # Get link count and check for directoriness.
                ($dev,$ino,$mode,$nlink) = lstat($_) unless $nlink;
		
                if (-d _) {

                    # It really is a directory, so do it recursively.
                    
                    if (!$prune && chdir $_) {
                        &finddir($name,$nlink);
                        chdir '..';
                    }
                    --$subcount;
                } else {
                    if ( /^[0-9]*$/ ) {
                        $min = $_ if !defined $min || $min >= $_;
                        $max = $_ if !defined $min || $max <= $_;
                        if ($OPT{force} || ($nov_time < &mtime($_))) {
                            $novdb[$_] = &nov_entry($_, $group);
                        }
                    }
                }
            } else {
                return unless $update;
                if ( /^[0-9]*$/ ) {
                    $min = $_ if !defined $min || $min >= $_;
                    $max = $_ if !defined $min || $max <= $_;
                    if ($OPT{force} || ($nov_time < &mtime($_))) {
                        $novdb[$_] = &nov_entry($_, $group);
                    }
                }
            }
	}
    }
    return unless $update;
    if (defined $max) {
        $ACTV{$group} = "$max $min n\n";
        &write_nov($nov, @novdb);
    }
}

sub write_nov {
    my($nov, @novdb) = @_;

    print STDERR "write_nov\n" if $OPT{debug};
    rename $nov, "$nov~";
    open(NOV, ">$nov")  || die "Could not open $nov: $!\n";
    for $num ($[ .. $#novdb) {
        print NOV "$num\t$novdb[$num]" if $novdb[$num];
    }
    close NOV;
}

sub read_nov {
    my($nov) = @_;
    my(@novdb, $num, $data);

    print STDERR "read_nov\n" if $OPT{debug};
    if ( !$OPT{force} && -e $nov) {
        open(NOV, "<$nov") || die "Could not open $nov: $!\n";
        while (<NOV>) {
            ($num, $data) = split(/\s+/,$_,2);
            $novdb[$num] = $data;
        }
        close NOV;
    }

    @novdb;
}

sub nov_entry {
    my($file, $group) = @_;
    local($_);

    my($subject, $from, $date, $id, $references, $chars, $lines, $xref) =
        ("(none)", "(nobody)", "", "", "", 0, "0", "");

    print STDERR "nov_entry($group:$file)\n" if $OPT{verbose};
    #$chars = (stat($file))[7];
    open(MAIL, "$file") || die "Could not open $file: $!\n";
    while (<MAIL>) {
        #$lines++;
        if (/^subject: (.*)/i)    { $subject    = $1; }
        if (/^from: (.*)/i)       { $from       = $1; }
        if (/^date: (.*)/i)       { $date       = $1; }
        if (/^Message-Id: (.*)/i) { $id         = $1; }
        if (/^references: (.*)/i) { $references = $1; }
        if (/^xref: (.*)/i)       { $xref       = $1; }
        last if /^$/;
    }
    $xref = "$hostname $group:$file" unless $xref;
    while (<MAIL>) {
        $lines++; $chars += length($_);
    }
    for ($subject, $from, $date, $id, $references) {
      s/\t/ /g && print STDERR "*** $file $_\n";
    }
    sprintf("%s\t%s\t%s\t%s\t%s\t%d\t%s\t%s\t\n",
            $subject, $from, $date, $id, $references, $chars, $lines-1, $xref);
}

__END__

=head1 NAME

overview - Update or create nnml databases for ding.

=head1 SYNOPSIS

B<overview>
[B<-base> I<directory>]
[B<-dir> I<directory>]
[B<-force>]
[B<-verbose>]
[B<-debug>]

=head1 DESCRIPTION

B<Overview> creates or updates nnml databases. The nnml database is
assumed to live in I<Mail> in the users home directory. This can be
overwritten by the B<-base> I<alternative_absolute_path> option.

The script operates on the full database unless the option B<-dir>
I<path_to_the_part> is given.

The script incrementally updates the F<active> file in the base
directory and all F<.overview > files in the subdirectories. The
modification times of the old versions are used to determine for which
files entries must be added.

The option B<-force > may be used to force the script to generate the
databases from scratch.

=head1 ENVIRONMENT

C<HOME> and C<LOGDIR> are used to determine the users home directory.

=head1 EXAMPLES

Incrementally update F<~/Mail/active> and F<~/Mail/*/.overview>:

  overview                         

Incrementally update F<~/Mail/active> and
F<~/Mail/lists/ding/.overview>:

overview -dir ~/Mail/lists/ding

Generate F<~/Mail/active> and F<~/Mail/*/.overview> from scratch:

  overview -force                  

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>

!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
