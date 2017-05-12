package Set::Groups ;

#   ======================
# 
#           Jacquelin Charbonnel - CNRS/LAREMA
#  
#   $Id: Groups.pm 22 2007-11-06 20:58:14Z jaclin $
#   
#   ----
#  
#   A set of groups.
#   Each group can own single members and group members.
#   A group can be flattened, i.e. expansed until each of his members is a single one.
# 
#   ----
#   $LastChangedDate: 2007-11-06 21:58:14 +0100 (Tue, 06 Nov 2007) $ 
#   $LastChangedRevision: 22 $
#   $LastChangedBy: jaclin $
#   $URL: https://svn.math/system-tools/trunk/Set-Groups/Groups.pm $
#  
#   ======================

require Exporter ;
@ISA = qw(Exporter);
@EXPORT=qw() ;
@EXPORT_OK = qw( );

use 5.006;
use Carp;
use warnings;
use strict;

our $VERSION = 0.8 ; # $LastChangedRevision: 22 $
my $hfmt = "Set::Groups: HORROR: group '%s' is cyclic, the walk is infinite... Bye"  ;

sub new()
{ 
	my ($type) = @_ ;
	my $this = {
		"group" => {}
		, "debug" => 0
	} ;
  
	bless $this,$type ;
	return $this ;
}

sub setDebug($)
{
	my ($this,$level) = @_ ;
	$this->{"debug"} = $level ;
}

# -----------------
# Set management
# -----------------

sub newGroup($)
{
	my ($this,$group) = @_ ;

	if (exists $this->{"group"}{$group})
	{
		return 0 ;
	}
	else
	{
		$this->{"group"}{$group} = {} ;
		delete $this->{"partition"} if exists $this->{"partition"} ; 
		return 1 ;
	}
}

sub deleteGroup($)
{
	my ($this,$group) = @_ ;
	
	if (exists $this->{"group"}{$group})
	{
		delete $this->{"group"}{$group} ;
		delete $this->{"partition"} if exists $this->{"partition"} ;
		return 1 ;
	}
	else
	{
		return 0 ;
	}
}

sub getGroups()
{
	my ($this) = @_ ;
	return keys %{$this->{"group"}} ;
}

sub getCyclicGroups
{
	my($this) = @_ ;

	$this->_walk() unless exists $this->{"partition"} ;
	return keys(%{$this->{"partition"}{"cyclic"}}) ;
}

sub getAcyclicGroups
{
	my($this) = @_ ;

	$this->_walk() unless exists $this->{"partition"} ;
	return keys(%{$this->{"partition"}{"acyclic"}}) ;
}

sub hasGroup($)
{
	my($this,$group) = @_ ;
	return exists $this->{"group"}{$group} ;
}

# -----------------
# Group management
# -----------------

sub addSingleTo($$)
{
	my ($this,$single,$group) = @_ ;

	warn "Set::Groups: NOTICE: 'addSingleTo' is deprecated, use 'addOwnSingleTo' instead" if $this->{"debug"}>0 ;
	return $this->addOwnSingleTo($single,$group) ;
}

sub addOwnSingleTo($$)
{
	my ($this,$single,$group) = @_ ;

	return 0 if exists $this->{"group"}{$group}{"single"}{$single} ;
	$this->{"group"}{$group}{"single"}{$single} = 1 ;
	return 1 ;
}

sub addGroupTo($$)
{
	my ($this,$mgroup,$group) = @_ ;

	warn "Set::Groups: NOTICE: 'addGroupTo' is deprecated, use 'addOwnGroupTo' instead" if $this->{"debug"}>0 ;
	return $this->addOwnGroupTo($mgroup,$group) ;
}

sub addOwnGroupTo($$)
{
	my ($this,$mgroup,$group) = @_ ;

	return 0 if exists $this->{"group"}{$group}{"group"}{$mgroup} ;
	$this->{"group"}{$mgroup} = {} unless (exists $this->{"group"}{$mgroup}) ;
	$this->{"group"}{$group}{"group"}{$mgroup} = 2 ;
	delete $this->{"partition"} if exists $this->{"partition"} ;
	return 1 ;
}

sub removeSingleFrom($$)
{
	my ($this,$single,$group) = @_ ;

	warn "Set::Groups: NOTICE: 'removeSingleFrom' is deprecated, use 'removeOwnSingleFrom' instead" if $this->{"debug"}>0 ;
	return $this->removeOwnSingleFrom($single,$group) ;
}

sub removeOwnSingleFrom($$)
{
	my ($this,$single,$group) = @_ ;

	if ($this->isSingleOf($single,$group))
	{
		delete $this->{"group"}{$group}{"single"}{$single} ;
		return 1 ;
	}
	else { return 0 ; }
}

