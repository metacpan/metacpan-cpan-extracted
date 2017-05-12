#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents an Event

package Slurm::Sacctmgr::Event;
use strict;
use warnings;
use base qw(Slurm::Sacctmgr::EntityBaseListable);
use Carp qw(carp croak);

#-------------------------------------------------------------------
#	Globals
#-------------------------------------------------------------------

#-------------------------------------------------------------------
#	Accessors
#-------------------------------------------------------------------

#Fields common to all slurm versions
my @common_accessors = qw(
	cluster
	clusternodes
	duration
	end
	event
	eventraw
	nodename
	reason
	start
	state
	stateraw
	user
);

#Fields from pre-TRES Slurms
my @preTRES_accessors = qw(
	cpus
);

#Fields from post-TRES Slurms
my @postTRES_accessors = qw(
	tres
);

my @all_accessors = (
	@common_accessors,
	@preTRES_accessors,
	@postTRES_accessors,
);

my @simple_accessors = @common_accessors;

__PACKAGE__->mk_accessors(@simple_accessors);

#Handle the TRES/nonTRES variants
__PACKAGE__->mk_tres_nontres_accessors('tres', 'cpus' => 'cpu' );


#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @all_accessors ];
}

#Do NOT overload this, should never get used
#Events cannot be identified by a singlle field
#sub _sacctmgr_name_field($)
#{	my $class = shift;
#	die "This needs work";
#	return 'event';
#}
 
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

sub _my_sacctmgr_where_clause($)
#Overload to match on enough fields to make the event unique
#Not like this will get used, but for completeness (and regression tests)
{	my $obj = shift;
	croak "Must be called as an instance method at "
		unless $obj && ref($obj);

	#Is this enough to uniquely identify an event?
	my @fields = qw(cluster clusternodes end event nodename start state user);
	my ($fld, $val, $meth);
	my $where = {};
	foreach $fld (@fields)
	{	$meth = $fld;
		$val = $obj->$meth;
		$val = '' unless defined $val;
		$where->{$fld} = $val;
	}
	return $where;
}



#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

#All inherited

1;
__END__

=head1 NAME

Slurm::Sacctmgr::Event

=head1 SYNOPSIS

  use Slurm::Sacctmgr::Event;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::Event->sacctmgr_list($sacctmgr);

  #List all events known to sacctmgr
  foreach $event (@$list)
  {	#event is a Slurm::Sacctmgr::Event object
  	$uname = $event->event;
	$defacct = $event->defaultaccount;
	$adminlevel = $event->adminlevel;
	print "$uname ($defacct) [$adminlevel]\n";
  }

  #Get a single event 
  $uname = 'payerle';
  $event = Slurm::Sacctmgr::Event->new_from_sacctmgr_by_name($sacctmgr,$uname);
  $defacct = $event->defaultaccount;
  print "Default account for event '$uname' is '$defacct'\n";

  ...


=head1 DESCRIPTION

Represents a Event entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to list or
show sacctmgr entities of type "event".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

Objects of this class contain the following data members:

=over 4

=item B<cluster> : the name of the cluster the event happened on

=item B<clusternodes> : the hostlist for a cluster event

=item B<cpus> : the number of CPUs involved in the event

=item B<duration> : the duration of the event

=item B<end> : when the event ended

=item B<event> : the name of the event

=item B<eventraw> : numeric id of the event

=item B<nodename> : the node affected by the event

=item B<reason> : why the event happened

=item B<start> : when the event started

=item B<state> : the state of the node during a node event

=item B<stateraw> : the numeric value associated with B<state>

=item B<user> : the user causing a node event to occur

=back

and these are the fields that will be set by the B<sacctmgr_list> and similar
methods.  When filtering results, you can use any fields recognized by the
B<sacctmgr> command.

Most functionality is provided via the base classes, 

=over 4

=item B<Slurm::Sacctmgr::EntityBaseListable>

=item B<Slurm::Sacctmgr::EntityBase>

=back

As a result, the whole B<Slurm::Sacctmgr::*> family (for different entity types)
all have a very similar event interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  

Since Slurm's sacctmgr command only lets you list events, the only real
method provided is B<sacctmgr_list($sacctmgr, %where)>.
This will return a list reference of all objects of entity type "event"
matching the "where" clause.  
The "where" clause is a list of zero or more key => value pairs 
specifying the conditions.  Only exact matching is supported, and keys cannot
be usefully repeated (the "where" clause is treated as a hash, so later keys
simply overwrite earlier keys).  You can use any parameter the Slurm
B<sacctmgr> command allows you to filter on.  If no 
key => value pairs are given, all entities of this type are returned.

=head2 EXPORT

Nothing.  Pure OO interface.

=head1 SEE ALSO

=over 4

=item B<Slurm::Sacctmgr::EntityBase>

=item B<Slurm::Sacctmgr::EntityBaseListable>

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

