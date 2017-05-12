#!/usr/local/bin/perl
#
#Base class for sacctmgr entities which can be do "add" and "delete"

package Slurm::Sacctmgr::EntityBaseAddDel;
use strict;
use warnings;
use base qw(Slurm::Sacctmgr::EntityBase);
use Carp qw(carp croak);

#This is intended for regression tests only
my $_last_raw_output;
sub _ebadddel_last_raw_output($)
{	return $_last_raw_output;
}
sub _clear_ebadddel_last_raw_output($)
{       $_last_raw_output = [];
}


sub _sacctmgr_add_cmd($)
{	my $class = shift;
	$class = ref($class) if ref($class);

	my $base = $class->_sacctmgr_entity_name;
	return [ '-i', 'add', $base ];
}

sub _sacctmgr_delete_cmd($)
{	my $class = shift;
	$class = ref($class) if ref($class);

	my $base = $class->_sacctmgr_entity_name;
	return [ '-i', 'delete', $base ];
}

sub _sacctmgr_fields_addable($$)
#This lists the fields we can include in a sacctmgr add/create call
#May in general depend on version of slurm, hence sacctmgr argument.
#Should be overloaded in all children classes
{       my $class = shift;
	my $sacctmgr = shift;
        $class = ref($class) if ref($class);
        die "Class $class forgot to overload _sacctmgr_fields_addable";
}

sub _my_sacctmgr_add_clause($$)
#This might need to be overloaded.
#Returns a hash ref for adding this instance into DB with sacctmgr.
{	my $obj = shift;
	my $sacctmgr = shift;
	croak "Must be called as an instance method at "
		unless $obj && ref($obj);
	my $me = ref($obj) . '::_my_sacctmgr_add_clause';
	die "$me: Missing req param sacctmgr at " unless $sacctmgr;
	
	my $namefld = $obj->_sacctmgr_name_field;
	my $fields = $obj->_sacctmgr_fields_addable($sacctmgr); 

	my %hash = ();
	FIELD: foreach my $fld (@$fields)
	{	my $fldname=$fld;
		$fldname = $namefld if $fld eq 'name';
		my $meth = $fld;
		my $val = $obj->$meth;
		next FIELD unless defined $val;
		$hash{$fldname} = $obj->_stringify_value($val, $me);
	}
	return \%hash;
}

sub sacctmgr_add($$@)
#Does sacctmgr list to get a add an entity of this type with specified
#fields (given as key => value pairs).
{	my $class = shift;
	my $sacctmgr = shift;
	my %fields = @_;

	my $me = 'sacctmgr_add';
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $cmd = $class->_sacctmgr_add_cmd;
	my @cmd = @$cmd;

	my $ok_if_exists = delete $fields{'--ok-if-previously-exists'};

	#Throw a sort in to make ordering deterministic for regression tests
	KEY: foreach my $key (sort(keys %fields))
	{	my $val = $fields{$key};
		$val = $class->_stringify_value($val);
		#push @cmd, "$key='$val'";
		#Do not add extra quotes around '$val'; they are NOT needed
		#(eventually being passed to execvp call, so NEVER go through
		#shell interpolation, so not needed), and can cause issues
		#on certain sactmgr cmds which do not strip away quotes
		#(e.g. setting defaultqos).
		push @cmd, "$key=$val";
	}

	my $list = $sacctmgr->run_generic_sacctmgr_cmd(@cmd);
	unless ( $list && ref($list) )
	{	#Got an error.
		chomp $list if $list;
		if ( $list =~ /Nothing new added/ )
		{	return [] if $ok_if_exists;
			croak "Trying to add existing object at ";
		}
		croak "Error running add cmd for $class: $list at ";
	}
	$_last_raw_output = $list;
	return $list;

}

sub sacctmgr_add_me($$@)
#Does sacctmgr list to get add an entity record for this Perl object instance.
{	my $obj = shift;
	my $sacctmgr = shift;
	my %extra = @_;

	my $me = 'sacctmgr_add_me';
	croak "$me must be called as an instance method at "
		unless $obj && ref($obj);
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $addclause = $obj->_my_sacctmgr_add_clause($sacctmgr);

	#Add extra fields
	$addclause = { %$addclause, %extra };
	return $obj->sacctmgr_add($sacctmgr, %$addclause);

}

