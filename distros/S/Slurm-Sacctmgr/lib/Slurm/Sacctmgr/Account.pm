#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents an Account

package Slurm::Sacctmgr::Account;
use strict;
use warnings;
use base qw(Slurm::Sacctmgr::EntityBaseRW);
use Carp qw(carp croak);
use POSIX qw(floor);

#-------------------------------------------------------------------
#	Globals
#-------------------------------------------------------------------

#-------------------------------------------------------------------
#	Accessors
#-------------------------------------------------------------------

my @simple_accessors = qw(
	account
	description
	organization
);

my @arrayref_accessors = qw(
	coordinators
);

my @rw_accessors = (@simple_accessors, @arrayref_accessors );

#The following fields can be set in sacctmgr add or update commands
#All but coordinators
my @modifiable_fields = @simple_accessors;

__PACKAGE__->mk_accessors(@simple_accessors);
__PACKAGE__->mk_arrayref_accessors(@arrayref_accessors);


#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @rw_accessors ];
}

sub _sacctmgr_name_field($)
{	my $class = shift;
	return 'account';
}
 
sub _sacctmgr_fields($$)
{	my $class = shift;
	my $sacctmgr = shift;
	return [ @rw_accessors ];
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
	return [ @rw_accessors ];
}

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

#All inherited

#-------------------------------------------------------------------
#	Special class methods
#-------------------------------------------------------------------

sub zero_usage_on_account_cluster($$$$;$)
#Given account name and cluster name, zero the usage
{	my $class = shift;
	my $sacctmgr = shift;
	my $account = shift;
	my $cluster = shift;
	my $quiet = shift;

        my $me = 'zero_usage_on_account_cluster';
        croak "No/invalid Slurm::Sacctmgr object passed to $me at "
                unless $sacctmgr && ref($sacctmgr);
	croak "No account name passed to $me at " unless $account;
	croak "No cluster name passed to $me at " unless $cluster;

	my $where = { 	name => $account, cluster=>$cluster };
	my $set = { rawusage => 0 };

	$class->sacctmgr_modify($sacctmgr, $where, $set, $quiet);
}

sub set_cpumin_limit_on_account_cluster($$$$$)
#DEPRECATED.  Use set_grptresmin_on_account_cluster instead
{	my $class = shift;
	my @args = @_;
	return $class->set_grptresmin_on_account_cluster(@args);
}

sub set_grptresmin_on_account_cluster($$$$$;$)
#Given account name and cluster name, and cpumin, set GrpCpuMins to $cpumin
#for that account/cluster.  Use -1 to unset???
{	my $class = shift;
	my $sacctmgr = shift;
	my $account = shift;
	my $cluster = shift;
	my $tresmin = shift;
	my $quiet = shift;
        my $me = __PACKAGE__ . '::set_grptresmin_on_account_cluster';

        croak "$me: No/invalid Slurm::Sacctmgr object given at "
                unless $sacctmgr && ref($sacctmgr);
	croak "$me: No account name given at " unless $account;
	croak "$me: No cluster name given at " unless $cluster;
	croak "$me: No tresmin given at " unless defined $tresmin;

	unless ( $tresmin && ref($tresmin) )
	{	croak "$me: undef $tresmin given at " unless defined $tresmin;
		#See if looks like TRES string or number
		if ( $tresmin =~ /=/ )
		{	#Looks like a tresmin string
			$tresmin = $class->_string2hashref($tresmin, $me);
		} else
		{ 	#Assume we were given cpumin for GrpCPUMins
			#We need to round cpumin to the nearest minute
			my $cpumin = floor($tresmin + 0.5);
			$tresmin = { cpu => $cpumin };
		}
	}

	unless ( %$tresmin )
	{	#Empty hash given, nothing to do, but warn
		carp "$me: Ignoring empty GrpTRESmin hash at ";
		return;
	}

	my $where = { 	name => $account, cluster=>$cluster };
	my $set;
	if ( $sacctmgr->sacctmgr_cmd_supports( 'trackable_resources' ) )
	{	#Our sacctmgr command supports trackable resources, use them
		$set = { grptresmins => $tresmin };
	} else
	{	#We do NOT support TRES
		my $tmp = { %$tresmin }; #Make a copy
		my $cpumin = delete $tmp->{cpu};
		if ( %$tmp )
		{	my @tmp = keys %$tmp;
			$tmp = join ", ", @tmp;
			carp "$me: TRES names [ $tmp ] provided to non-TRES capable sacctmgr, will be ignored, at "
				unless $quiet;
		}
		$set = { grpcpumins => $cpumin };
	}
		
	$class->sacctmgr_modify($sacctmgr, $where, $set, $quiet);
}


1;
__END__

=head1 NAME

Slurm::Sacctmgr::Account;

