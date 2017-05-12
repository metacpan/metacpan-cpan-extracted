package RPM::Update;

use Getopt::Long;
use vars qw(
	    $VERSION
	    );

$VERSION='0.1';

=pod

=head1 NAME

RPM::Update - compare installed rpms with up-to-date distribution

=head1 SYNOPSIS

 use RPM::Update;

 RPM::Update::execute('-ftp',
               'mirror.pa.msu.edu/linux/redhat/linux/updates/7.2/en/os/',
               '-d','check','-dl');

=head1 README

I<RPM::Update> compares installed RPM packages (listed by the command
"rpm -qa") on a Linux system with an up-to-date distribution. That
distribution may either reside in a local directory (possibly NFS
mounted) or on a ftp server.

=head1 DESCRIPTION

Based on Martin Siegert's I<check-rpms> at
L<http://www.sfu.ca/acs/security/linux/check-rpms.html>.

Options are to be specified as a list of arguments to
B<RPM::Update::execute>.

I<RPM::Update> compares installed RPM packages (listed by the command
"rpm -qa") on a Linux system with an up-to-date distribution. That
distribution may either reside in a local directory (possibly NFS
mounted) or on a ftp server.  If the B<-ftp> option is specified,
I<RPM::Update> retrieves directory listings from the I<ftpserver>'s
I<directory>/<arch> directories, where <arch> is set to noarch, i386,
i586, i686, and athlon consecutively. If I<ftpserver/directory> is
not specified, $FTPSERVER/$FTPUPDATES is used. The $FTPSERVER and
$FTPUPDATES variables can be set in the configuration file. If
either of the two is not set, the default server "updates.redhat.com"
and the default directory "$RHversion/en/os" is used,
where $RHversion is obtained from the /etc/redhat-release file. If
run with the B<-ftp> option, all rpm packages that need to be downloaded
(see the B<--download>, B<--recheck>, and B<--update> options) will
be downloaded into the directory specified by the B<-d> directory
option. If that option is omitted the $RPMDIR directory is used.
The $RPMDIR variable that can be set in the configuration file. If
$RPMDIR variable is not set either, the default directory
"/mnt/redhat/RedHat/RPMS" is used.

If the B<-ftp> is omitted, it is assumed that B<-d> I<directory> specifies
a local directory that contains up-to-date rpm packages. If B<-d>
I<directory> is omitted as well, the $RPMDIR directory is used. If
$RPMDIR is not set, the default directory "/mnt/redhat/Red-
Hat/RPMS" is used.

I<RPM::Update> uses a lexical sort on the version string and the
release string of the package in order to decide whether the
installed package or the package form the distribution is newer.
I<RPM::Update> lists packages of the distribution that are found to be
newer than the installed packages or, if B<--update> is specified,
will update the packages using the "rpm -Fvh <list of packages>"
command. In the latter case I<RPM::Update> must be run as root. Fur-
thermore, the $RPMUSER variable should be set to a non-root user-
name (see the B<-c> option below). I<RPM::Update> will switch to that
user and run most of the script under that user id.Only the
final "rpm -Fvh ..." command will be run as root. If $RPMUSER is
not set, the "nobody" user id will be used. It is recommended to
set $RPMUSER to an ordinary username (such as yourself). Further-
more, if a ftp server is used, create the download directory
(which is specified in the B<-d> directory option or in the $RPMDIR
variable), change the owner ship of that directory to that user,
and set the permissions to 700 before running I<RPM::Update> with the
B<--update> option. Note, that B<--update> implies the B<--no-kernel>
option, i.e., I<RPM::Update> refuses to update the kernel directly.

=cut

=pod

=head1 OPTIONS

=over 4

=item B<-v> B<--verbose>

verbose  mode:  prints  additional  progress information on
standard output

=item B<-ftp> [I<ftpserver/directory>]

