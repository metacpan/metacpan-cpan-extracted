#!/usr/bin/perl -w
#
# Base subroutines brought by the the Project-Builder project
# which can be easily used by whatever perl project
#
# Copyright B. Cornec 2007-2016
# Eric Anderson's changes are (c) Copyright 2012 Hewlett Packard
# Provided under the GPL v2
#
# $Id$
#

package ProjectBuilder::Base;

use strict;
use lib qw (lib);
use Carp qw/confess cluck/;
use Cwd;
use File::Path;
use Data::Dumper;
use Time::localtime qw(localtime);
use English;
use POSIX qw(locale_h);
use ProjectBuilder::Version;

# Inherit from the "Exporter" module which handles exporting functions.
 
use vars qw($VERSION $REVISION @ISA @EXPORT);
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
 
our $pbdebug = 0;		# Global debug level
our $pbLOG = \*STDOUT;	# File descriptor of the log file
our $pbsynmsg = "Error";	# Global error message
our $pbdisplaytype = "text";
						# default display mode for messages
our $pblocale = "C";

our @ISA = qw(Exporter);
our @EXPORT = qw(pb_mkdir_p pb_system pb_rm_rf pb_get_date pb_log pb_log_init pb_get_uri pb_get_content pb_set_content pb_display_file pb_syntax_init pb_syntax pb_temp_init pb_get_arch pb_get_osrelease pb_check_requirements pb_check_req pb_path_expand pb_exit $pbdebug $pbLOG $pbdisplaytype $pblocale);
($VERSION,$REVISION) = pb_version_init();

=pod

=head1 NAME

ProjectBuilder::Base, part of the project-builder.org - module dealing with generic functions suitable for perl project development

=head1 DESCRIPTION

This module provides generic functions suitable for perl project development 

=head1 SYNOPSIS

  use ProjectBuilder::Base;

  #
  # Create a directory and its parents
  #
  pb_mkdir_p("/tmp/foo/bar");

  #
  # Remove recursively a directory and its children
  #
  pb_rm_rf("/tmp/foo");

  #
  # Encapsulate the system call for better output and return value test
  #
  pb_system("ls -l", "Printing directory content");

  #
  # Analysis a URI and return its components in a table
  #
  my ($scheme, $account, $host, $port, $path) = pb_get_uri("svn+ssh://ac@my.server.org:port/path/to/dir");

  #
  # Gives the current date in a table
  #
  @date = pb_get_date();

  #
  # Manages logs of the program
  #
  pb_log_init(2,\*STDOUT);
  pb_log(1,"Message to print\n");

  #
  # Manages content of a file
  #
  pb_display_file("/etc/passwd",\*STDERR);
  my $cnt = pb_get_content("/etc/passwd");

=head1 USAGE

=over 4

=item B<pb_mkdir_p>

Internal mkdir -p function. Forces mode to 755. Supports multiple parameters.

Based on File::Path mkpath.

=cut

sub pb_mkdir_p {
my @dir = @_;
my $ret = eval { mkpath(@dir, 0, 0755) };
confess "pb_mkdir_p @dir failed in ".getcwd().": $@" if ($@);
return($ret);
}

=item B<pb_rm_rf>

Internal rm -rf function. Supports multiple parameters.

Based on File::Path rmtree.

=cut

sub pb_rm_rf {
my @dir = @_;
my $ret = rmtree(@dir, 0, 0);
return($ret);
}

=item B<pb_system>

Encapsulate the "system" call for better output and return value test.
Needs a $ENV{'PBTMP'} variable which is created by calling the pb_mktemp_init function.
Needs pb_log support, so pb_log_init should have been called before.

The first parameter is the shell command to call. This command should NOT use redirections.
The second parameter is the message to print on screen. If none is given, then the command is printed.
The third parameter prints the result of the command after correct execution if value is "verbose". If value is "noredir", it avoids redirecting outputs (e.g. for vi). If value is "quiet", doesn't print anything at all. If value is "mayfail", failure of the command is ok even if $Global::pb_stop_on_error is set, because the caller will be handling the error. A "verbose" can be added to mayfail to have it explain why it failed. If value is verbose_PREF, then every output command will be prefixed with PREF.
This function returns as a result the return value of the system command.

If no error reported, it prints OK on the screen, just after the message. Else it prints the errors generated.

=cut

