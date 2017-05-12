#
# Copyright 1999-2003 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#ident	"@(#)Project.pm	1.5	03/03/13 SMI"
#
# Project.pm provides the bootstrap for the Sun::Solaris::Project module, and
# also functions for reading, validating and writing out project(4) format
# files.
#

require 5.6.1;
use strict;
use warnings;

package Sun::Solaris::Project;

our $VERSION = '1.5';
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our (@EXPORT_OK, %EXPORT_TAGS);
my @constants = qw(MAXPROJID PROJNAME_MAX PROJF_PATH PROJECT_BUFSZ
    SETPROJ_ERR_TASK SETPROJ_ERR_POOL);
my @syscalls = qw(getprojid);
my @libcalls = qw(setproject activeprojects getprojent setprojent endprojent
    getprojbyname getprojbyid getdefaultproj fgetprojent inproj
    getprojidbyname);
my @private = qw(projf_read projf_write proj_validate projf_validate);
@EXPORT_OK = (@constants, @syscalls, @libcalls, @private);
%EXPORT_TAGS = (CONSTANTS => \@constants, SYSCALLS => \@syscalls,
    LIBCALLS => \@libcalls, PRIVATE => \@private, ALL => \@EXPORT_OK);

use base qw(Exporter);
use Sun::Solaris::Utils qw(gettext);

#
# Read in the passed project filehandle.  Returns a reference to an array of
# project entries in the same format as returned by getprojent et al. 
#
sub projf_read($)
{
	my ($fh) = @_;
	my ($line, @projf);
	while (defined($line = <$fh>)) {
		my @proj;
		chomp($line);
		@proj = split(/:/, $line, 6);
		$proj[2] = '' if (! defined($proj[2]));
		$proj[3] = defined($proj[3]) ? [split(/,/, $proj[3])] : [];
		$proj[4] = defined($proj[4]) ? [split(/,/, $proj[4])] : [];
		$proj[5] = '' if (! defined($proj[5]));
		push(@projf, \@proj);
	}
	return(\@projf);
}

#
# Write out to the passed project filehandle.  Fisrt parameter is a filehandle,
# second is a reference to an array of project entries in the same format as
# returned by getprojent et al.
#
sub projf_write($$)
{
	my ($fh, $projf) = @_;
	foreach my $proj (@$projf) {
		$proj->[3] = join(',', @{$proj->[3]});
		$proj->[4] = join(',', @{$proj->[4]});
		print($fh join(':', @$proj), "\n");
	}
}

#
# Validate a project entry in the same format as returned by getprojent et al.
# The first arg is a reference to a project record as returned by getprojent.
# The second argument is a reference to a flags hash, where the currently
# understood flags are:
#     'dup' - Allow duplicate projid
#     'res' - Allow projid in the reserved (0-99) range
# If project names are to be checked for uniqueness, a reference to a project
# file array as returned by projf_read should be passed as the third argument.
# In a scalar context the number of errors found will be returned, in a list
# context a list of error messages for the entry will be returned.  Each entry
# in the list is in turn a list containing an exit code followed by a printf
# format string and any required arguments.
#
sub proj_validate($;$$)
{
	my ($proj_rec, $flag, $projf) = @_;
	my ($pname, $id, $comment, $user, $group, $attr) = @$proj_rec;
	$flag ||= {};
	my ($low_projid, $linelen, @err);
	$low_projid = exists($flag->{res}) ? 0 : 100;
	$linelen = 0;

	# Validate project name.
	push(@err, [3, gettext("Invalid project name \"%s\""), $pname])
	    if ($pname !~ /^[A-Za-z][\w.-]*$/);
	push(@err, [9, gettext("Duplicate project name \"%s\""), $pname])
	    if (grep {$_->[0] eq $pname} @$projf);
	$linelen += length($pname) + 1;

	# Validate project id.
	if ($id !~ /^[+-]?\d+$/) {
		push(@err,
		    [3, gettext("Invalid projid \"%s\": must be numeric"), $id])
	} else {
		push(@err, [3, gettext("Invalid projid \"%d\": must be >= %d"),
		    $id, $low_projid])
		    if ($id < $low_projid);
		push(@err, [3, gettext("Invalid projid \"%.f\": must be <= %d"),
		    $id, &MAXPROJID])
		    if ($id > &MAXPROJID);
		push(@err, [4, gettext("Duplicate projid \"%d\""), $id])
		    if (! exists($flag->{dup}) && defined($projf) &&
		    grep { $_->[1] == $id } @$projf);
	}
	$linelen += length($id) + 1;

	# Validate comment.
	push(@err, [3, gettext("Invalid character \"%s\" in comment"), $1])
	    if ($comment =~ /([\n:])/);
	$linelen += length($comment) + 1;

	# Validate users.
	foreach my $u (@$user) {
		push(@err, [6, gettext("User \"%s\" does not exist"), $u])
		    if (! (($u =~ /^\d+$/ && defined(getpwuid($u))) ||
			   ($u =~ /^\*$/) || ($u =~ /^\!\*$/) ||
			   ($u =~ /^\!(\S+)$/ && defined(getpwnam($1))) ||
		    	   defined(getpwnam($u))));
		$linelen += length($u) + 1;
	}
	$linelen += 1 if (! @$user);

	# Validate groups.
	foreach my $g (@$group) {
		push(@err, [6, gettext("Group \"%s\" does not exist"), $g])
		    if (! (($g =~ /^\d+$/ && defined(getgrgid($g))) ||
			   ($g =~ /^\*$/) || ($g =~ /^\!\*$/) ||
			   ($g =~ /^\!(\S+)$/ && defined(getgrnam($1))) ||
			   defined(getgrnam($g))));
		$linelen += length($g) + 1;
	}
	$linelen += 1 if (! @$group);

	# Validate attribute string.
	push(@err, [3, gettext("Invalid attribute string \"%s\""), $attr])
	    if ($attr !~
	    /^$|^(?:[A-Za-z][\w.-]*=[^\s;]+)(?:;[A-Za-z][\w.-]*=[^\s;]+)*$/);
	$linelen += length($attr);

	# Validate line length.
	push(@err, [10, gettext("Project entry > %d bytes"), &PROJECT_BUFSZ])
	    if ($linelen > &PROJECT_BUFSZ);

	return (wantarray() ? @err : scalar(@err));
}

#
# Validate an entire project file as returned from projf_read.  Applies
# proj_validate to each entry, and returns a list of all the errors found
# in the same format as proj_validate, with a line number appended to each
# error message.
#
sub projf_validate($;$)
{
	my @projf = @{shift(@_)};	# Make a copy of the array.
	my $flag = shift(@_);
	my @err;
	my $line = 1;
	my $where = gettext(" at line %d");
	while (my $rec = shift(@projf)) {
		foreach my $e (proj_validate($rec, $flag, \@projf)) {
			$e->[1] .= $where;
			push(@$e, $line);
			push(@err, $e);
		}
		$line++;
	}
	return(wantarray() ? @err : scalar(@err));
}

1;