compare the installed packages with the rpm packages found
on the ftp server I<ftpserver> in the directories I<directory>/<arch>,
where arch is set to noarch, i386, i586, i686,
and athlon consecutively. If I<ftpserver/directory> is not
specified, the $FTPSERVER and $FTPUPDATES variables are
checked. These variables can be set in the configuration
file (see the B<-c> option below). If those variables are not
set either, the default server "updates.redhat.com" and the
default directory "$RHversion/en/os" is used, where $RHversion
is obtained from the I</etc/redhat-release> file.

=item B<-noftp>

use  a  local  directory as the source for new rpm packages
even if the $FTP veriable is set to 1 in the  configuration
file.

=item B<-d> I<directory> B<--rpm-directory> I<directory>

if B<-ftp> is specified download all rpm packages that need to
be downloaded into I<directory>. If B<-ftp> is not specified,
regard the rpm packages found in I<directory> as an up-to-date
distribution against which the installed packages are
compared to.

=item B<-lm> B<--list-missing>

list installed packages that do not have an equivalent in
the up-to-date distribution. This will generate lots of
output when the comparison is made with the updates directory
of a ftp server.

=item B<-lq> B<--list-questionable>

list packages for which the lexical sort algorithm does not
give a conclusive result on whether the installed package
is older than the package in the distribution. These are
packages that have version and/or release strings that contain
letters. For example, it is not absolutely clear
whether the version 1.2.3b is actually newer or older than
1.2.3. The lexical sort would classify 1.2.3b to be newer
than 1.2.3; with B<-lq> specified the package would be listed
in any case. See also B<--recheck> below.

=item B<-dl> B<--download>

download packages from the remote ftp server that are found
to be newer than installed packages into the directory that
is specified in the B<-d> I<directory> option or in the $RPMDIR
variable or, if neither of the two are specified, into
"/mnt/redhat/RedHat/RPMS". If the download directory does
not exist, I<check-rpms> will create it.

=item B<-r> B<--recheck>

Use the "rpm -Uvh --test --nodeps <package>" command to
check all packages that have letters in their version
and/or release string; B<--recheck> implies B<--list-questionable>
(see above). At the time of writing (Feb. 2002) there
is one known case for which the lexical sort algorithm
fails to detect a new package: mutt-1.2.5.1 was released to
replace mutt-1.2.5i, however, the lexical sort algorithm
incorrectly classifies mutt-1.2.5i to be  newer  than
mutt-1.2.5.1. In this case using the B<--recheck> option is
essential. In all other cases it is not. It is nevertheless
probably a good idea to use B<--recheck> at least once in a
while. B<--recheck> can increase the run-time of I<check-rpms>
substantially, particularly if a ftp server is used. In
that case the questionable packages must be downloaded from
the server into a directory I<directory> (as specified in the
-d option or the $RPMDIR variable) which will be created,
if it does not exist.

=item B<-nk> B<--no-kernel>

do not list kernel packages. That is, kernel, kernel-smp,
kernel-enterprise, kernel-BOOT, and kernel-debug will not
be checked and listed. However, kernel-headers and kernel-source
will be checked. The B<--update> option (see below)
implies B<--no-kernel>.

=item B<--update>

update all packages that were found to have newer versions.
For this to work I<check-rpms> must be run as root and a suitable
$RPMUSER must exist (see DESCRIPTION above). It is
strongly advisable to do a dry run B<check-rpms -v -lq> before
running B<check-rpms --update>.

=item B<-c> I<configurationfile>

The optional configuration file to use. This file can be
used to specify the $RPMDIR variable, the $FTP, $FTPSERVER,
and $FTPUPDATES, variables, and the $RPMUSER variable. An
example configuration file is given below. If the B<-c> option
is omitted, I<check-rpms> will use the default configuration
file I</usr/local/etc/check-rpms.conf>, if it exists.

=back

=head1 EXAMPLES

=over 4

=item check-rpms