sub pb_system {

my $cmd=shift;
my $cmt=shift || $cmd;
my $verbose=shift;
my $redir = "";

pb_log(0,"$cmt... ") if ((! defined $verbose) || ($verbose ne "quiet"));
pb_log(1,"Executing $cmd\n");
unlink("$ENV{'PBTMP'}/system.$$.log") if (-f "$ENV{'PBTMP'}/system.$$.log");
$redir = "2>> $ENV{'PBTMP'}/system.$$.log 1>> $ENV{'PBTMP'}/system.$$.log" if ((! defined $verbose) || ($verbose ne "noredir"));

# If sudo used, then be more verbose
pb_log(0,"Executing $cmd\n") if (($pbdebug < 1) && ($cmd =~ /^\s*\S*sudo/o) && (defined $Global::pb_show_sudo) && ($Global::pb_show_sudo =~ /true/oi));

system("$cmd $redir");
my $res = $?;
# Exit now if the command may fail
if ((defined $verbose) and ($verbose =~ /mayfail/)) {
	pb_log(0,"NOT OK but non blocking\n") if ($res != 0);
	pb_log(0,"OK\n") if ($res == 0);
	pb_display_file("$ENV{'PBTMP'}/system.$$.log",undef,$verbose) if ((-f "$ENV{'PBTMP'}/system.$$.log") and ($verbose =~ /verbose/));
	return($res) 
}

my $cwd = getcwd;
my $error = undef;
$error = "ERROR: failed to execute ($cmd) in $cwd: $!\n" if ($res == -1);
$error = "ERROR: child ($cmd) died with signal ".($res & 127).", ".($res & 128) ? 'with' : 'without'." coredump\n" if ($res & 127);
$error = "ERROR: child ($cmd) cwd=$cwd exited with value ".($res >> 8)."\n" if ($res != 0);

if (defined $error) {
	pb_log(0, $error) if (((! defined $verbose) || ($verbose ne "quiet")) || ($Global::pb_stop_on_error));
	pb_display_file("$ENV{'PBTMP'}/system.$$.log",undef,$verbose) if ((-f "$ENV{'PBTMP'}/system.$$.log") and ((! defined $verbose) || ($verbose ne "quiet") || $Global::pb_stop_on_error));
	if ($Global::pb_stop_on_error) {
		confess("ERROR running command ($cmd) with cwd=$cwd, pid=$$");
	} else {
		pb_log(0,"ERROR running command ($cmd) with cwd=$cwd, pid=$$\n");
	}
} else {
	pb_log(0,"OK\n") if ((! defined $verbose) || ($verbose ne "quiet"));
	pb_display_file("$ENV{'PBTMP'}/system.$$.log",undef,$verbose) if ((-f "$ENV{'PBTMP'}/system.$$.log") and (defined $verbose) and ($verbose ne "quiet"));
}

return($res);
}

=item B<pb_get_uri>

This function returns a list of 6 parameters indicating the protocol, account, password, server, port, and path contained in the URI passed in parameter.

A URI has the format protocol://[ac@]host[:port][path[?query][#fragment]].

Cf man URI.

=cut

sub pb_get_uri {

my $uri = shift;

pb_log(2,"DEBUG: uri:" . (defined $uri ? $uri : '') . "\n");
my ($scheme, $authority, $path, $query, $fragment) =
         $uri =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?| if (defined $uri);
my ($account,$host,$port) = $authority =~ m|(?:([^\@]+)\@)?([^:]+)(:(?:[0-9]+))?| if (defined $authority);

$scheme = "" if (not defined $scheme);
$authority = "" if (not defined $authority);
$path = "" if (not defined $path);
$account = "" if (not defined $account);
$host = "" if (not defined $host);
if (not defined $port) {
	$port = "" 
} else {
	# Remove extra : at start
	$port =~ s/^://;
}

pb_log(2,"DEBUG: scheme:$scheme ac:$account host:$host port:$port path:$path\n");
return($scheme, $account, $host, $port, $path);
}

=item B<pb_get_date>

This function returns a list of 9 parameters indicating the seconds, minutes, hours, day, month, year, day in the week, day in the year, and daylight saving time flag of the current time.

Cf: man ctime and description of the struct tm.

=cut

sub pb_get_date {
	
return(localtime->sec(), localtime->min(), localtime->hour(), localtime->mday(), localtime->mon(), localtime->year(), localtime->wday(), localtime->yday(), localtime->isdst());
}

=item B<pb_log_init>

This function initializes the global variables used by the pb_log function.

The first parameter is the debug level which will be considered during the run of the program?
The second parameter is a pointer on a file descriptor used to print the log info.

As an example, if you set the debug level to 2 in that function, every call to pb_log which contains a value less or equal than 2 will be printed. Calls with a value greater than 2 won't be printed.

The call to B<pb_log_init> is typically done after getting a parameter on the CLI indicating the level of verbosity expected.