sub removeGroupFrom($$)
{
	my ($this,$sub,$group) = @_ ;

	warn "Set::Groups: NOTICE: 'removeGroupFrom' is deprecated, use 'removeOwnGroupFrom' instead" if $this->{"debug"}>0 ;
	return $this->removeOwnGroupFrom($sub,$group) ;
}

sub removeOwnGroupFrom($$)
{
	my ($this,$sub,$group) = @_ ;

	if ($this->isGroupOf($sub,$group))
	{
		delete $this->{"group"}{$group}{"group"}{$sub} ;
		delete $this->{"partition"} if exists $this->{"partition"} ;
		return 1 ;
	}
	else { return 0 ; }
}

# This function performs a total walk, if needeed
# At exit, the partition is always complete
sub isAcyclic
{
	my ($this,$group) = @_ ;

	$this->_walk() unless exists($this->{"partition"}) ;
	return exists($this->{"partition"}{"acyclic"}{$group}) ;
}  

sub isOwnSingleOf($$)
{
	my ($this,$candidate,$group) = @_ ;
	return exists $this->{"group"}{$group}{"single"}{$candidate} ;
}

sub isOwnGroupOf($$)
{
	my ($this,$candidate,$group) = @_ ;
	return exists $this->{"group"}{$group}{"group"}{$candidate} ;
}

sub isSingleOf($$)
{
	my ($this,$candidate,$group) = @_ ;

	carp sprintf($hfmt,$group) if $this->{"debug"}>0 && !$this->isAcyclic($group) ;
	my %fs = $this->_flattenedSinglesOf($group) ;
	return exists $fs{$candidate} ;
}  

sub isGroupOf($$)
{
	my ($this,$candidate,$group) = @_ ;

	carp sprintf($hfmt,$group) if $this->{"debug"}>0 && !$this->isAcyclic($group) ;
	my %fs = $this->_flattenedGroupsOf($group) ;
	return exists $fs{$candidate} ;
}  

sub getOwnSinglesOf($)
{
	my ($this,$group) = @_ ;
	return keys %{$this->{"group"}{$group}{"single"}} ;
}

sub getOwnGroupsOf($)
{
	my ($this,$group) = @_ ;
	return keys %{$this->{"group"}{$group}{"group"}} ;
}

sub getSinglesOf($)
{
	my ($this,$group) = @_ ;

	carp sprintf($hfmt,$group) if $this->{"debug"}>0 && !$this->isAcyclic($group) ;
	my %h = $this->_flattenedSinglesOf($group) ;
	return keys %h ;
}

sub getGroupsOf($)
{
	my ($this,$group) = @_ ;

	carp sprintf($hfmt,$group) if $this->{"debug"}>0 && !$this->isAcyclic($group) ;
	my %h = $this->_flattenedGroupsOf($group) ;
	return keys %h ;
}

# -----------------
# private methods
# -----------------

sub _flattenedSinglesOf()
{
	my ($this,$group) = @_ ;

	my %flat = () ;
	%flat = %{$this->{"group"}{$group}{"single"}} 
	  if exists $this->{"group"}{$group}{"single"} ;

	for my $k (keys %{$this->{"group"}{$group}{"group"}})
	{
		my %fs = $this->_flattenedSinglesOf($k) ;
		for my $kk (keys %fs)
		{
			$flat{$kk} = 1 ;
		}
	}
	return %flat ;
}  

sub _flattenedGroupsOf()
{
	my ($this,$group) = @_ ;

	my %flat = () ;
	for my $k (keys %{$this->{"group"}{$group}{"group"}})
	{
		$flat{$k} = 1 ;
		if (! exists $this->{"group"}{$k}{"group"} || scalar keys %{$this->{"group"}{$k}{"group"}}==0)
		{ 
		}
		else
		{
			my %fs = $this->_flattenedGroupsOf($k) ;
			for my $kk (keys %fs)
			{
				$flat{$kk} = 1 ;
			}
		}
	}
	return %flat ;
}  

# This function don't perform a total walk
# At exit, the partition is incomplete
sub _isAcyclic($$)
{
	my ($this,$group,$passed) = @_ ;

	if (exists $passed->{$group})
	{
		$this->{"partition"}{"cyclic"}{$group} = 1 ;
		return 0 ;
	}
	my %passed = ( %$passed, $group => 1 ) ;

	for my $k (keys %{$this->{"group"}{$group}{"group"}})
	{
		next if exists $this->{"partition"}{"acyclic"}{$k} ;
		if (exists $this->{"partition"}{"cyclic"}{$k})
		{
			$this->{"partition"}{"cyclic"}{$group} = 1 ;
			return 0 ;
		}
		if ($this->_isAcyclic($k,\%passed)==1)
		{
			$this->{"partition"}{"acyclic"}{$k} = 1 ;
		}
		else
		{
			$this->{"partition"}{"cyclic"}{$k} = 1 ;
			$this->{"partition"}{"cyclic"}{$group} = 1 ;
			return 0 ;
		}  
	}
	$this->{"partition"}{"acyclic"}{$group} = 1 ;
	return 1 ;
}  