will 1) check whether /usr/local/etc/check-rpms.conf exists; 2) if
it does it will read the variables specified in that file, if it
doesn't exist, $RPMDIR is set to /mnt/redhat/RedHat/RPMS; 3) if
$RPMDIR is set, this directory will be regarded as the source of
the up-to-date distribution, unless $FTP is set to 1. In that latter
case the $FTPSERVER and $FTPUPDATES are used, if those variables are
set. Otherwise "updates.redhat.com" and "<RHversion>/en/os"
will be used; 4) the installed packages are compared

=item check-rpms -v -lq -d /mnt/redhat/7.1/RedHat/RPMS

will use the distribution in the directory /mnt/redhat/7.1/RedHat/RPMS
for comparison with the installed packages. The command
will give more detailed information on its progress and will list
the packages that need upgrading and in another section it will
list packages they may need to be upgraded.

=item check-rpms -v -lq -ftp updates.redhat.com/7.1/en/os

same as above, but the directories 7.1/en/os/noarch,
7.1/en/os/i386, 7.1/en/os/i586, 7.1/en/os/i686, and
7.1/en/os/athlon on updates.redhat.com will be searched for new
packages.

=item check-rpms -v -r --updates

will use the default location for updated packages (determined as
indicated in the first example); if a ftp server is used, it will
download all newer and all packages with letters in the version
and/or release strings (i.e., "questionable" packages) from that
ftp server, recheck the questionable packages, and finally update
all packages that need to be updated.

=back

=cut

=pod

=head1 The Configuration File

All variables must be defined using perl syntax, i.e., in the form

$variable = value;

(do not forget the semicolon at the  end  of  a  line).   Comments
start with "#" and blank lines may be included as well.

Example configuration file:

 # check-rpms configuration file

 # $RPMDIR is the directory where up-to-date RPMs can be found and/or
 # rpm packages are downloaded into.
 $RPMDIR = "/mnt/redhat/RedHat/RPMS";

 # $RPMUSER is the user name that check-rpms switches to for most of
 # the script when run as root
 $RPMUSER = "joe";

 # $FTPSERVER and $FTPUPDATES are the hostname of a ftp server and the
 # directory where RPM updates can be found without the <arch> directory.
 # I.e., $FTPUPDATES should be set to something like pub/7.2, if the RPMs
 # are located in pub/7.2/i386, pub/7.2/i686, etc.
 # $FTPSERVER and $FTPUPDATES are used if -ftp is specified or if the following
 # line is uncommented.
 # $FTP = 1;
 $FTPSERVER = "updates.redhat.com";
 $FTPUPDATES = "7.2/en/os";

=cut

=pod

=head1 SEE ALSO

rpm(8), ncftpls(1), ncftpget(1)

=head1 AUTHOR

Author of the "check-rpms" script on which this module
is strongly based is
Martin Siegert, Simon Fraser University, siegert@sfu.ca

The module packager is Scott Harrison,
Michigan State University, sharrison@users.sourceforge.net

=head1 LICENSE

check-rpms.pl is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

check-rpms.pl is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details:
http://www.gnu.org/licenses/gpl.html

=cut

