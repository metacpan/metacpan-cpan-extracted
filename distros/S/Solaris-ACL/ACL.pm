package Solaris::ACL;

# $Id: ACL.pm,v 1.14 2000/04/07 22:47:19 ian Exp $

# Change Log:
# $Log: ACL.pm,v $
# Revision 1.14  2000/04/07 22:47:19  ian
# Version change to 0.06
#
# Calls to mask, groups(gid) and users(uid) now return -1 if the
# requested entry does not exist.
#
# Internal structure documentation moved to the end, with a warning as
# to its transitory nature.
#
# Fixed error in documentation of how to copy an ACL, which swapped
# target and source.
#
# Revision 1.13  2000/03/02 20:12:23  ian
# Version 0.05 release
#
# Internally documented _report_or_set_or_delete and _generic_list
# Now deletes the users and/or groups hashes if they become empty.
#
# Make clean code improved
#
# Revision 1.12  2000/02/18 22:06:09  ian
# Whoops - we were already at 0.03 - going to 0.04
#
# Revision 1.11  2000/02/13 21:31:53  ian
# Fixed typo in test.pl
# The version 0.03 release
# Using cvs2cl to create ChangeLog (though these comments only show up in
# next commit...)
#
# Revision 1.10  2000/02/13 00:35:37  ian
# Made private functions _report_or_set_or_delete and _generic_list into
# preloaded functions (moved them before the __END__ token)
#
# Revision 1.9  2000/02/10 20:14:11  ian
# Tagged as release 0.02.  Updated version in ACL.pm
#
# Revision 1.8  2000/02/07 01:26:54  iroberts
# * Added Id and Log strings to all files
# * Now EXPORTs instead of EXPORT_OKing setfacl and getfacl
# * make clean now removes test-acl-file and test-acl-dir
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw(getfacl setfacl);
$VERSION = '0.06';

bootstrap Solaris::ACL $VERSION;

# Preloaded methods go here.

# _report_or_set_or_delete($hash, $ref [, $val])

# report_or_set_or_delete either reports the value of $hash->{$ref},
# or, if $val is set, sets $hash->{$ref} to $val.  If $val is -1, the
# it instead deletes $hash->{$ref}.  If $hash->{$ref} does not exist,
# then -1 is returned.

sub _report_or_set_or_delete
{
    my($hash, $ref, $val) = @_;
    if(defined($val))
    {
	if($val == -1)
	{
	    delete $hash->{$ref};
	}
	else
	{
	    $hash->{$ref} = $val;
	}
    }
    else
    {
	defined($hash->{$ref}) ? $hash->{$ref} : -1;
    }
}

# _generic_list($list, $acl, [, $uid [, $perm]])

# _generic_list is a helper function for users and groups which
# interfaces with _report_or_set_or_delete to manage the users and
# groups hashes.  If _report_or_set_or_delete is called, then it may
# have deleted the last key of a hash, in which case _generic_list
# will delete the hash.  If this is a read request, and there is no
# perm listed for the given uid, -1 is returned.