# Perform an inconditionnal walk on the graph
sub _walk()
{
	my ($this) = @_ ;

	carp "Set::Groups: DEBUG: walking on the graph to find cycles..." if $this->{"debug"}>0 ;
	delete $this->{"partition"} if exists $this->{"partition"} ;
	for my $group ($this->getGroups())  
	{
		$this->_isAcyclic($group,{}) ;
	}
}  

1; 




=head1 NAME

Set::Groups - A set of groups.

=head1 SYNOPSIS

  use Set::Groups ;

  # create a set of groups
  $groups = new Set::Groups ;
  
  # create a group MyGroup with a single member
  $groups->addOwnSingleTo("single1","MyGroup") ;

  # add a group member into MyGroup
  $groups->addOwnGroupTo("Member1Group","MyGroup") ; 

  # add a single members into the previous member group
  $groups->addOwnSingleTo("single2","Member1Group") ;
  
  # add a group member into the previous member group
  $groups->addOwnGroupTo("Member2Group","Member1Group") ; 

  # add a single members into the previous member group
  $groups->addOwnSingleTo("single3","Member2Group") ;
  
  # flatten the group MyGroup
  @singles = $groups->getSinglesOf("MyGroup") ; 
  @groups = $groups->getGroupsOf("MyGroup") ; 
  $present = $groups->isSingleOf("single3","MyGroup") ; 
  $present = $groups->isGroupOf("Member2Group","MyGroup") ; 
  
=head1 DESCRIPTION

The Groups object implements a set of groups. 
Each group can own single members and group members.
A group can be flattened, i.e. expansed until each of his members is a single one.

=cut

=head1 CONSTRUCTORS

=head3 new

Create a new group set.

  my $groups = new Set::Groups

=head1 INSTANCE METHODS

=head3 setDebug

Set a debug level (0 or 1).

  $groups->setDebug(1) ;
  
=head2 Set management

=head3 newGroup

Create a new empty group and add it into the set. 
A group is everything which can be a key of a hash.
Returns 1 on success, 0 otherwise.
  
  $groups->newGroup("a_group") ;
  $groups->newGroup(1) ;

=head3 deleteGroup

Delete a group from the set. Return 1 on success, 0 otherwise.

  $groups->deleteGroup("a_group") ;
  
=head3 getGroups

Return the list of the groups present into the set.

  @groups = $groups->getGroups() ; 

=head3 getCyclicGroups

Return the list of the cyclic groups (i.e. self-contained) present into the set.

  @groups = $groups->getGroups() ; 

=head3 getAcyclicGroups

Return the list of the acyclic groups (i.e. not self-contained) present into the set.

  @groups = $groups->getGroups() ; 

=head3 hasGroup

Check if a group is present into the set.

  $present = $groups->hasGroup("a_group") ;

=head2 Groups management

=head3 addOwnSingleTo

Add a single member to a group. 
A single is everything which can be a key of a hash.
If the group doesn't exist in the set, it is created.
Return 1 on success, 0 otherwise.

  $groups->addOwnSingleTo("single","a_group") ;

=head3 addOwnGroupTo

Add a group member to a group. 
If the embedding group doesn't exist in the set, it is created.
If the member group doesn't exist in the set, it is created as an empty group.
Return 1 on success, 0 otherwise.

  $groups->addOwnGroupTo("group_member","a_group") ;
  
=head3 removeOwnSingleFrom

Remove an own single from a group. Return 1 on success, 0 otherwise.

  $groups->removeOwnSingleFrom("single","a_group") ;

=head3 removeOwnGroupFrom

Remove a group member from a group. Return 1 on success, 0 otherwise.

  $groups->removeOwnGroupFrom("a_member_group","a_group") ;

=head3 isAcyclic

Check if a group is acyclic.

  $is_acyclic = $groups->isAcyclic("a_group") ;
  
=head3 isOwnSingleOf

Check if a single is an own member of a group.

  $present = $groups->isOwnSingleOf("single","a_group") ;

=head3 isOwnGroupOf

Check if a group is an own member of a group.

  $present = $groups->isOwnGroupOf("a_group_member","a_group") ;