sub execute {
    my (@options)=@_;
    @ARGV=(@options);
    print @ARGV;
   my $retval=&GetOptions("verbose|v","lm|list-missing","lq|list-questionable",
                         "dir|d=s","ftp:s","noftp","download|dl","recheck|r",
			   "nk|no-kernel","update","c=s");
    if ( $retval == 0 ) {
	usage();
    }
    # executables
    $FTPLS = "ncftpls";
    $FTPGET = "ncftpget";
    $GREP = "grep";
    
    # default values
    $RHversion = (split /\s/, `cat /etc/redhat-release`)[4];
    $DEFCONF = "/usr/local/etc/check-rpms.conf";
    $DEFRPMDIR = "/mnt/redhat/RedHat/RPMS";
    $DEFFTPSERVER = "updates.redhat.com";
    $DEFFTPUPDATES = "$RHversion/en/os";
    $DEFRPMUSER = "nobody";
    
    $RPMDIR=$DEFRPMDIR;

    # configuration
    # the configuration file should set the $RPMDIR variable and/or $FTPSERVER,
    # $FTPUPDATES and $DOWNLOADDIR variables, and the $RPMUSER variable.
    if ($opt_c) {
	$CONF = $opt_c;
    } else {
	$CONF = $DEFCONF;
    }
    if ( -f $CONF) {
	require($CONF);
    } else {
	$FTPSERVER = $DEFFTPSERVER;
	$FTPUPDATES = $DEFFTPUPDATES;
    }

    # check whether we are running as root
    if ($< == 0){
	if (! $RPMUSER) {
	    $RPMUSER = $DEFRPMUSER;
	}
	$RPMUID = getpwnam($RPMUSER);
	if (! $RPMUID) {
	    die "You do not seem to have a $RPMUSER user on your system.\nSet the \$RPMUSER variable in the $CONF configuration file to a non-root user.\n";
	}
	if ($RPMUID == 0) {
	    die "You must set the \$RPMUSER variable in $CONF to a non-root user.\n";
	}
	# switch to $RPMUID
	$> = $RPMUID;
	if ($> != $RPMUID) { die "switching to $RPMUID uid failed.\n" }
    }
    
    # command-line arguments
    $verbose         = $opt_verbose;
    $list_missing    = $opt_lm;
    $questionable    = $opt_lq;
    $no_kernel       = $opt_nk;
    $download        = $opt_download;
    $recheck         = $opt_recheck;
    $update          = $opt_update;

    if (defined $opt_update && $< != 0) {
	die "You must be root in order to update rpms.\n";
    }

    if ( defined $opt_dir ){
	$RPMDIR = $opt_dir;
    }

    if (defined $opt_ftp && defined $opt_noftp) {
	die "Setting -ftp and -noftp does not make sense, does it?\n";
    }

    if (defined $opt_noftp) { $FTP = 0; }

    if (defined $opt_ftp || $FTP) {
	$ftp = 1;
	if ( $opt_ftp ) {
	    $_ = $opt_ftp;
	    ($FTPSERVER, $FTPUPDATES) = m/^([^\/]+)\/(.*)$/;
	} elsif ( ! ($FTPSERVER && $FTPUPDATES)) {
	    $FTPSERVER = $DEFFTPSERVER;
	    $FTPUPDATES = $DEFFTPUPDATES;
	}
	
	if (defined $opt_update){
	    $download=1;
	}

	if ($download || $recheck) {
	    if ( ! -d $RPMDIR) {
		if ($verbose) { print "Creating $RPMDIR ...\n"; }
		if ($< == 0) {
		    $retval = system("su $RPMUSER -c \'mkdir -p $RPMDIR\'; chmod 700 $RPMDIR");
		} else {
		    $retval = system("mkdir -p $RPMDIR; chmod 700 $RPMDIR");
		}
		if ($retval) { die "error: could not create $RPMDIR\n"; }
	    }
	}
    } elsif ( (! -d $RPMDIR) || system("ls $RPMDIR/*.rpm > /dev/null 2>&1")) {
	die "Either $RPMDIR does not exist or it does not contain any packages.\n";
    }

    if ($recheck) {
	$questionable=1;
    }

    if (defined $opt_update || defined $opt_nk) {
	$no_kernel=1;
    }

    $PROC = `grep -i athlon /proc/cpuinfo`;
    if ( ! "$PROC" ) {
	$PROC = `uname -m`;
	chomp($PROC);
    } else {
	$PROC = "athlon";
    }

    @ARCHITECTURES = ("noarch", "i386", "i586", "i686");
    if ( $RHversion > 7.0 ){ 
	push(@ARCHITECTURES, "athlon");
    }

    # get the local list of installed packages

    if ($verbose) {
	print "updates for $PROC processor, RH $RHversion\n";
	print "Getting list of installed packages\n";
    }
    
    if ($< == 0) {
	@local_rpm_list = `su $RPMUSER -c 'rpm -qa'`;
    } else {
	@local_rpm_list = `rpm -qa`;
    }
    chop(@local_rpm_list);
    
    %local_rpm = %remote_rpm = ();

    for (@local_rpm_list) {
    #    good place to test the regular expressions...
    #    ($pkg, $ver, $release) = m/^(.*)-([^-]*)-([^-]+)/;
    #    print "$_\t->$pkg, $ver, $release\n";

	my ($pkg, $pver) = m/([^ ]*)-([^-]+-[^-]+)/;
	$local_rpm{$pkg} = $pver;
    }
    
    # now connect to the remote host
    
    my @templist;
    if ($ftp) {
	if ( `rpm -q ncftp --pipe "grep 'not installed'"` ) {
	    die "you must have the ncftp package installed in order to use a\n",
	    "ftp server with check-rpms.\n";
	}
	$SOURCE = $FTPSERVER;
	for (@ARCHITECTURES) {
	    my $FTPDIR = "$FTPUPDATES/$_";
	    if ($verbose) {
		print ("Getting package lists from $FTPSERVER/$FTPDIR ...\n");
	    }
	    push(@templist, grep(/\.rpm$/, `$FTPLS -x "-1a" "ftp://$FTPSERVER/$FTPDIR/"`));
	    if ($?) { print STDERR "$FTPLS failed with status ",$?/256,".\n"; }
	}
    } else {
	$SOURCE = $RPMDIR;
	if ($verbose) {
	    print ("Getting package lists from $RPMDIR ...\n");
	}
	@templist = grep(/\.rpm$/, `(cd $RPMDIR;ls -1)`);
    }

    #
    # If two versions of the same RPM appear with different architectures
    # and/or different versions, the right one must be found.
    #

    $giveup = 0;
    for (@templist) {
	($rpm, $pkg, $pver, $arch) = m/(([^ ]*)-([^- ]+-[^-]+\.(\w+)\.rpm))/;
	if (! defined $local_rpm{$pkg}) { next; }
	if ($remote_rpm{$pkg}) {
	    # problem: there are several versions of the same package.
	    # this means that the package exists for different architectures
	    # (e.g., kernel, glibc, etc.) and/or that the remote server
	    # has several versions of the same package in which case the
	    # latest version must be picked.
	    my ($pkg1) = ($remote_rpm{$pkg} =~ m/([^-]+-[^-]+)\.\w+.rpm/);
	    my ($pkg2) = ($pver =~ m/([^-]+-[^-]+)\.\w+.rpm/);
	    my ($vcmp, $qflag) = cmp_versions($pkg1, $pkg2);
	    if ($qflag && $questionable) {
		# cannot decide which of the two is newer - what should we do?
		# print a warning that lists the two rpms.
		# If running with --update, both packages must be rechecked with 
		# rpm -qp --queryformat '%{SERIAL}' <pkg>
		if ($recheck || $update) {
		    my $decision = pkg_compare("$pkg-$remote_rpm{$pkg}",$rpm, $vcmp);
		    if ($decision < 0) {
			# an error in the ftp download routine accured: giveup
			$remote_rpm{$pkg} = undef;
			$giveup = 1;
		    } elsif ($decision > 0) {
			# second package is newer
			$remote_rpm{$pkg} = $pver;
		    }
		    next;
		} else {
		    mulpkg_msg("$pkg-$remote_rpm{$pkg}", $rpm, $vcmp);
		    print "** check whether this is correct or rerun with --recheck option.\n";
		    if ($vcmp < 0) {
			$remote_rpm{$pkg} = $pver;
		    }
		}
	    }
	    if ($vcmp == 0) {        
		# versions are equal: must be different architecture
		# procedure to select the correct architecture:
		# if $PROC = athlon: if available use $arch = athlon (exist for
		# RH 7.1 or newer) otherwise use i686
		# if $PROC = ix86: choose pkg with $PROC cmp $arch >= 0 and
		# $arch cmp $prev_arch = 1
		$_ = $remote_rpm{$pkg};
		($prev_arch) =  m/.*\.(\w+)\.rpm$/;
		if (cmp_arch($arch,$prev_arch)) { $remote_rpm{$pkg} = $pver };
	    } elsif ($vcmp < 0) {    # second rpm is newer
		$remote_rpm{$pkg} = $pver;
	    }
	} else {
	    $remote_rpm{$pkg} = $pver;
	}
    }

    if ($giveup && defined $opt_update) {
	die "Multiple versions of the same package were found on the server.\n",
	"However, due to ftp download problems it could not be verified\n",
	"which of the packages are the most recent ones.\n",
	"If the choices specified above appear to be correct, rerun check-rpms\n",
	"without the -lq (or --list-questionable) option. Otherwise, fix the download\n",
	"problems or install those packages separately first.\n";
    }
    
    #
    # check for UPDated and DIFferent packages...
    #

    for (@local_rpm_list) {
	my ($pkg,  $version) = m/^([^ ]*)-([^-]+-[^-]+)$/;
	if (! $pkg) { print "Couldn't parse $_\n"; next; }
	if ($no_kernel) {
	    if ($pkg eq 'kernel' || $pkg eq 'kernel-smp'
		|| $pkg eq 'kernel-enterprise' || $pkg eq 'kernel-BOOT'
		|| $pkg eq 'kernel-debug') { next; }
	}
	if (defined $remote_rpm{$pkg}) { 
	    # this package has an update
	    my ($rversion) = ($remote_rpm{$pkg} =~ m/([^-]+-[^-]+)\.\w+.rpm/);
	    my $rpm = ($pkg . '-' . $remote_rpm{$pkg});
	    my ($vcmp,$qflag) = cmp_versions($version, $rversion);
	    if ( $qflag && $questionable ) {
		# at least one of the version strings contains letters
		push(@q_updates, $rpm);
	    } elsif ( $vcmp < 0 ) {
		# local version is lower
		push(@updates, $rpm);
	    }
	} elsif ($list_missing) {
	    print "Package '$pkg' missing from remote repository\n";
	}
    }
    
    if ($recheck && @q_updates) {
	if ($ftp) {    
	    for (@q_updates) {
		($arch) = m/[^ ]*-[^- ]+-[^-]+\.(\w+)\.rpm/;
		push(@ftp_files, "$FTPUPDATES/$arch/$_");
	    }
	    if ($verbose) {
		print "Getting questionable packages form $FTPSERVER ...\n";
	    }
	    my $status = system("$FTPGET $FTPSERVER $RPMDIR @ftp_files");
	    if ($status) {
		if ($< == 0) {
		    # if we are running as root exit to avoid symlink attacks, etc.
		    die "$FTPGET failed with status ", $status/256, ".\n";
		} else {
		    print STDERR "warning: $FTPGET failed with status ", $status/256, ".\n";
		} 
	    }
	}
	for (@q_updates) {
	    if ($verbose) {print "** rechecking $_ ... ";}
	    my $errmsg = `rpm -Uvh --test --nodeps --pipe 'grep -v ^Preparing' $RPMDIR/$_ 2>&1`;
	    if (! $errmsg) {
		# no error message, i.e., the rpm is needed.
		push(@updates,$_);
		if ($verbose) {print "needed!\n";}
	    } elsif ($verbose) {
		print "not needed:\n$errmsg\n";
	    }
	}
	@q_updates=();
    }
       
    #
    # print list of new files and download ...
    #

    @updates = sort @updates;
    if (@updates) {
	if ($verbose) {
	    print "\nRPM files to be updated:\n\n";
	}
	for (@updates) {
	    print "$_\n";
	}
	if ($download) {
	    @ftp_files=();
	    for (@updates) {
		($arch) = m/[^ ]*-[^- ]+-[^-]+\.(\w+)\.rpm/;
		push(@ftp_files, "$FTPUPDATES/$arch/$_");
	    }
	    if ($verbose) {
		print "starting downloads ... \n";
	    }
	    my $status = system("$FTPGET $FTPSERVER $RPMDIR @ftp_files");
	    if ($status) {
		if ($< == 0) {
		    # if we are running as root exit to avoid symlink attacks, etc.
		    die "$FTPGET failed with status ", $status/256, ".\n";
		} else {
		    print STDERR "warning: $FTPGET failed with status ", $status/256, ".\n";
		} 
	    } elsif ($verbose) {
		print "... done.\n";
	    }
	}           
    }
    
    @q_updates = sort @q_updates;
    if (@q_updates && $questionable) {
	if ($verbose) {
	    print "\nRPM files that may need to be updated:\n\n";
	    for (@q_updates) {
		my ($old) = m/^([^ ]*)-[^-]+-[^-]+\.\w+\.rpm$/;
		$old = `rpm -q $old`;
		chomp($old);
		print "upgrade ", $old, " to ", $_, " ?\n";
	    }
	} else {
	    for (@q_updates) {
		print "$_\n";
	    }
	}
	if ($download) {
	    @ftp_files=();
	    for (@updates) {
		($arch) = m/[^ ]*-[^- ]+-[^-]+\.(\w+)\.rpm/;
		push(@ftp_files, $FTPUPDATES/$arch/$_);
	    }
	    if ($verbose) {
		print "starting downloads ... \n";
		system("$FTPGET $FTPSERVER $$RPMDIR @ftp_files");
		print "... done.\n";
	    } else {
		system("$FTPGET $FTPSERVER $$RPMDIR @ftp_files");
	    }
	}           
    }
    
    if ($verbose && !(@updates || @q_updates)) {
	print "No new updates are available in $SOURCE\n";
    }
    
    if ($opt_update) {
	if (@q_updates){
	    push(@updates,@q_updates);
	}
	if (@updates) {
	    if ($verbose) {
		print "Running rpm -Fvh ...\n";
	    }
	    # switch to UID=0
	    $> = $<;
	    system("(cd $RPMDIR;rpm -Fvh @updates)");
	}
    }
}
# download routine
sub ftp_download {
    my ($FTPSERVER, $FTPDIR, $downloaddir, @packages) = @_;
    my @ftp_packages=();
    for (@packages) {
	my ($arch) = m/[^ ]*-[^-]+-[^-]*\.(\w+)\.rpm$/;
	push(@ftp_packages,"$FTPDIR/$arch/$_");
    }
    my $status = system("$FTPGET $FTPSERVER $downloaddir @ftp_packages");
    return $status;
}

