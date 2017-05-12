#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents a Cluster

package Slurm::Sacctmgr::Cluster;
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

#Accessors common to all versions of slurm
my @common_accessors = qw(
	classification
	cluster
	controlhost
	controlport
	flags
	nodenames
	pluginidselect
	rpc
);

#Accessors in pre-TRES (< 15.x.y ) versions of slurm
my @preTRES_accessors = qw(
 	cpucount
	nodecount
);

#Accessors in post-TRES ( 15.x.y or higher ) versions of slurm
my @postTRES_accessors = qw(
	tres
);

my @all_accessors = ( 
	@common_accessors,
	@preTRES_accessors,
	@postTRES_accessors,
);

my @simple_accessors = ( @common_accessors );

__PACKAGE__->mk_accessors(@simple_accessors);

#Special accessors: handle TRES and non-TRES fields
__PACKAGE__->mk_tres_nontres_accessors('tres', 
		'cpucount' => 'cpu', 
		'nodecount' => 'node', 
);

#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @all_accessors ];
}

sub _sacctmgr_name_field($)
{	my $class = shift;
	return 'cluster';
}
 
sub _sacctmgr_fields($)
#All fields, all versions of slurm
{	my $class = shift;
	my $fields = [ @common_accessors,
			@preTRES_accessors,
			@postTRES_accessors,
		];
	return $fields;
}

sub _sacctmgr_fields_in_order($$)
{	my $class = shift;
	my $sacctmgr = shift;
	my @fields = @common_accessors;
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
	my @fields = @common_accessors;
	if ( $sacctmgr->sacctmgr_cmd_supports('trackable_resources') )
	{	push @fields, @postTRES_accessors;
	} else
	{	push @fields, @preTRES_accessors;
	}
	return [ @fields ];
}


sub _sacctmgr_fields_updatable($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return $class->_sacctmgr_fields_addable($sacctmgr);
}



#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

#All inherited

1;
__END__

=head1 NAME

Slurm::Sacctmgr::Cluster

=head1 SYNOPSIS

  use Slurm::Sacctmgr::Cluster;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::Cluster->sacctmgr_list($sacctmgr);

  #List all clusters known to sacctmgr
  foreach $cluster (@$list)
  {	#cluster is a Slurm::Sacctmgr::Cluster object
  	$nodes = $cluster->nodecount;
	$cpus = $cluster->cpucount;
	print "$name $nodes $cpus\n";
  }

  ...


=head1 DESCRIPTION

Represents a Cluster entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to add, delete, list,
show, and modify sacctmgr entities of type "cluster".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

Objects of this class contain the following data members:

=over 4

=item B<classification>: type of machine (capability or capacity)

=item B<cluster>: the name of the cluster

=item B<controlhost>: the host with the Slurm database

=item B<controlport>: the port to communicate with the Slurm database

=item B<cpucount>: the current count of CPUs on the cluster

=item B<flags>: flags for the cluster

=item B<nodecount>: the current count of Nodes on the cluster

=item B<nodenames>: the nodes (names) associatied with the cluster

=item B<pluginidselect>: the number value of the select plugin in use by the cluster

=item B<rpc>: the RPC version of the controller

=item B<tres>: the number of various Trackable Resources available in the cluster

=back

and these are the fields that will be set by the B<sacctmgr_list> and similar
methods.  When filtering results, you can use any fields recognized by the
B<sacctmgr> command, and when adding/modifying records you can provide any
fields recognized by the command.

The B<tres> accessor will return a hash ref keyed on the resource name, with
the value being the amount of the resource on the cluster.  For Slurm versions
which do not support trackable resources, this will return "cpu" and "node"
keys based on B<cpucount> and B<nodecount> fields; for Slurm versions with
TRES support, the B<cpucount> and B<nodecount> accessors will extract the
"cpu" and "node" keys from B<tres>.

Most functionality is provided via the base classes, 

=over 4

=item B<Slurm::Sacctmgr::EntityBaseRW>

=item B<Slurm::Sacctmgr::EntityBaseListable>

=item B<Slurm::Sacctmgr::EntityBaseModifiable>

=item B<Slurm::Sacctmgr::EntityBaseAddDel>