sub _generic_list
{
    my($list,$acl,$uid,$perm) = @_;
    if(defined($uid))
    {
	# because if we do delete a key, we might need to also delete
	# $acl->{$list}, we only call _report_or_set_or_delete in the
	# event that $perm is set; otherwise, we just do the lookup
	# directly, rather than save the return val of
	# _report_or_set_or_delete in a temporary variable to return
	# later.

	if(defined($perm))
	{
	    $acl->{$list} = {} unless(defined($acl->{$list}));
	    _report_or_set_or_delete($acl->{$list},$uid,$perm);
	    # Did we delete the last user/group?
	    if(defined $acl->{$list} && ! keys(%{$acl->{$list}}))
	    {
		delete $acl->{$list};
	    }
	}
	else
	{
	    (defined($acl->{$list}) && $acl->{$list}->{$uid}) ?
		$acl->{$list}->{$uid} : -1;
	}
    }
    else
    {
	keys(%{$acl->{$list}});
   }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Solaris::ACL - Perl extension for reading and setting Solaris Access Control Lists for files

=head1 SYNOPSIS

  use Solaris::ACL;
  ($acl, $default_acl) = getfacl("path/to/file");
  setfacl("path/to/file", $acl [, $default_acl]);


=head1 DESCRIPTION

This module provides access to the system level C<acl>(2) call,
allowing efficient setting and reading of Access Control Lists (ACLs)
in perl.

ACL provides the following functions:

=over

=item setfacl(C<$path>, C<$acl> [, C<$default_acl>])

Set the ACL of the file or directory named by C<$path> to that
specified by C<$acl>.  If C<$path> names a directory, then the optional
C<$default_acl> argument can also be passed to specify the default ACL
for the directory.  See L<"ACL structure"> for information on how the
C<$acl> and C<$default_acl> hashes should be constructed.

=item getfacl(C<$file_name>)

Return a reference to a hash containing information about the file's
ACL.  If the file is a directory with a default ACL, then a list is
returned, with the first entry being a hash reference to the ACL, and
the second being a hash reference to the default ACL.  See L<"Accessing
ACL structures"> for information on how to access these hashes, and
L<"ACL structure"> for information on how these hashes are internally
constructed.

=back

=head2 Accessing ACL structures

The structures returned by the getfacl call are blessed into the
Solaris::ACL package, and can be inspected and changed using methods
from that class.  In most cases, the same method can be used for
inspecting or setting values; a value is set if data is given to set
it with; otherwise, it is inspected and returned.  The following
accessor methods are defined:

=over

=item uperm

=item gperm

=item operm

=item mask

Without an argument, each of these methods returns the permission for
the corresponding entity (user, group, other, or file mask).  With an
argument, they set the permission to that argument.  For example:

  $user_perm = $acl->uperm;  # find out current owner permissions.
  $acl->operm(5);            # give others read-execute permissions.

If no mask is set in the ACL, C<mask> returns -1.

=item users

=item groups

Without arguments, return a list of users (by uid) or groups (by gid)
with special ACL access.  When passed a uid/gid as an argument, return
the permission for the given user/group, or -1 if no permission is
set in the ACL.  When passed a uid/gid and a permission, give the specified
user/group the indicated permission; if the permission is -1, remove
any permissions for the specified user/group.

=item calc_mask

Calculate the mask for the acl, as would the C<-r> flag of setfacl.

=item equal(C<$acl2>)

Check to see if the acl is equal to C<$acl2>.  Returns 1 if equal, 0
otherwise.

=item Solaris::ACL->new(C<$mode>)

Create a new blessed acl with permissions for user, group and other
determined by mode.

=back

=head1 EXAMPLES

  $acl = new Solaris::ACL(0741);
  $acl->users(scalar(getpwnam("iroberts"),2);
  $acl->users(scalar(getpwnam("rdb"),0);
  $acl->calc_mask;

  $def_acl = new Solaris::ACL(0751);

  setfacl("working_dir", $acl, $def_acl);

  ($acl1, $def_acl1) = getfacl("working_dir");

  print "All is well\n" if($acl->equal($acl1));

  $acl2 = getfacl("working_file");
  print "uids with acls set: ", join(", ", $acl2->users), "\n";
  print "uid 29 had permission ", $acl2->users(29), "\n";
  $acl2->users(29,6);
  $acl2->calc_mask;
  setfacl("working_file", $acl2)
  print "uid 29 now has permission 6\n";

  # to copy an acl from one file or directory to another;
  setfacl($target_file, getfacl($source_file));

=head1 RETURN VALUES

C<setfacl> returns TRUE if successful and FALSE if unsuccessful.
C<getfacl>, if successful, returns a list containing a reference to
the hash describing an acl, and, if there is a default acl, a
reference to the hash describing the default acl.  If unsuccessful,
C<getfacl> returns a null list.  If either C<setfacl> or C<getfacl>
are unsuccessful, the variable C<$Solaris::ACL::error> is set to a
descriptive error string; in addition, if the failure was due to a
system error, C<$!> is set.

=head2 ACL structure

WARNING: The internal structures described here are subject to change in future
versions.

All information passed to C<setfacl> returned from C<getfacl> is in
the form of references to hashes.  A hash describing an ACL can have
the following keys:

=over

=item uperm, gperm, operm, mask

Each of these keys have values containing permissions for the
corresponding entity (user, group, other, mask).

=item groups, users

Each of these keys (if existent) contain a reference to a hash whose
keys are decimal representations of numbers, and whose values contain
permissions for the user/group whose uid/gid is the number in the key.

=back

=head1 BUGS

No checking is done on data types; bad data will result in strange
error message being placed in C<$Solaris::ACL::errors>.

=head1 AUTHOR

Ian Robertson <ian@lugh.uchicago.edu>

=head1 SEE ALSO

perl(1), getfacl(1), setfacl(1), acl(2)

=cut

sub mask
{
    my($acl,$mask) = @_;
    _report_or_set_or_delete($acl,'mask',$mask);
}

sub uperm
{
    my($acl) = shift;
    @_  ? $acl->{'uperm'} = shift
	: $acl->{'uperm'};
}

sub gperm
{
    my($acl) = shift;
    @_  ? $acl->{'gperm'} = shift
	: $acl->{'gperm'};
}

sub operm
{
    my($acl) = shift;
    @_  ? $acl->{'operm'} = shift
	: $acl->{'operm'};
}

sub mode
{
    my($acl) = shift;
    if(@_)
    {
	my $mode = shift;
	$acl->operm($mode & 07);
	$acl->gperm(($mode & 070) >>3);
	$acl->uperm(($mode & 0700) >>6);
	return $mode;
    }
    else
    {
	return $acl->operm + $acl->gperm << 3 + $acl->uperm << 6;
    }
}

# calc_mask calculates the mask for an acl, as would the -r flag of
# setfacl.

sub calc_mask
{
    my($acl) = $_[0];
    my($uid, $type);
    $acl->{'mask'} = $acl->{'gperm'};
    foreach $type ('users', 'groups')
    {
	if(defined $acl->{$type})
	{
  	    foreach $uid (keys(%{$acl->{$type}}))
  	    {
  		$acl->{'mask'} |= $acl->{$type}->{$uid};
  	    }
	}
	return $acl->{'mask'};
    }
}

sub users
{
    _generic_list('users',@_);
}

sub groups
{
    _generic_list('groups',@_);
}

# new(mode)

# new returns an acl with user, group and other fields set according
# to mode

sub new
{
    my $pkg = shift;
    my $self = {};
    bless $self, $pkg;
    my ($key, $type);
    if(ref($_[0]))		# passed an acl; clone it
    {
	my($acl) = shift;
	for $key ('uperm', 'gperm', 'operm', 'mask')
	{
	    $self->{$key} = $acl->{$key} if (defined $acl->{$key});
	} 
	foreach $type ('users', 'groups')
	{
	    if(defined $acl->{$type})
	    {
		foreach $key (keys(%{$acl->{$type}}))
		{
		    $self->{$type}->{$key} = $acl->{$type}->{$key};
		}
	    }
	}
    }
    else			# construct a new acl
    {
	my $mode = shift;
	$self->mode($mode);
    }
    return $self
}

# equal(acl1, acl2) (or $acl1->compare($acl2)

# equal reports whether or not two acls are equal, returning 0 if
# different, 1 if the same.

sub equal
{
    my $self = shift;
    my $acl = shift;
    my ($key, $type);
    for $key ('uperm', 'gperm', 'operm')
    {
	return 0 if ($self->{$key} != $acl->{$key});
    }
    if(defined $self->{'mask'})
    {
	return 0 unless (defined $acl->{'mask'} &&
			 $self->{'mask'} == $acl->{'mask'});
    }
    else
    {
	return 0 if defined $acl->{'mask'};
    }
 
    foreach $type ('users', 'groups')
    {
	if(defined $self->{$type})
	{
	    return 0 unless defined $acl->{$type};

	    # This may not be optimally efficient: we need to check
	    # equality in both directions.  Rather than take a union
	    # of the list of keys, we will just loop over both lists.

	    foreach $key (keys(%{$self->{$type}}), keys(%{$acl->{$type}}))
	    {
		return 0 if ($self->{$type}->{$key} != $acl->{$type}->{$key});
	    }
	}
	else
	{
	    return 0 if defined $acl->{$type};
	}
    }
    # made it this far, so they must be equal!
    return 1;
}