sub pkg_compare($$$) {
    my ($pkg1, $pkg2, $cmp) = @_;
    if (defined $opt_ftp) {
	if ($verbose) {
	    my ($pkg) = ($pkg1 =~ /([^ ]*)-[^-]+-[^-]+\.\w+\.rpm/);
	    print "The ftp server provides multiple versions of the $pkg package.\n",
	    "Downloading $pkg1 and $pkg2 in order to find out which is newer.\n";
	}
	my $status = ftp_download($FTPSERVER, $FTPUPDATES, $RPMDIR, ($pkg1, $pkg2));
	if ($status) {
	    # at this point just give up ...
	    print STDERR "** $FTPGET failed with status ", $status/256, ".\n";
	    mulpkg_msg($pkg1, $pkg2, $cmp);
	    return -1;
	}
    }
    my $serial1 = `rpm -qp --queryformat '%{SERIAL}' $RPMDIR/$pkg1`;
    my $serial2 = `rpm -qp --queryformat '%{SERIAL}' $RPMDIR/$pkg2`;
    if ($serial2 > $serial1) {
	remove_pkg("$RPMDIR/$pkg1");
	return 1;
    } else {
	remove_pkg("$RPMDIR/$pkg2");
	return 0;
    }
}

sub remove_pkg($) {
    my ($pkg) = @_;
    if ($verbose) {
	print "Removing $pkg ...\n";
    }
    my $status = system("rm -f $pkg");
    if ($status) {
	printf STDERR "error: could not remove $pkg. You must remove this file before updating.\n";
	if ($update) { $giveup = 1; }
    }
}