sub sacctmgr_delete($$@)
#Does sacctmgr delete to delete all of the entities of this type
#matching specified criteria
{	my $class = shift;
	my $sacctmgr = shift;
	my %where = @_;

	my $me = 'sacctmgr_delete';
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $cmd = $class->_sacctmgr_delete_cmd;
	my @cmd = @$cmd;

	my @where = ();
	foreach my $key (sort (keys %where) )
	{	my $val = $where{$key};
		$val = '' unless defined $val;
		#push @where, "$key='$val'";
		#Do not add extra quotes around '$val'; they are NOT needed
		#We do NOT go through shell interpolation
		push @where, "$key=$val";
	}
	if ( @where )
	{	push @cmd, 'where', @where;
	} else
	{	croak "$me refusing to issue delete w/out where clause at ";
	}

	my $list = $sacctmgr->run_generic_sacctmgr_cmd(@cmd);
	unless ( $list && ref($list) )
	{	#"Nothing deleted" is NOT an error
		#return 0 to distinguish from undef for actual deletion case
		return 0 if $list =~ /Nothing deleted/;
		croak "Error running delete cmd for $class: $list at ";
	}
	$_last_raw_output = $list;
	return;
}

sub sacctmgr_delete_me($$)
#Does sacctmgr delete to the sacctmgr entity corresponding to this Perl
#object instance
{	my $obj = shift;
	my $sacctmgr = shift;

	my $me = 'sacctmgr_delete_me';
	croak "$me must be called as an instance method at "
		unless $obj && ref($obj);
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $where = $obj->_my_sacctmgr_where_clause;
	return $obj->sacctmgr_delete($sacctmgr, %$where);
}

1;
__END__

=head1 NAME

Slurm::Sacctmgr::EntityBaseAddDel

=head1 SYNOPSIS

  package Slurm::Sacctmgr::Coordinator;
  use base qw(Slurm::Sacctmgr::EntityBaseAddDel);


=head1 DESCRIPTION

This is the base class for entities managed by sacctmgr, for entities
which can be use the "add" and "delete" commands.
It provides the B<sacctmgr_add> and B<sacctmgr_del> methods.  The heavy lifting is actually
done by B<Slurm::Sacctmgr::EntityBase>.

This is a child class of B<Slurm::Sacctmgr::EntityBase>, see that class for functions
not described here.

This module defines

=over 4

=item B<_sacctmgr_fields_addable($sacctmgr)>

This should be overloaded in any child classes.  This should return a list ref
of field names which can be included in a B<sacctmgr add> command for this
entity type.  As this in general may depend on the version of Slurm running,
includes a B<Slurm::Sacctmgr> instance (which will have version of Slurm).

=item B<_sacctmgr_add_cmd>

The sacctmgr command to add entities of this type.  
Default is "-i add $entity" where $entity 
is B<_sacctmgr_entity_name>.

=item B<_sacctmgr_delete_cmd>

The sacctmgr command to delete entities of this type.  
Default is "-i delete $entity" where $entity 
is B<_sacctmgr_entity_name>.

=item B<_my_sacctmgr_add_clause>

The clause to give to the sacctmgr list command to add this entity
to the database with sacctmgr.  Should be a hash ref of key =>
value pairs.  The default is just the list of parameter names
(from B<_sacctmgr_fields_in_order>) and there values, with the name of
B<_sacctmgr_name_field> replaced by 'name', and the key => value pairs for
undef values omitted.

=item B<sacctmgr_add>($sacctmgr, [ fld1=>val, [fld2=>val2 ... ])

This calls Slurm::Sacctmgr::run_generic_command to add an entity
of the desired type with the specified fields.  In addition to the
standard field definitions, if the pseudo-field '--ok-if-previously-exists'
is passed and true, the method will return "successfully" even if B<sacctmgr>
errors because the entity already exists.

=item B<sacctmgr_add_me>($sacctmgr, [ extra1 => val, [ extra2 => val2 ...]])

This is an instance method, and calls B<sacctmgr_add> with the 
appropriate parameters to add the entity represented by the Perl object.
If any "extra" arguments are provided, this will also be passed to B<sacctmgr>.
B<NOTE:> The extra arguments will override data members if there is a conflict.

=item B<sacctmgr_delete>($sacctmgr, [ fld1=>val, [fld2=>val2 ... ])

This calls Slurm::Sacctmgr::run_generic_command to delete one or more
entities matching the specified fields.  It requires some where clause
or will abort.

=item B<sacctmgr_delete_me($sacctmgr)>

This is an instance method, and calls B<sacctmgr_modify> 
to delete the entity record in the DB corresponding to the invocant
Perl object.

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

