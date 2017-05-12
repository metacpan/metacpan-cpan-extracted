#!/usr/local/bin/perl
#
#Base class for sacctmgr entities which can be "list"ed

package Slurm::Sacctmgr::EntityBaseListable;
use strict;
use warnings;
use base qw(Slurm::Sacctmgr::EntityBase);
use Carp qw(carp croak);

#This is intended for regression tests only
my $_last_raw_output;
sub _eblist_last_raw_output($)
{       return $_last_raw_output;
}
sub _clear_eblist_last_raw_output($)
{       $_last_raw_output = [];
}


#2016-03-09: dropping this.
#Accessors/mutators for non-string types should convert strings as needed
# #-------------------------------------------------------------------
# #	Data conversion routines
# #-------------------------------------------------------------------
# 
# sub _data_converter_csv($)
# #Takes a csv and returns a list ref
# {	my $csv = shift;
# 	return unless $csv;
# 
# 	my @data = split /\s*,\s*/, $csv;
# 	return [ @data ];
# }
# 
# my %DATA_TYPES =
# (	csv => \&_data_converter_csv,
# );

#-------------------------------------------------------------------
#	List command
#-------------------------------------------------------------------

sub _sacctmgr_list_cmd($$)
{	my $class = shift;
	my $sacctmgr = shift;
	$class = ref($class) if ref($class);
	my $me = $class . '::_sacctmgr_list_cmd';

	die "$me: Missing sacctmgr param at " unless $sacctmgr && ref($sacctmgr);

	my $base = $class->_sacctmgr_entity_name;
	my $fields = $class->_sacctmgr_fields_in_order($sacctmgr);
	my $fmtstr = join ",", @$fields;
	return [ 'list', $base, "format=$fmtstr" ];
}

sub new_from_sacctmgr_list_record($$$)
#Generates a new instance from a list ref as obtained from one of the
#sacctmgr list commands
{	my $class = shift;
	my $record = shift;
	my $sacctmgr = shift; #Needed for slurm_version specific stuff
	my $me = __PACKAGE__ . '::new_from_sacctmgr_list_record';

	croak "$me: Missing req parameter sacctmgr at " unless $sacctmgr && ref($sacctmgr);

	my $fields = $class->_sacctmgr_fields_in_order($sacctmgr);
#2016-03-09: dropping special_fields; instead have accessors customized to handle either
#the real type or a string as input.  On output convert to string based on ref type
#	my $special = $class->_special_fields;
	my @record = @$record;

	my @newargs = ();

	foreach my $fld (@$fields)
	{	my $val = shift @record;
		$fld = lc $fld;

		$val = undef if defined $val && $val eq '';

#		my $type = $special->{$fld};
#		if ( $type )
#		{	my $dcf = $DATA_TYPES{$type};
#			unless ( $dcf )
#			{	die "Class $class: invalid data type $type for field $fld";
#			}
#			$val = &$dcf($val);
#		}
		push @newargs, $fld, $val;
	}

	my $obj = $class->new(@newargs);
	return $obj;
}

sub sacctmgr_list($$@)
#Does sacctmgr list to get a list all of the entities of this type
#matching specified criteria
{	my $class = shift;
	my $sacctmgr = shift;
	my %where = @_;

	my $me = 'sacctmgr_list';
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $cmd = $class->_sacctmgr_list_cmd($sacctmgr);
	my @cmd = @$cmd;

	#Throw a sort in to make ordering deterministic for regression tests
	foreach my $key (sort (keys %where) )
	{	my $val = $where{$key};
		$val = '' unless defined $val;
		#push @cmd, "$key='$val'";
		#Do NOT put extra quotes around $val; they are NOT needed
		#(we do not go through shell interpolation)
		push @cmd, "$key=$val";
	}

	my $list = $sacctmgr->run_generic_sacctmgr_list_command(@cmd);
	unless ( $list && ref($list) )
	{	croak "Error running list cmd for $class: $list at ";
	}
	$_last_raw_output = $sacctmgr->_sacctmgr_last_raw_output;

	my @objects = ();
	foreach my $rec (@$list)
	{	my $obj = $class->new_from_sacctmgr_list_record($rec, $sacctmgr);
		push @objects, $obj;
	}

	return [@objects];
}