sub mulpkg_msg($$$) {
    my ($pkg1, $pkg2, $cmp) = @_;
    print "** The server provides two versions of the same package:\n",
    "** $pkg1 and $pkg2.\n";
    if ($cmp > 0) {
	print "** It appears that $pkg-$remote_rpm{$pkg} is newer.\n"
	} else {
	    print "** It appears that $pkg-$pver is newer.\n";
	}
}

#############################################################################
#
# Version comparison utilities
#

sub hack_version($) {
    my ($pver) = @_;
    $pver =~ s/(\d+)/sprintf("%08d", $1)/eg; # pad numbers with leading zeros to make alphabetical sort do the right thing
    $pver =  (sprintf "%-80s", $pver);	     # pad with spaces so that "3.2.1" is greater than "3.2"
    return $pver;
}

sub cmp_versions($$) {
    my ($pkg1, $pkg2) = @_;
    
    # shortcut if they're obviously the same.
    return (0,0) if ($pkg1 eq $pkg2);

    # split into version and release
    my ($ver1, $rel1) = ($pkg1 =~ m/([^-]+)-([^-]+)/);
    my ($ver2, $rel2) = ($pkg2 =~ m/([^-]+)-([^-]+)/);

    if ($ver1 ne $ver2) {
       my $qflag = ((grep /[A-z]/, $ver1) || (grep /[A-z]/, $ver2));
       $ver1 = hack_version($ver1);
       $ver2 = hack_version($ver2);
       return ($ver1 cmp $ver2, $qflag);
    } else {
       my $qflag = ((grep /[A-z]/, $rel1) || (grep /[A-z]/, $rel2));
       $rel1 = hack_version($rel1);
       $rel2 = hack_version($rel2);
       return ($rel1 cmp $rel2, $qflag);
    }
}