=head3 isSingleOf

Check if a single is a (own or not) member of a group.

  $present = $groups->isSingleOf("single","an_acyclic_group") ;

Warning - Calling this method with a cyclic group as argument gives a infinite recursion.

=head3 isGroupOf

Check if a group is a (own or not) member of a group.

  $present = $groups->isGroupOf("a_group_member","an_acyclic_group") ;

Warning - Calling this method with a cyclic group as argument gives a infinite recursion.

=head3 getOwnSinglesOf

Return the list of own singles of a group.

  @singles = $groups->getOwnSinglesOf("a_group") ;

=head3 getOwnGroupsOf

Return the list of own groups of a group.

  @groups = $groups->getOwnGroupsOf("a_group") ;

=head3 getSinglesOf

Return the list of (own or not) singles of an acyclic group.

  @singles = $groups->getSinglesOf("an_acyclic_group") ;

Warning - Calling this method with a cyclic group as argument gives a infinite recursion.

=head3 getGroupsOf

Return the list of (own or not) groups of an acyclic group.

  @groups = $groups->getGroupsOf("an_acyclic_group") ;

Warning - Calling this method with a cyclic group as argument gives a infinite recursion.

=head3 addGroupTo

Deprecated - Replaced by addOwnGroupTo.

=head3 addSingleTo

Deprecated - Replaced by addOwnSingleTo.

=head3 removeGroupFrom

Deprecated - Replaced by removeOwnGroupFrom.

=head3 removeSingleFrom

Deprecated - Replaced by removeOwnSingleFrom.

=head1 EXAMPLES

Suppose a group file like :

	admin:root,adm
	team:piotr,lioudmila,adam,annette,jacquelin
	true-users:james,sophie,@team,mohammed
	everybody:@admin,operator,@true-users
	daemon:apache,smmsp,named,daemon
	virtual:nobody,halt,@daemon
	all:@everybody,@virtual

where C<@name> means I<group name>, then the following code :

	use Set::Groups ;

	$groups = new Set::Groups ;
	while(<>)
	{
	  ($group,$members) = /^(\S+):(.*)$/ ;
	  @members = split(/,/,$members) ;
	  for $member (@members)
	  {
	    if ($member=~/^@/)
	    {
	      $member=~s/^@// ;
	      $groups->addOwnGroupTo($member,$group) ;
	    }
	    else
	    {
	      $groups->addOwnSingleTo($member,$group) ;
	    }
	  }
	}
	die "some groups are cyclic" if scalar($groups->getCyclicGroups())>0 ;
	print "singles: ",join(', ',$groups->getSinglesOf("all")),"\n" ;
	print "groups: ",join(', ',$groups->getGroupsOf("all")),"\n" ;

gives : 

	singles: apache, sophie, jacquelin, lioudmila, mohammed, smmsp, nobody, adm, annette, operator, james, named, adam, halt, root, daemon, piotr
	groups: admin, everybody, team, daemon, true-users, virtual

=cut
=head1 AUTHOR

Jacquelin Charbonnel, C<< <jacquelin.charbonnel at math.cnrs.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Set-Groups at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-Groups>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set-Groups

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Set-Groups>

=item * CPAN Ratings

L<http://cpanratings.perl.org/s/Set-Groups>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-Groups>

=item * Search CPAN

L<http://search.cpan.org/dist/Set-Groups>

=back

=head1 COPYRIGHT & LICENSE

Copyright Jacquelin Charbonnel E<lt> jacquelin.charbonnel at math.cnrs.fr E<gt>

This software is governed by the CeCILL-C license under French law and
abiding by the rules of distribution of free software.  You can  use, 
modify and/ or redistribute the software under the terms of the CeCILL-C
license as circulated by CEA, CNRS and INRIA at the following URL
"http://www.cecill.info". 

As a counterpart to the access to the source code and  rights to copy,
modify and redistribute granted by the license, users are provided only
with a limited warranty  and the software's author,  the holder of the
economic rights,  and the successive licensors  have only  limited
liability. 

In this respect, the user's attention is drawn to the risks associated
with loading,  using,  modifying and/or developing or reproducing the
software by the user in light of its specific status of free software,
that may mean  that it is complicated to manipulate,  and  that  also
therefore means  that it is reserved for developers  and  experienced
professionals having in-depth computer knowledge. Users are therefore
encouraged to load and test the software's suitability as regards their
requirements in conditions enabling the security of their systems and/or 
data to be ensured and,  more generally, to use and operate it in the 
same conditions as regards security. 

The fact that you are presently reading this means that you have had
knowledge of the CeCILL-C license and that you accept its terms.