=item B<Slurm::Sacctmgr::EntityBase>

=back

As a result, the whole B<Slurm::Sacctmgr::*> family (for different entity types)
all have a very similar cluster interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  

The remainder of this page briefly discusses the more commonly used methods
for this class, but the base classes above contain fuller documentation.
In all that follows, the variable B<$sacctmgr> is a required instance of 
B<Slurm::Sacctmgr>, and the invocant is not explicitly shown.

The following class methods are available: these will take either an instance
of B<Slurm::Sacctmgr::Cluster> or the "Slurm::Sacctmgr::Cluster" class name.

=over 4

=item B<sacctmgr_list($sacctmgr, %where)>

This will return a list reference of all objects of entity type "cluster"
matching the "where" clause.  
The "where" clause is a list of zero or more key => value pairs 
specifying the conditions.  Only exact matching is supported, and keys cannot
be usefully repeated (the "where" clause is treated as a hash, so later keys
simply overwrite earlier keys).  You can use any parameter the Slurm
B<sacctmgr> command allows you to filter on.  If no 
key => value pairs are given, all entities of this type are returned.

=item B<new_from_sacctmgr_by_name($sacctmgr, $clustername)> 

This looks up in sacctmgr the cluster entity with the specified clustername, 
and returns the corresponding B<Slurm::Sacctmgr::Cluster> object.  
If no entity with specified clustername was found, returns undef.

=item B<sacctmgr_add($sacctmgr,%fields)> 

This method adds a new cluster entity to sacctmgr's databases.  
The entity to add will be defined by the "%fields" list of key => value pairs; 
valid keys are any parameters sacctmgr allows you to set when adding clusters.
In addition, the "pseudofield" B<--ok-if-previously-exists> can be 
given, and if true the method will not complain at attempts to add an entity
which already exists. 

=item B<sacctmgr_delete($sacctmgr, %where)> 

This method will delete one or more cluster entities matching the "where" clause.  
The where clause behaves as discussed in B<sacctmgr_list>.

=item B<sacctmgr_modify($sacctmgr, $where, $update)> 

This will update the cluster entities matching the "where" clause as indicated
by the "update" clause.  Both $where and $update
are B<list references> of key => value pairs.  The where clause behaves as
in B<sacctmgr_list> (except that it is a B<array reference>, not a list), 
and similarly the update clause behaves as in B<sacctmgr_add>.

=back

The following instance methods are available, which require an instance
of B<Slurm::Sacctmgr::Account> as the invocant.  With the exception
of B<sacctmgr_save_me>, they basically correspond to the class methods
above, except will take basic parameters from the invocant.

=over 4

=item B<sacctmgr_list_me($sacctmgr)>

This will look up in the Slurm database and return the corresponding
B<Slurm::Sacctmgr::Cluster> instance for the cluster in the Slurm
database with the same cluster name as the invocant.  I.e., it returns
what Slurm thinks the current Cluster object should be.

=item B<sacctmgr_add_me($sacctmgr,%extra_fields)>

This will add the to the Slurm database the cluster corresponding to
the invocant.  Any key => value pairs in extra fields will also be
supplied to the sacctmgr add command.

=item B<sacctmgr_delete_me($sacctmgr)>

This will delete from the Slurm database the cluster with the same
name as the invocant.

=item B<sacctmgr_modify_me($sacctmgr,%fields)>

This will invoke a sacctmgr modify command on the cluster matching
the name in the invocant, setting the fields in %fields.

=item B<sacctmgr_save_me($sacctmgr,%fields)>

This is sort of a combination of B<sacctmgr_list_me>, B<sacctmgr_add_me> and B<sacctmgr_modify_me>.
First, B<sacctmgr_list_me> is invoked to determine if the invocant
exists in the Slurm database, and if so what is stored there for it.
If it does not exist, it is B<sacctmgr_add_me>-ed, with the extra data
in %fields.  If it already exists in the Slurm databases, the values stored
there are compared to those of the invocant, and a B<sacctmgr_modify_me> command
will be invoked to bring the database in line with the invocant (as well as providing
the extra arguments from %fields).  If no extra %fields are given, and the invocant
is already in the Slurm database and no data members differ, no seconds sacctmgr
command is called.

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

