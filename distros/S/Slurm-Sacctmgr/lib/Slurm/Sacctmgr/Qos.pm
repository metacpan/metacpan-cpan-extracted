#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents a Qos

package Slurm::Sacctmgr::Qos;
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
	description
	gracetime
	grpjobs
	grpsubmitjobs
	grpwall
	id
	maxjobs
	maxsubmitjobs
	maxwall
	name
	preempt
	preemptmode
	priority
	usagefactor
	usagethreshold
);

my @preTRES_accessors = qw(
	grpcpumins
	grpcpus
	grpnodes
	maxcpumins
	maxcpus
	maxcpusperuser
	maxnodes
	maxnodesperuser
	mincpus

);

my @postTRES_accessors = qw(
	grptresmins
	grptresrunmins
	grptres
	maxtresmins
	maxtresperjob
	maxtrespernode
	maxtresperuser
	mintresperjob
);

my @common_aref_accessors = qw(
	flags
);

my @common_accessors = (
	@common_simple_accessors,
	@common_aref_accessors,
);

my @all_accessors = (
	@common_accessors,
	@preTRES_accessors,
	@postTRES_accessors,
);

my @simple_accessors = (@common_simple_accessors);

__PACKAGE__->mk_accessors(@simple_accessors);

#------------	Special accessors

#Aref
__PACKAGE__->mk_arrayref_accessors(@common_aref_accessors);

#TRES/nonTRES variants
__PACKAGE__->mk_tres_nontres_accessors('grptres', 'grpcpus' => 'cpu', 'grpnodes' => 'node' );
__PACKAGE__->mk_tres_nontres_accessors('grptresmins', 'grpcpumins' => 'cpu', );
__PACKAGE__->mk_tres_nontres_accessors('maxtresmins', 'maxcpumins' => 'cpu', );
#maxcpus/maxnodes are actually per job
__PACKAGE__->mk_tres_nontres_accessors('maxtresperjob', 'maxcpus' => 'cpu', 'maxnodes' => 'node' );
__PACKAGE__->mk_tres_nontres_accessors('maxtresperuser', 
	'maxcpusperuser' => 'cpu', 'maxnodesperuser' => 'node' );
#mincpus is actually per job
__PACKAGE__->mk_tres_nontres_accessors('mintresperjob', 'mincpus' => 'cpu', );
#These do not have preTRES counterparts ???
__PACKAGE__->mk_tres_nontres_accessors('grptresrunmins');
__PACKAGE__->mk_tres_nontres_accessors('maxtrespernode');

#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @all_accessors ];
}

sub _sacctmgr_fields($$)
{	my $class = shift;
	return [ @all_accessors ];
}

sub _sacctmgr_name_field($)
{	my $class = shift;
	return 'name';
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
	return $class->_sacctmgr_fields_in_order($sacctmgr);
}

sub _sacctmgr_fields_updatable($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return $class->_sacctmgr_fields_in_order($sacctmgr);
}

#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

#All inherited

1;
__END__

=head1 NAME

Slurm::Sacctmgr::Qos

=head1 SYNOPSIS

  use Slurm::Sacctmgr::Qos;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::Qos->sacctmgr_list($sacctmgr);

  #List all qoses known to sacctmgr
  foreach $qos (@$list)
  {	#qos is a Slurm::Sacctmgr::Qos object
  	$name = $qos->name;
	$desc = $qos->description;
	$priority = $qos->priority;
	print "$name ($desc) [$priority]\n";
  }

  #Get a single qos 
  $name = 'high';
  $qos = Slurm::Sacctmgr::Qos->new_from_sacctmgr_by_name($sacctmgr,$uname);
  $priority = $qos->priority;
  print "Priority for qos '$name' is '$priority'\n";

  ...


=head1 DESCRIPTION

Represents a Qos entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to add, delete, list,
show, and modify sacctmgr entities of type "qos".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

Objects of this class contain the following data members:

=over 4

=item B<description> : Description of the QoS

=item B<gracetime> : Preemption gracetime

=item B<grpcpumins> : Total number of CPU minutes available to jobs in the QoS

=item B<grpcpus> : Maximum number of CPUs for jobs running under this QoS

=item B<grpjobs> : Maximum number of jobs that can run under this QoS at a time.

=item B<grpnodes> : Maximum number of nodes that can be running jobs under this QoS

=item B<grpsubmitjobs> : Maximum number of jobs (pending and running) for this QoS at one time

=item B<grpwall> : Maximum wall clock time for jobs in this QoS

=item B<maxcpumins> :  Maximum wall clock time each job in this QoS can use

=item B<maxcpus> : Maximum number of CPUs each job in this QoS can use

=item B<maxcpusperuser> : Maximum number of CPUS each user in this QoS can use

=item B<maxjobs> :Maximum number of jobs each user in this QoS can run at one time

=item B<maxnodes> :Maximum number of nodes each job in this QoS can use

=item B<maxnodesperuser> :Maximum number of nodes each user in this QoS can use

=item B<maxsubmitjobs> :Maximum number of jobs (pending or running) per user in this QoS

=item B<maxwall> :Maximum wall clock time each job in this QoS can use

=item B<name> : Name of the QoS

=item B<preempt> : QoSes which this Qos can preempt

=item B<preemptmode> : mechanism used for preempting jobs

=item B<priority> : priority number for jobs in this QoS

=item B<usagefactor> : usage factor when running with this QoS

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
all have a very similar qos interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  

The remainder of this page briefly discusses the more commonly used methods
for this class, but the base classes above contain fuller documentation.
In all that follows, the variable B<$sacctmgr> is a required instance of 
B<Slurm::Sacctmgr>, and the invocant is not explicitly shown.

The following class instances are available: these will take either an instance
of B<Slurm::Sacctmgr::Qos> or the "Slurm::Sacctmgr::Qos" class name.

=over 4

=item B<sacctmgr_list($sacctmgr, %where)>

This will return a list reference of all objects of entity type "qos"
matching the "where" clause.  
The "where" clause is a list of zero or more key => value pairs 
specifying the conditions.  Only exact matching is supported, and keys cannot
be usefully repeated (the "where" clause is treated as a hash, so later keys
simply overwrite earlier keys).  You can use any parameter the Slurm
B<sacctmgr> command allows you to filter on.  If no 
key => value pairs are given, all entities of this type are returned.

=item B<new_from_sacctmgr_by_name($sacctmgr, $qosname)> 

This looks up in sacctmgr the qos entity with the specified qosname, 
and returns the corresponding B<Slurm::Sacctmgr::Qos> object.  
If no entity with specified qosname was found, returns undef.

=item B<sacctmgr_add($sacctmgr,%fields)> 

This method adds a new qos entity to sacctmgr's databases.  
The entity to add will be defined by the "%fields" list of key => value pairs; 
valid keys are any parameters sacctmgr allows you to set when adding qoses.
In addition, the "pseudofield" B<--ok-if-previously-exists> can be 
given, and if true the method will not complain at attempts to add an entity
which already exists. 

=item B<sacctmgr_delete($sacctmgr, %where)> 

This method will delete one or more qos entities matching the "where" clause.  
The where clause behaves as discussed in B<sacctmgr_list>.

=item B<sacctmgr_modify($sacctmgr, $where, $update)> 

This will update the qos entities matching the "where" clause as indicated
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