=cut

sub pb_log_init {

$pbdebug = shift;
$pbLOG = shift;

$pbdebug = 0 if (not defined $pbdebug);
$pbLOG = \*STDOUT if (not defined $pbLOG);
pb_log(1,"Debug value: $pbdebug\n");

} 

=item B<pb_log>

This function logs the messages passed as the second parameter if the value passed as first parameter is lesser or equal than the value passed to the B<pb_log_init> function.

Here is a usage example:

  pb_log_init(2,\*STDERR);
  pb_log(1,"Hello World 1\n");
  pb_log(2,"Hello World 2\n");
  pb_log(3,"Hello World 3\n");

  will print:
  
  Hello World 1
  Hello World 2

=cut 

sub pb_log {

my $dlevel = shift;
my $msg = shift;

$dlevel = 0 if (not defined $dlevel);
$msg = "" if (not defined $msg);
$pbLOG = \*STDOUT if (not defined $pbLOG);

print $pbLOG "$msg" if ($dlevel <= $pbdebug);
print "$msg" if (($dlevel == 0) && ($pbLOG != \*STDOUT));
}


=item B<pb_display_file>

This function prints the content of the file passed in parameter.
If a second parameter is given, this is the descriptor of the logfile to write to in addtion to STDOUT.
If a third parameter is given, this is the prefix providing it's writen as verbose_PREF. In which case the PREF string will be added before the line output.

This is a cat equivalent function.

=cut

sub pb_display_file {

my $file=shift;
my $desc=shift;
my $prefix=shift;

return if (not -f $file);
my $cnt = pb_get_content($file);
# If we have a prefix, then add it at each line
if ((defined $prefix) and ($prefix =~ "_")) {
	$prefix =~ s/verbose_//;
	$cnt =~ s/(.*)\n/$prefix$1\n/g;
} else {
	$prefix = "";
}
print "$prefix$cnt";
print $desc "$prefix$cnt" if (defined $desc);
}

=item B<pb_get_content>

This function returns the content of the file passed in parameter.

=cut
sub pb_get_content {

my $file=shift;

open(R,$file) || die "Unable to open $file: $!";
local $/;
my $content=<R>;
close(R);
return($content);
}


=item B<pb_set_content>

This function put the content of a variable passed as second parameter into the file passed as first parameter.

=cut

sub pb_set_content {

my $file=shift;
my $content=shift;

my $bkp = $/;
undef $/;
open(R,"> $file") || die "Unable to write to $file: $!";
print R "$content";
close(R);
$/ = $bkp;
}

=item B<pb_exit>

Fundtion to call before exiting pb so cleanup is done

=cut

sub pb_exit {

my $ret = shift;
$ret = 0 if (not defined $ret);
pb_log(0,"Please remove manually $ENV{'PBTMP'} after debug analysis\n") if ($pbdebug > 1);
exit($ret);
}

=item B<pb_syntax_init>

This function initializes the global variable used by the pb_syntax function.

The parameter is the message string which will be printed when calling pb_syntax

=cut

sub pb_syntax_init {

$pbsynmsg = shift || "Error";
}

=item B<pb_syntax>

This function prints the syntax expected by the application, based on pod2usage, and exits.
The first parameter is the return value of the exit.
The second parameter is the verbosity as expected by pod2usage.

Cf: man Pod::Usage

=cut

sub pb_syntax {

my $exit_status = shift;
my $verbose_level = shift;

my $filehandle = \*STDERR;

# Don't do it upper as before as when the value is 0 
# it is considered false and then exit was set to -1
$exit_status = -1 if (not defined $exit_status);
$verbose_level = 0 if (not defined $verbose_level);

$filehandle = \*STDOUT if ($exit_status == 0);

eval {
	require Pod::Usage;
	Pod::Usage->import();
};
if ($@) {
	# No Pod::Usage found not printing usage. Old perl only
	pb_exit();
} else {
	pod2usage(	-message => $pbsynmsg,
			-exitval => $exit_status,
			-verbose => $verbose_level,
			-output  => $filehandle );
}
}

=item B<pb_temp_init>

This function initializes the environemnt variable PBTMP to a random value. This directory can be safely used during the whole program, it will be removed at the end automatically.

=cut