=head1 SYNOPSIS

  use Slurm::Sacctmgr::Account;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::Account->sacctmgr_list($sacctmgr);

  #List all accounts known to sacctmgr
  foreach $account (@$list)
  {	#account is a Slurm::Sacctmgr::Account object
  	$name = $account->account;
	$desc = $account->description;
	$org = $account->organization;
	print "$name ($org) [$desc]\n";
  }

  #Get a single account 
  $name = 'test-account';
  $account = Slurm::Sacctmgr::Account->new_from_sacctmgr_by_name($sacctmgr,$name);
  $desc = $account->description;
  print "Description for account '$name' is '$desc'\n";

  #Set cpumin limit and zero usage on an account
  $cluster='test-cluster';
  $cpumin = 4*1000*60; #4 kSU
  #Old, deprecated way
  Slurm::Sacctmgr::Account->set_cpumin_limit_on_account_cluster($sacctmgr,$name, $cluster, $cpumin);
  #New way 
  Slurm::Sacctmgr::Account->set_grptresmin_on_account_cluster($sacctmgr,$name, $cluster, { cpu => $cpumin} );
  Slurm::Sacctmgr::Account->zero_usage_on_account_cluster($sacctmgr,$name, $cluster);

  ...

=head1 DESCRIPTION

Represents a Account entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to add, delete, list,
show, and modify sacctmgr entities of type "account".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

Objects of this class contain the following data members:

=over 4

=item B<account>: the accountname of the account/allocation.

=item B<organization>: the organization the account/allocation belongs to.

=item B<description>: the description of the account/allocation.

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
all have a very similar account interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  


The remainder of this page briefly discusses the more commonly used methods
for this class, but the base classes above contain fuller documentation.
In all that follows, the variable B<$sacctmgr> is a required instance of 
B<Slurm::Sacctmgr>, and the invocant is not explicitly shown.

The following special class methods are defined in this class; the invocant
can be either the class name or an instance of this class.

=over 4

=item B<set_cpumin_limit_on_account_cluster($sacctmgr, $name, $cluster, $cpumin)>

This is B<DEPRECATED> in favor of B<set_grptresmin_on_account_cluster>.  It is
currently just an alias for the latter.

=item B<set_grptresmin_on_account_cluster($sacctmgr, $name, $cluster, $tresmin)>

This sets the B<GrpTresMin> limits on a specific account/cluster as specified in
$tresmin.  $tresmin should be a hash ref with TRES names as keys and the corresponding
limit as the value.  TRES names which are not listed will be unchanged; use a 
value of -1 to remove an existing limit.  $tresmin can also be a scalar TRES string,
e.g. "cpu=100000,mem=500", etc.  If $tresmin is a non-reference scalar that looks
like a number, it will be convertedto  the hash { cpu => $tresmin } to provide 
backwards compatibility with the old B<set_cpumin_limit_on_account_cluster> method.  

This method will automatically adapt the resulting sacctmgr command for the version
of Slurm being run; i.e. on versions of Slurm before TRES was implemented, 
only the cpu TRES will be considered and its value will be used to set B<GrpCPUMins>
(and any other TRES fields will result in a warning).

=item B<zero_usage_on_account_cluster($sacctmgr, $name, $cluster)> 

This will modify the sacctmgr record assocation with account B<$name> in cluster B<$cluster>,
setting B<RawUsage> to 0.

=back 

The following class methods are available: these will take either an instance
of B<Slurm::Sacctmgr::Account> or the "Slurm::Sacctmgr::Account" class name
as the invocant.

=over 4

=item B<sacctmgr_list($sacctmgr, %where)>

This will return a list reference of all objects of entity type "account"
matching the "where" clause.  
The "where" clause is a list of zero or more key => value pairs 
specifying the conditions.  Only exact matching is supported, and keys cannot
be usefully repeated (the "where" clause is treated as a hash, so later keys
simply overwrite earlier keys).  You can use any parameter the Slurm
B<sacctmgr> command allows you to filter on.  If no 
key => value pairs are given, all entities of this type are returned.

=item B<new_from_sacctmgr_by_name($sacctmgr, $accountname)> 

This looks up in sacctmgr the account entity with the specified accountname, 
and returns the corresponding B<Slurm::Sacctmgr::Account> object.  
If no entity with specified accountname was found, returns undef.

=item B<sacctmgr_add($sacctmgr,%fields)> 

This method adds a new account entity to sacctmgr's databases.  
The entity to add will be defined by the "%fields" list of key => value pairs; 
valid keys are any parameters sacctmgr allows you to set when adding accounts.
In addition, the "pseudofield" B<--ok-if-previously-exists> can be 
given, and if true the method will not complain at attempts to add an entity
which already exists. 

=item B<sacctmgr_delete($sacctmgr, %where)> 

This method will delete one or more account entities matching the "where" clause.  
The where clause behaves as discussed in B<sacctmgr_list>.

=item B<sacctmgr_modify($sacctmgr, $where, $update)> 

This will update the account entities matching the "where" clause as indicated
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
B<Slurm::Sacctmgr::Account> instance for the account in the Slurm
database with the same account name as the invocant.  I.e., it returns
what Slurm thinks the current Account object should be.

=item B<sacctmgr_add_me($sacctmgr,%extra_fields)>

This will add the to the Slurm database the account corresponding to
the invocant.  Any key => value pairs in extra fields will also be
supplied to the sacctmgr add command.

=item B<sacctmgr_delete_me($sacctmgr)>

This will delete from the Slurm database the account with the same
name as the invocant.

=item B<sacctmgr_modify_me($sacctmgr,%fields)>

This will invoke a sacctmgr modify command on the account matching
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

