#!/usr/bin/perl -w

# Makefile.PL for Net::ICal::VTIMEZONES
#
# Installs VTIMEZONE files in the right place depending on
# your OS and whether you already have a set of them. 
# Records some information in a config file, Net::ICal::Config.
#
# Options:
#  --prefix=dirname   installs vtimezones in $prefix/zoneinfo.
#
$VERSION = (qw'$Revision: 1.4 $')[1];

use strict;
use File::Copy;
use Getopt::Long;

my $OS = $^O;
my %unices = (  linux   => '1',
                hpux    => '1',
                sunos   => '1'
                );

my $config = {};



# where to install the VTIMEZONES unless we're told otherwise.
# Command-line configurable, but needs to be wired to
# install in $PREFIX from the Makefile.
my $prefix = "";
GetOptions ('prefix=s' => \$prefix);
$prefix ||= '/usr/local/share';

my $DEST_LOCATION = "$prefix/reefknot/zoneinfo";
my $SOURCE_LOCATION = 'zoneinfo';                

if (exists $unices{$OS}) {
    $config = libical_is_installed($config);
    
    if ($config->{'zoneinfo_location'} ne '') {
        # write out a config file with where we found it
        write_config_module($config);
        
    } else {
        # install vtimezones and then write a config file
        $config->{zoneinfo_location} = $DEST_LOCATION;
        install_vtimezones($SOURCE_LOCATION, $config->{zoneinfo_location});
        write_config_module($config);
    }
    
} elsif ($OS eq 'MSWin32') {
    # someone with win32 speak up here, please
    print
"You're using Win32. We don't know where Win32 Perl users 
need to have shared library files installed. If you know, 
please tell us. Read the README file and report a bug,
and we'll get this fixed for you soon. 
Thanks---
                       The Reefknot team 
";
    exit 1;

} elsif ($OS eq 'MacOS') {
    # someone with macos speak up here, please
    print
"You're using MacOS. We don't know where Mac users need
to have shared library files installed. If you know, 
please tell us. Read the README file and report a bug,
and we'll get this fixed for you soon. 
Thanks---
                       The Reefknot team 
";
    exit 1;
    
} else {
    print
"You have an OS that this module doesn't know about yet. 
Please read the README file and report a bug. Let us know
what OS you're using and where that OS likes to have 
shared data files put, and we'll get this fixed for you.
Additionally, you should let us know that your OS reports                            
itself as '$OS'.

Thanks---
                       The Reefknot team 
";
    exit 1;
}

#============================================================
sub libical_is_installed {
    my ($config) = @_;

    print "Checking for existing libical timezone files...\n";
    
    # where to look for libical files.
    my @possible_locations = (qw(
            /usr/share/libical-evolution/zoneinfo
            /usr/local/share/libical-evolution/zoneinfo
            /usr/share/libical/zoneinfo));
            
    foreach my $location (@possible_locations) {
        if (-d $location ) {
            print "Found files in $location!\n";
            # check for an arbitrary VTIMEZONE file
            # to confirm that there are actually files
            # there.
            if (-e "$location/Africa/Cairo.ics") {
                print "Confirmed existence of Africa/Cairo timezone file. Good.\n";
                $config->{'zoneinfo_location'} = $location;
                return $config;
            }
        } 
    }

    # We only get here if we weren't successful at finding
    # anything.
    print "no files found.\n";
    $config->{'zoneinfo_location'} = '';
    return $config;
    
}

sub install_vtimezones {
    my ($srcdir, $destdir) = @_;
    print "Installing VTIMEZONE files in $destdir.\n";
    if ($destdir && (! -d $destdir)) {
        $destdir =~ m:(.*)/[^/]+:;
        my $destdirparent = $1;
        unless (-d $destdirparent) {
            mkdir $destdirparent 
                or die "Couldn't create $destdirparent;";
        }
        print "Creating $destdir...\n";
        mkdir $destdir or die "Couldn't create $destdir;";
        # should we have some chmod magic here?
    }
    opendir(DIR, $srcdir) or 
        die "couldn't open $srcdir";
    while (defined(my $subdir = readdir DIR)) {
        my $srcsubdir = "$srcdir/$subdir";
        #print "Looking at $srcsubdir ...\n";
        if ((-d "$srcsubdir") && ($srcsubdir !~ /[.]+/) && ($srcsubdir !~ /^CVS$/)) {
            opendir(SUBDIR, $srcsubdir) 
                or die "couldn't open $srcsubdir";
            unless (-d "$destdir/$subdir") {
                mkdir "$destdir/$subdir" 
                    or die "couldn't mkdir $destdir/$subdir";
            }
            while (defined(my $file = readdir SUBDIR)) {
                my $fullpath = "$srcsubdir/$file";
                if ( ($file =~ /ics$/) && (-f "$fullpath") ) {
                    copy ($fullpath, "$destdir/$subdir/$file") 
                        or die "couldn't copy $fullpath to $destdir/$subdir/$file";
                } elsif ((-d $fullpath) && ($fullpath !~ /[.]+/) && ($fullpath !~ /CVS/)) {
                    # this is really only for America/Indiana. What a mess.
                    # This should be cleaned up. 
                    my $subsubdir = "$destdir/$subdir/$file";
                    unless (-d $subsubdir) {
                        mkdir ($subsubdir) or die "couldn't mkdir $subsubdir";
                    }
                    opendir SUBSUBDIR, $fullpath
                        or die "couldn't open dir $fullpath";
                    while (defined(my $file = readdir SUBSUBDIR)) {
                        my $sourcepath = "$fullpath/$file";
                        if ( ($file =~ /ics$/) && (-f "$fullpath/$file") ) {
                            copy ("$fullpath/$file", "$subsubdir/$file") 
                                or die "couldn't copy $fullpath/$file to $subsubdir/$file";
                        }
                    }
                }
            }
        } elsif ((-f "$srcsubdir") && ($srcsubdir =~ /zones.tab/)) {
            # copy the zones.tab file, which isn't a directory
            copy ($srcsubdir, $destdir) 
                or die "couldn't copy $srcsubdir to $destdir";
        }
    }
    closedir(DIR);
}

sub write_config_module {
    my ($config) = @_;
    my $installed_location = $config->{zoneinfo_location};
    
    # TODO: how do we do this without stepping on any
    # already-installed N::I::Config?
    print "updating Net::ICal::Config...";

    my $oldconfig = "lib/Net/ICal/Config.pm";
    my $newconfig = "lib/Net/ICal/Config.pm.new";
    my $origconfig = "lib/Net/ICal/Config.pm.orig";

    # make sure not to blow away the template config file.
    # TODO: we should also be restoring state on "make clean".
    if (-e $origconfig) {
        unlink $oldconfig;
        rename $origconfig, $oldconfig;
    }
    # hm, this needs to be cross-platform, and it's not yet, help
    open (CONFIGFILE, "< $oldconfig");
    open (CONFIGNEW, "> $newconfig");
    while (<CONFIGFILE>) {
        s/\$\$ZONEINFO_LOCATION\$\$/$installed_location/;
        print CONFIGNEW $_  or die "couldn't print to CONFIGNEW: $!" 
    }
    close CONFIGFILE or die "couldn't close $oldconfig";
    close CONFIGNEW or die "couldn't close $newconfig";
    rename $oldconfig, $origconfig;
    rename $newconfig, $oldconfig;

    print "done.\n";
}