sub sacctmgr_list_me($$)
#Takes an instance of an entity, and does a sacctmgr list to find the
#current value in SlurmDB for this entity instance
#Returns undef if no matches (I don't exist)
#Returns a new instance with that info
#On error, returns a non-ref error string
{	my $obj = shift;
	my $sacctmgr = shift;

	my $me = 'sacctmgr_list_me';
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $where = $obj->_my_sacctmgr_where_clause;
	my $list = $obj->sacctmgr_list($sacctmgr, %$where);
	return $list unless $list && ref($list) eq 'ARRAY';
	return unless scalar(@$list); #No matches, I don't exist

	if ( scalar(@$list) > 1 )
	{	my @tmp = map { "$_='" .  $where->{$_} . "'" } (keys %$where);
		my $tmp = join ", ", @tmp;
		my $class = ref($obj);
		return "Multiple  objects of type $class found with [$tmp]";
	}

	my $obj2 = $list->[0];
	return $obj2;
}

sub new_from_sacctmgr_by_name($$$)
#Get a new object for this entity class by looking up the appropriate
#entity from sacctmgr by the entity's name.
#
#Returns undef if no object with that name exists.
#Returns non-ref true value if encountered error (error message)
#Returns the object ref if succeeded.
{	my $class = shift;
	my $sacctmgr = shift;
	my $name = shift;

	my $me = 'new_from_sacctmgr_by_name';
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my %where = ( name => $name );
	my $list = $class->sacctmgr_list($sacctmgr, %where);

	return $list unless $list && ref($list) eq 'ARRAY'; #Error
	return unless scalar(@$list); #No matches, I don't exist

	if ( scalar(@$list) > 1 )
	{	croak "$me: Error, multiple entities of type $class named '$name' found, aborting at ";
	}
	my $obj = $list->[0];
	return $obj;
}

1;
__END__

=head1 NAME

Slurm::Sacctmgr::EntityBaseListable

=head1 SYNOPSIS

  package Slurm::Sacctmgr::Association;
  use base qw(Slurm::Sacctmgr::EntityBaseListable);

  sub _ro_fields($)
  {	my $class = shift;
	return qw( account description organization coordinators);
  }

  ...


=head1 DESCRIPTION

This is the base class for entities managed by sacctmgr, for entities
which can be listed with the "list" or "show" commands.
It provides the B<sacctmgr_list> method.  The heavy liting is actually
done by B<Slurm::Sacctmgr::EntityBase>.

See B<Slurm::Sacctmgr::EntityBase> for definitions of:

=over 4

=item B<_ro_fields> 

=item B<_rw_fields>

=item B<_required_fields>

=item B<_sacctmgr_fields_in_order>

=item B<_sacctmgr_entity_name>

=item B<_my_sacctmgr_where_clause>

=item B<_sacctmgr_name_field>

=back


This module defines

=over 4

=item B<_data_converter_csv>

Used for converting CSV output from sacctmgr list
commands to list refs.

=item B<_sacctmgr_list_cmd($sacctmgr)>

The sacctmgr list command to list entities of this type.
Requires a B<Slurm::Sacctmgr> instance because may depend on version of sacctmgr being used.
Default is "list $entity format=$fmtstr" where 
$entity is B<_sacctmgr_entity_name> and $fmtstr is the comma separated
concatenation of the field names in B<_sacctmgr_fields_in_order>

=item B<new_from_sacctmgr_list_record($rec)>

This is an alternative constructor, which  
takes a list ref e.g. from one of the list returned by a 
Slurm::Sacctmgr::run_generic_sacctmgr_list_command and returns
a new instance of specified type.  Elements of list are required to
be in the order given by B<_sacctmgr_fields_in_order>.

=item B<sacctmgr_list>($sacctmgr, [ where=>val, [where2=>val2 ... ])

This calls Slurm::Sacctmgr::run_generic_list_command to list the
entities of our type.  Optional where clauses given as key => value pairs
can be given, otherwise it should list all entities.  The returned list
is converted to a list of Perl objects of the appropriate type.
On error, a non-ref error string is returned.

=item B<sacctmgr_list_me($sacctmgr)>

This is an instance method, and calls B<sacctmgr_list> with the 
appropriate where clause to return only the record representing the
current instance.  This is returned as a new instance.  If no matching
record found, returns undef. On error, 
a non-ref error string is returned.

=item B<new_from_sacctmgr_by_name($sacctmgr, $name)>

Returns a new instance of the Perl object for given entity type, obtained
from looking up in sacctmgr for the record with the given name.  If no
such record found, returns undef.  Returns non-ref true value (error message)
on error.  Otherwise, returns the instance.

=back

=head2 EXPORT

Nothing.  Pure OO interface.

=head1 SEE ALSO

B<EntityBase>

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