sub cmp_arch($$) {
    my ($arch1, $arch2) = @_;
    my $retval = 0;
    $archcmp = ($arch1 cmp $arch2) > 0;
    if ( "$PROC" eq "athlon" ) {
       if ( "$arch2" ne "athlon" 
              && ( "$arch1" eq "athlon" || $archcmp )){
	   $retval = 1;
       }
    } elsif ( $archcmp && ($PROC cmp $arch1) >= 0 ) {
       $retval = 1;
    }
    return $retval;
}

# @tests = ('3.2', '3.2',
#           '3.2a', '3.2a',
#           '3.2', '3.2a',
#           '3.2', '3.3',
#           '3.2', '3.2.1',
#           '1.2.5i', '1.2.5.1',
#           '1.6.3p6', '1.6.4');
# 
# while (@tests) {
#     $a = shift(@tests);
#     $b = shift(@tests);
#     printf "%-10s < %-10s = %d\n", $a, $b, cmp_versions($a, $b);
# }
#
# And the correct output is...
#
#     3.2        < 3.2        = 0
#     3.2a       < 3.2a       = 0
#     3.2        < 3.2a       = -1
#     3.2        < 3.3        = -1
#     3.2        < 3.2.1      = -1
#     1.2.5i     < 1.2.5.1    = -1
#     1.6.3p6    < 1.6.4      = -1
#
# the lexical sort does not give the correct result in the second to last case.


sub usage() {
  die "usage: check-rpms [-v | --verbose]  [-d directory | --dir directory]\n",
      "                  [-ftp [server/directory]] [-noftp] [-lm | --list-missing]\n",
       "                  [-lq | --list-questionable] [-r | --recheck ]\n",
       "                  [-nk | --no-kernel] [--update] [-c configurationfile]\n";
}

1;
