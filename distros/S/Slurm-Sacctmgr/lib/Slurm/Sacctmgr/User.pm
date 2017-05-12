#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents an User

package Slurm::Sacctmgr::User;
use strict;
use warnings;
use base qw(Slurm::Sacctmgr::EntityBaseRW);
use Carp qw(carp croak);

#-------------------------------------------------------------------
#	Globals
#-------------------------------------------------------------------

#-------------------------------------------------------------------
#	Accessors
#-------------------------------------------------------------------

#simple: just scalar, etc.  No custom accessor
#common: common to all versions of slurm
my @simple_common_accessors = qw(
	adminlevel
	defaultaccount
	user
);

my @aref_common_accessors = qw(
	coordinators
);

my @all_accessors = 
(	@simple_common_accessors,
	@aref_common_accessors,
);

my @simple_accessors = 
(	@simple_common_accessors,
);

my @aref_accessors = 
(	@aref_common_accessors,
);

my @common_accessors = 
(	@simple_common_accessors,
	@aref_common_accessors,
);

#coordinators is NOT modifiable 
#ie cannot change in sacctmgr modify user
my @modifiable_fields = 
(	@simple_common_accessors,
);

__PACKAGE__->mk_accessors(@simple_accessors);
__PACKAGE__->mk_arrayref_accessors(@aref_accessors);


#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @all_accessors ];
}

sub _sacctmgr_name_field($)
{	my $class = shift;
	return 'user';
}
 
sub _sacctmgr_fields($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @common_accessors ];
}

sub _sacctmgr_fields_addable($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @modifiable_fields ];
}

sub _sacctmgr_fields_updatable($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @modifiable_fields ];
}

sub _sacctmgr_fields_in_order($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @common_accessors ];
}

#Overload this to include 'withcoord' flag
sub _sacctmgr_list_cmd($$)
{	my $class = shift;
	my $sacctmgr = shift;
	my $me = $class . '::_sacctmgr_list_cmd';

	die "$me: Missing sacctmgr param at " unless $sacctmgr && ref($sacctmgr);

	my $tmp = $class->SUPER::_sacctmgr_list_cmd($sacctmgr);
	return $tmp unless $tmp && ref($tmp) eq 'ARRAY';
	push @$tmp, 'withcoord';
	return $tmp;
}


#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

#Overload default setting
sub _set_defaults($)
#Default adminlevel to None.  Set it to '' for Notset
{	my $obj = shift;

	my $val = $obj->adminlevel;
	unless ( defined $val )
	{	$obj->adminlevel('None');
	}

	return;
}
#All inherited

1;
__END__

=head1 NAME

Slurm::Sacctmgr::User

=head1 SYNOPSIS

  use Slurm::Sacctmgr::User;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::User->sacctmgr_list($sacctmgr);

  #List all users known to sacctmgr
  foreach $user (@$list)
  {	#user is a Slurm::Sacctmgr::User object
  	$uname = $user->user;
	$defacct = $user->defaultaccount;
	$adminlevel = $user->adminlevel;
	print "$uname ($defacct) [$adminlevel]\n";
  }

  #Get a single user 
  $uname = 'payerle';
  $user = Slurm::Sacctmgr::User->new_from_sacctmgr_by_name($sacctmgr,$uname);
  $defacct = $user->defaultaccount;
  print "Default account for user '$uname' is '$defacct'\n";

  ...


=head1 DESCRIPTION

Represents a User entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to add, delete, list,
show, and modify sacctmgr entities of type "user".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

Objects of this class contain the following data members:

=over 4

=item B<user>: the username of the user.

=item B<defaultaccount>: the default account/allocation for jobs submitted by yhis user.

=item B<adminlevel>: what if any administrative privileges the user has (in slurm).

=back

and these are the fields that will be set by the B<sacctmgr_list> and similar
methods.  When filtering results, you can use any fields recognized by the
B<sacctmgr> command, and when adding/modifying records you can provide any
fields recognized by the command.

Most functionality is provided via the base classes, 

=over 4

=item B<Slurm::Sacctmgr::EntityBaseRW>

=item B<Slurm::Sacctmgr::EntityBaseListable>

=item B<Slurm::Sacctmgr::EntityBaseModifiable>

=item B<Slurm::Sacctmgr::EntityBaseAddDel>

=item B<Slurm::Sacctmgr::EntityBase>

=back

As a result, the whole B<Slurm::Sacctmgr::*> family (for different entity types)
all have a very similar user interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  

The remainder of this page briefly discusses the more commonly used methods
for this class, but the base classes above contain fuller documentation.
In all that follows, the variable B<$sacctmgr> is a required instance of 
B<Slurm::Sacctmgr>, and the invocant is not explicitly shown.

The following class instances are available: these will take either an instance
of B<Slurm::Sacctmgr::User> or the "Slurm::Sacctmgr::User" class name.

=over 4

=item B<sacctmgr_list($sacctmgr, %where)>

This will return a list reference of all objects of entity type "user"
matching the "where" clause.  
The "where" clause is a list of zero or more key => value pairs 
specifying the conditions.  Only exact matching is supported, and keys cannot
be usefully repeated (the "where" clause is treated as a hash, so later keys
simply overwrite earlier keys).  You can use any parameter the Slurm
B<sacctmgr> command allows you to filter on.  If no 
key => value pairs are given, all entities of this type are returned.

=item B<new_from_sacctmgr_by_name($sacctmgr, $username)> 

This looks up in sacctmgr the user entity with the specified username, 
and returns the corresponding B<Slurm::Sacctmgr::User> object.  
If no entity with specified username was found, returns undef.

=item B<sacctmgr_add($sacctmgr,%fields)> 

This method adds a new user entity to sacctmgr's databases.  
The entity to add will be defined by the "%fields" list of key => value pairs; 
valid keys are any parameters sacctmgr allows you to set when adding users.
In addition, the "pseudofield" B<--ok-if-previously-exists> can be 
given, and if true the method will not complain at attempts to add an entity
which already exists. 

=item B<sacctmgr_delete($sacctmgr, %where)> 

This method will delete one or more user entities matching the "where" clause.  
The where clause behaves as discussed in B<sacctmgr_list>.

=item B<sacctmgr_modify($sacctmgr, $where, $update)> 

This will update the user entities matching the "where" clause as indicated
by the "update" clause.  Both $where and $update
are B<list references> of key => value pairs.  The where clause behaves as
in B<sacctmgr_list> (except that it is a B<array reference>, not a list), 
and similarly the update clause behaves as in B<sacctmgr_add>.

=back

=head2 EXPORT

Nothing.  Pure OO interface.

=head1 SEE ALSO

=over 4

=item B<Slurm::Sacctmgr::EntityBase>

=item B<Slurm::Sacctmgr::EntityBaseListable>

=item B<Slurm::Sacctmgr::EntityBaseAddDel>

=item B<Slurm::Sacctmgr::EntityBaseModifiable>

=item B<Slurm::Sacctmgr::EntityBaseRW>

=item B<sacctmgr> man page

=back

=head1 AUTHOR

Tom Payerle, payerle@umd.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by the University of Maryland.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

