#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents a Resource

package Slurm::Sacctmgr::Resource;
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

my @common_simple_accessors = qw(
	cluster
	count
	description
	name
	percentallowed
	server
	servertype
	type
);

my @common_readonly_accessors = qw(
	allocated
);

my @preTRES_accessors = qw(
);

my @postTRES_accessors = qw(
);

my @common_aref_accessors = qw(
	flags
);

my @common_accessors = (
	@common_simple_accessors,
	@common_aref_accessors,
);

my @rw_accessors = (
	@common_accessors,
	@preTRES_accessors,
	@postTRES_accessors,
);

my @ro_accessors = (
	@common_readonly_accessors
);

my @all_accessors = (
	@rw_accessors,
	@ro_accessors,
);

my @simple_accessors = (@common_simple_accessors);

__PACKAGE__->mk_accessors(@simple_accessors);
__PACKAGE__->mk_accessors(@common_readonly_accessors);

#------------	Special accessors

#Aref
__PACKAGE__->mk_arrayref_accessors(@common_aref_accessors);

#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @rw_accessors ];
}

sub _ro_fields($)
{	my $class = shift;
	return [ @ro_accessors ];
}

sub _sacctmgr_fields($$)
{	my $class = shift;
	return [ @all_accessors ];
}

sub _sacctmgr_name_field($)
{	my $class = shift;
	return 'name';
}

sub _my_sacctmgr_where_clause($)
#Overloaded to match on name/cluster, which should be enough to uniquely specify???
#Remember cluster may be undef
{	my $obj = shift;
	croak "Must be called as an instnace method at "
		unless $obj && ref($obj);

	my $name = $obj->name;
	my $cluster = $obj->cluster || '';

	my $where = {
		name => $name,
		cluster => $cluster,
	};
	return $where;
}

	
 
sub _sacctmgr_fields_in_order($$)
{	my $class = shift;
	my $sacctmgr = shift;
	my @fields = (@common_accessors, @common_readonly_accessors);
	if ( $sacctmgr->sacctmgr_cmd_supports('trackable_resources') )
	{	push @fields, @postTRES_accessors;
	} else
	{	push @fields, @preTRES_accessors;
	}
	return [ @fields ];
}

sub _sacctmgr_fields_addable($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @rw_accessors ];
}

sub _sacctmgr_fields_updatable($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @rw_accessors ];
}

#Overload _sacctmgr_list_cmd to include 'withcluster' flag
sub _sacctmgr_list_cmd($$)
{	my $class = shift;
	my $sacctmgr = shift;
	my $me = $class . '::_sacctmgr_list_cmd';

	die "$me: Missing sacctmgr param at " unless $sacctmgr && ref($sacctmgr);

	my $tmp = $class->SUPER::_sacctmgr_list_cmd($sacctmgr);
	return $tmp unless $tmp && ref($tmp) eq 'ARRAY';
	push @$tmp, 'withcluster';
	return $tmp;
}

#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

#All inherited

1;
__END__

=head1 NAME

Slurm::Sacctmgr::Resource

=head1 SYNOPSIS

  use Slurm::Sacctmgr::Resource;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::Resource->sacctmgr_list($sacctmgr);

  #List all resources known to sacctmgr
  foreach $rsc (@$list)
  {	#rsc is a Slurm::Sacctmgr::Resource object
	$desc = $rsc->description;
	$type = $rsc->type;
	$count= $rsc->count;
	print "$desc  ($type) : $count\n";
  }

  ...


=head1 DESCRIPTION

Represents a Resource entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to add, delete, list,
show, and modify sacctmgr entities of type "resource".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

This sacctmgr entity represents shared resources in Slurm, that is resources shared
across the entire cluster.   At the time of writing, this means licenses,
in particular those served from a remote license server.

Objects of this class contain the following data members:

=over 4

=item B<allocated>: percentage of resource allocated.  NOT updatable via sacctmgr.

=item B<cluster>: cluster name on which the resource is available.

=item B<count>: The number/amount of the resource configured
 
=item B<description> : Description of the Resource

=item B<flags> : Flags for the resource

=item B<servertype>: the type of server providing the resource.  E.g. flexlm, or rlm

=item B<name> : The name of the resource

=item B<percentallowed>: the percentage of the resource that can be used on specified cluster

=item B<server> : Name of the server serving up the resource, or 'slurmdb' for licenses served by slurm db.

=item B<type> : Type of resource.  Currently allowes 'License'.


=back

and these are the fields that will be set by the B<sacctmgr_list> and similar
methods.  When filtering results, you can use any fields recognized by the
B<sacctmgr> command, and when adding/modifying records you can provide any
fields recognized by the command.  The B<allocated> field cannot be set by sacctmgr.

Most functionality is provided via the base classes, 

=over 4

=item B<Slurm::Sacctmgr::EntityBaseRW>

=item B<Slurm::Sacctmgr::EntityBaseListable>

=item B<Slurm::Sacctmgr::EntityBaseModifiable>

=item B<Slurm::Sacctmgr::EntityBaseAddDel>

=item B<Slurm::Sacctmgr::EntityBase>

=back

As a result, the whole B<Slurm::Sacctmgr::*> family (for different entity types)
all have a very similar resource interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  

The remainder of this page briefly discusses the more commonly used methods
for this class, but the base classes above contain fuller documentation.
In all that follows, the variable B<$sacctmgr> is a required instance of 
B<Slurm::Sacctmgr>, and the invocant is not explicitly shown.

The following class instances are available: these will take either an instance
of B<Slurm::Sacctmgr::Resource> or the "Slurm::Sacctmgr::Resource" class name.

=over 4

=item B<sacctmgr_list($sacctmgr, %where)>

This will return a list reference of all objects of entity type "resource"
matching the "where" clause.  
The "where" clause is a list of zero or more key => value pairs 
specifying the conditions.  Only exact matching is supported, and keys cannot
be usefully repeated (the "where" clause is treated as a hash, so later keys
simply overwrite earlier keys).  You can use any parameter the Slurm
B<sacctmgr> command allows you to filter on.  If no 
key => value pairs are given, all entities of this type are returned.

=item B<new_from_sacctmgr_by_name($sacctmgr, $rscname)> 

This looks up in sacctmgr the resource entity with the specified rscname, 
and returns the corresponding B<Slurm::Sacctmgr::Resource> object.  
If no entity with specified rscname was found, returns undef.

=item B<sacctmgr_add($sacctmgr,%fields)> 

This method adds a new resource entity to sacctmgr's databases.  
The entity to add will be defined by the "%fields" list of key => value pairs; 
valid keys are any parameters sacctmgr allows you to set when adding resources.
In addition, the "pseudofield" B<--ok-if-previously-exists> can be 
given, and if true the method will not complain at attempts to add an entity
which already exists. 

=item B<sacctmgr_delete($sacctmgr, %where)> 

This method will delete one or more resource entities matching the "where" clause.  
The where clause behaves as discussed in B<sacctmgr_list>.

=item B<sacctmgr_modify($sacctmgr, $where, $update)> 

This will update the resource entities matching the "where" clause as indicated
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