sub pb_temp_init {

my $pbkeep = shift;	

# Do not keep temp files by default
$pbkeep = 0 if (not defined $pbkeep);

if (not defined $ENV{'TMPDIR'}) {
	$ENV{'TMPDIR'}="/tmp";
}

# Makes this function compatible with perl 5.005x
eval {
	require File::Temp;
	File::Temp->import("tempdir");
};
if ($@) {
	# File::Temp not found, harcoding stuff
	# Inspired by http://cpansearch.perl.org/src/TGUMMELS/File-MkTemp-1.0.6/File/MkTemp.pm 
	# Copyright 1999|2000 Travis Gummels.  All rights reserved.  
	# This may be used and modified however you want.
	my $template = "pb.XXXXXXXXXX";
	my @template = split //, $template;
	my @letters = split(//,"1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");
	for (my $i = $#template; $i >= 0 && ($template[$i] eq 'X'); $i--){
		$template[$i] = $letters[int(rand 52)];
	}
	undef $template;
	$template = pack "a" x @template, @template;
	$ENV{'PBTMP'} = "$ENV{'TMPDIR'}/$template";
	pb_mkdir_p($ENV{'PBTMP'});
} else {
	if (($pbdebug > 1) || ($pbkeep == 1)) {
		$ENV{'PBTMP'} = tempdir( "pb.XXXXXXXXXX", DIR => $ENV{'TMPDIR'});
		pb_log(2,"DEBUG: Creating a non-volatile temporary directory ($ENV{'PBTMP'})\n");
	} else {
		$ENV{'PBTMP'} = tempdir( "pb.XXXXXXXXXX", DIR => $ENV{'TMPDIR'}, CLEANUP => 1 );
	}
}
}

=item B<pb_get_osrelease>

This function returns the release of our operating system

=cut

sub pb_get_osrelease {

# On linux can also use /proc/sys/kernel/osrelease
my $rel = `uname -r`;
chomp($rel);
return($rel);
}


=item B<pb_get_arch>

This function returns the architecture of our local environment and
standardize on i386 for those platforms. 

=cut

sub pb_get_arch {

my $arch = `uname -m`;
chomp($arch);
$arch =~ s/i[3456]86/i386/;
# For Solaris
$arch =~ s/i86pc/i386/;

return($arch);
}

=item B<pb_check_requirements>

This function checks that the commands needed for the subsystem are indeed present. 
The required commands are passed as a comma separated string as first parameter.
The optional commands are passed as a comma separated string as second parameter.

=cut

sub pb_check_requirements {

my $req = shift;
my $opt = shift;
my $appname = shift;

my ($req2,$opt2) = (undef,undef);
$req2 = $req->{$appname} if (defined $req and defined $appname);
$opt2 = $opt->{$appname} if (defined $opt and defined $appname);

# cmds is a string of comma separated commands
if (defined $req2) {
	foreach my $file (split(/,/,$req2)) {
		pb_check_req($file,0);
	}
}

# opts is a string of comma separated commands
if (defined $opt2) {
	foreach my $file (split(/,/,$opt2)) {
		pb_check_req($file,1);
	}
}
}

=item B<pb_check_req>

This function checks existence of a command and return its full pathname or undef if not found.
The command name is passed as first parameter.
The second parameter should be 0 if the command is mandatory, 1 if optional.
It returns the full path name of the command if found, undef otherwise and dies if that was a mandatory command

=cut

sub pb_check_req {

my $file = shift;
my $opt = shift;
my $found = undef;

$opt = 1 if (not defined $opt);

pb_log(2,"Checking availability of $file...");
# Check for all dirs in the PATH
foreach my $p (split(/:/,$ENV{'PATH'})) {
	if (-x "$p/$file") {
		$found =  "$p/$file";
		last;
	}
}

if (not $found) {
	pb_log(2,"KO\n");
	if ($opt eq 1) {
		pb_log(2,"Unable to find optional command $file\n");
	} else {
		die pb_log(0,"Unable to find required command $file\n");
	}
} else {
	pb_log(2,"OK\n");
}
return($found);
}

=item B<pb_path_expand>

Expand out a path by environment variables as ($ENV{XXX}) and ~

=cut

sub pb_path_expand {

my $path = shift;

eval { $path =~ s/(\$ENV.+\})/$1/eeg; };
$path =~ s/^\~/$ENV{HOME}/;

return($path);
}

=back 

=head1 WEB SITES

The main Web site of the project is available at L<http://www.project-builder.org/>. Bug reports should be filled using the trac instance of the project at L<http://trac.project-builder.org/>.

=head1 USER MAILING LIST

None exists for the moment.

=head1 AUTHORS

The Project-Builder.org team L<http://trac.project-builder.org/> lead by Bruno Cornec L<mailto:bruno@project-builder.org>.

=head1 COPYRIGHT

Project-Builder.org is distributed under the GPL v2.0 license
described in the file C<COPYING> included with the distribution.

=cut

1;
