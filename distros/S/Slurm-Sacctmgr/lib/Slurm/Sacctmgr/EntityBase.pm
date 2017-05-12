#!/usr/local/bin/perl
#
#Base class for sacctmgr entities

package Slurm::Sacctmgr::EntityBase;
use strict;
use warnings;
use base qw(Class::Accessor);
use Carp qw(carp croak);

#-------------------------------------------------------------------
#	Globals
#-------------------------------------------------------------------

#-------------------------------------------------------------------
#	Accessors
#-------------------------------------------------------------------

sub _ro_fields($)
{	return [];
}

sub _rw_fields($)
{	return [];
}

sub _required_fields($)
{	return [];
}

#2016-03-09: dropping special_fields hash
#instead, have custom accessor/mutators handle string input and convert to proper type
#for output, output string based on ref type
# sub _special_fields($)
# #This should be overloaded to return any fields with special data types
# #for this class of entity
# {	my $class = shift;
# 	return {};
# }


#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

sub new($;@)
{	my $class = shift;
	my @args = @_;
	$class = ref($class) if ref($class);

	my $obj = {};
	bless $obj, $class;

	$obj->_parse_args(@args);
	$obj->_set_defaults;
	$obj->_init;

	return $obj;
}

sub _parse_args($@)
{	my $obj = shift;
	my %args = @_;

	my $accessors = $obj->_rw_fields;
	my ($arg, $meth, $val);
	RWARG: foreach $arg (@$accessors)
	{	next RWARG unless exists $args{$arg};
		$val = delete $args{$arg};
		next RWARG unless defined $val;
		$meth = $arg;
		$obj->$meth($val);
	}

	$accessors = $obj->_ro_fields;
	ROARG: foreach $arg (@$accessors)
	{	next ROARG unless exists $args{$arg};
		$val = delete $args{$arg};
		next ROARG unless defined $val;
		$meth = $arg;
		$obj->set($meth,$val);
	}


	#Warn about unknown arguments
	if ( scalar(keys %args) )
	{	my $tmp = join ", ", (keys %args);
		croak "Unrecognized arguments [ $tmp ] to constructor at ";
	};
}

sub _set_defaults($)
{	my $obj = shift;

	return;
}

sub _init($)
{	my $obj = shift;

	my ($fld, $meth, $val);
	my $req_parms = $obj->_required_fields;
	foreach $fld (@$req_parms)
	{	$meth = $fld;
		$val = $obj->$meth;
		unless ( defined $val )
		{	croak "Missing required argument $fld";
		}
	}

}

	
#-------------------------------------------------------------------
#	Special constructor to generate from a sacctmgr list entry
#-------------------------------------------------------------------

sub _sacctmgr_fields($)
#Should return a list ref of sacctmgr field names known about
#Will include field names for ALL known versions of sacctmgr; 
{	my $class = shift;
	$class = ref($class) if ref($class);
	die "Class $class forgot to overload _sacctmgr_fields";
}


sub _sacctmgr_fields_in_order($$)
#Should return a list ref of field names in order sacctmgr will return them
#Requires Slurm::Sacctmgr instance (as in general may depend on version 
#of slurm)
{	my $class = shift;
	my $sacctmgr = shift;
	$class = ref($class) if ref($class);
	die "Class $class forgot to overload _sacctmgr_fields_in_order";
}

#-------------------------------------------------------------------
#	Data conversion routines
#-------------------------------------------------------------------

sub _string2arrayref($$;$)
#This converts a string like 'joe,steve,bob' to [ 'joe', 'steve', 'bob' ]
{	my $class = shift;
	my $string = shift;
	my $me = shift || ( __PACKAGE__ . '::_string2arrayref' );
	return unless defined $string;

	#Strip leading/trailing spaces
	$string =~ s/^\s*//; $string =~ s/\s*$//;
	return unless $string;

	my @recs = split /\s*,\s*/, $string;
	return [ @recs ];
}

sub _arrayref2string($$;$)
#Reverse of _string2arrayref. 
#This converts an array ref  like [ 'joe', 'steve', 'bob' ] to 'joe,steve,bob'
{	my $class = shift;
	my $arrayref = shift;
	my $me = shift || ( __PACKAGE__ . '::_arrayref2string' );
	return unless defined $arrayref;

	croak "$me: arrayref2string given non array ref '$arrayref' at "
		unless $arrayref && ref($arrayref) eq 'ARRAY';

	my $string = join ',', @$arrayref;
	return $string;
}


sub _string2hashref($$;$)
#This converts a string like "cpu=10000,node=50" to { cpu=>10000, node=>50}
#hash ref.  Intended for use with TRESes
{	my $class = shift;
	my $string = shift;
	my $me = shift || ( __PACKAGE__ . '::_string2hashref' );
	return unless defined $string;

	#Strip leading/trailing spaces
	$string =~ s/^\s*//; $string =~ s/\s*$//;
	return unless $string;

	my @recs = split /\s*,\s*/, $string;
	my $hash = {};
	foreach my $rec (@recs)
	{	croak "$me: Invalid component '$rec' in TRES string '$string', no =, at "
			unless $rec =~ /=/;
		my ( $fld, $val ) = split /\s*=\s*/, $rec;
		croak "$me: Duplicate TRES '$fld' in TRES string '$string' at "
			if exists $hash->{$fld};
		$hash->{$fld} = $val;
	}
	return $hash;
} 

sub _hashref2string($$;$)
#Reverse of _string2hashref
#This converts a hashref like { node=>50, cpu=>10000} to "cpu=10000,node=50"
#NOTE: hash keys are always in order, to provide determinism needed for regression tests
#Intended for use with TRESes
{	my $class = shift;
	my $hashref = shift;
	my $me = shift || ( __PACKAGE__ . '::_hashref2string' );
	return unless defined $hashref;

	croak "$me: hashref2string given non hash ref '$hashref' at "
		unless $hashref && ref($hashref) eq 'HASH';

	my @recs = map { "$_=$$hashref{$_}" } (sort keys %$hashref );
	my $string = join ',', @recs;
	return $string;
} 

sub _stringify_value($$;$)
#Converts a value to a string, based on ref type.
#Undef => ''
#Non-ref scalars passed unchanged
#hash ref converted using _hashref2string
#array refs converted using _arrayref2string
{	my $class = shift;
	my $value = shift;
	my $me = shift || ( __PACKAGE__ . '::_stringify_value');

	return '' unless defined $value;
	return $value unless ref($value);

	return $class->_hashref2string($value, $me) if ref($value) eq 'HASH';
	return $class->_arrayref2string($value, $me) if ref($value) eq 'ARRAY';

	croak "$me: Invalid value '$value', expecting non-ref or hash/array ref at ";
}


#-------------------------------------------------------------------
#	Accessor factories for fields w type conversions
#-------------------------------------------------------------------

sub mk_arrayref_accessors($@)
#Takes a list of fieldnames for which we should construct
#array ref typed accessors/mutators.  
#Such accessors will return an array ref always
#Mutators will accept either array ref or comma delimited string
#
{	my $class = shift;
	my @array_fields = @_;

	foreach my $afld (@array_fields)
	#Create accessor/mutator for array type field
	{   my $fqn = $class . '::' . $afld;
	    no strict "refs";
	    *{$fqn} = sub 
	    {	my $self = shift;
		my $new = shift;
		my $me = $fqn;

		if ( defined $new )
		{	$new = $self->_string2arrayref($new, $me) unless ref($new);
			croak "$me: Illegal value '$new', expecting arrayref/comma delim string, at "
				unless $new && ref($new) eq 'ARRAY';
			$self->set($afld, [ @$new ]);
		}
		my $val = $self->get($afld);
		return $val;
	    };
	}

	#Should we create a ${afld}_as_string accessor as well???????
}

#-------------------------------------------------------------------
#	Special accessor factory for TRES/nonTRES stuff
#-------------------------------------------------------------------

sub mk_tres_nontres_accessors($$@)
#Takes the name of a TRES-style field, and a list ref of key=>value
#pairs, with key being the name of the   nonTRES-style field and 
#value being the TRES name associated with it.
#This method will generate:
#1) An accessor/mutator for the TRES-style field.  When used as a
#mutator, the various nonTRES-style fields will also be set based on
#the specified TRES 
#2) Accessor/mutators for the nonTRES-style fields.  When used as
#a mutator, these will set the hash key in the TRES-field according
#to the TRES listed.
#
{	my $class = shift;
	my $TRESfld = shift;
	my %nonTREShash = @_;

	#Create accessor/mutator for TRES field
	{   my $fqn = $class . '::' . $TRESfld;
	    no strict "refs";
	    *{$fqn} = sub 
	    {	my $self = shift;
		my $new = shift;
		my $me = $fqn;

		if ( defined $new )
		{	$new = $self->_string2hashref($new, $me) unless ref($new);
			croak "$me: Illegal value '$new', expecting TRES hashref/string, at "
				unless $new && 
				( ref($new) eq 'HASH' || ref($new) eq 'ARRAY' );
			if ( ref($new) eq 'ARRAY' )
			{	if ( scalar(@$new) % 2 )
				{	croak "$me: Illegal value '$new'; expecting TRES hashref/string,"
						. " cannot convert aref with odd # of elements to href at ";
				}
				$new = { @$new };
			} else
			{	$new = { %$new };
			}
			$new = { %$new };
			$self->set($TRESfld, $new);

			foreach my $tmpfld (keys %nonTREShash)
			{	my $tmpTRES = $nonTREShash{$tmpfld};
				my $tmpval = $new->{$tmpTRES};
				$self->set($tmpfld, $tmpval);
			}
		}
		my $val = $self->get($TRESfld);
		return $val;
	    };
	}
	#Create accessors/mutators for nonTRES fields
	foreach my $nonTRESfld (keys %nonTREShash )
	{	my $TRESkey = $nonTREShash{$nonTRESfld};
		{   my $fqn = $class . '::' . $nonTRESfld;
		    no strict "refs";
		    *{$fqn} = sub
		    {	my $self = shift;
			my $new = shift;
			my $me = $fqn;

			if ( defined $new )
			{	croak "$me: Illegal value '$new', expecting scalar, at "
					if ref($new);
				$self->set($nonTRESfld, $new);

				my $hash = $self->get($TRESfld);
				unless ( $hash && ref($hash) eq 'HASH' )
				{	$hash = {};
				}
				$hash->{$TRESkey} = $new;
				$self->set($TRESfld, $hash);
			}
			my $val = $self->get($nonTRESfld);
			return $val;
		    };
		}
	}
}

#-------------------------------------------------------------------
#	Lookup entity with sacctmgr
#-------------------------------------------------------------------

sub _sacctmgr_entity_name($)
{	my $class = shift;
	$class = ref($class) if ref($class);

	my $base = $class;
	$base =~ s/^.*://;
	$base = lc $base;
	return $base;
}


sub _sacctmgr_name_field($)
{	my $class = shift;
	$class = ref($class) if ref($class);
	die "Class $class did not overload _sacctmgr_name_field ";
}

sub _my_sacctmgr_where_clause($)
#This might need to be overloaded.
#Returns a where clause hash that should return the current entity.
{	my $obj = shift;
	croak "Must be called as an instance method at "
		unless $obj && ref($obj);
	my $namefld = $obj->_sacctmgr_name_field;
	my $meth = $namefld;
	my $val = $obj->$meth;
	#$val = '' unless defined $val;
	$val = $obj->_stringify_value($val);
	return { $namefld => $val };
}

1;
__END__

=head1 NAME

Slurm::Sacctmgr::EntityBase

=head1 SYNOPSIS

  package Slurm::Sacctmgr::Account;
  use base qw(Slurm::Sacctmgr::EntityBase);

  sub _ro_fields($)
  {	my $class = shift;
	return qw( account description organization coordinators);
  }

  ...


=head1 DESCRIPTION

This is the base class for entities managed by sacctmgr.
It provides common constructors, etc.

Child classes should overload the following methods to customize
behavior:

=over 4

=item B<_ro_fields> 

Should return a list ref of the names of the
read-only fields for this entity.  Default is empty.

=item B<_rw_fields>

Should return a list ref of the names of the
read-write fields for this entity.  Default is empty.

=item B<_required_fields>

A list of required fields for the constructor to make the object.
Default is empty.

=item B<_sacctmgr_fields>

This should return a list ref of field names, including all
fields names sacctmgr knows about (for all versions of sacctmgr).

=item B<_sacctmgr_fields_in_order($sacctmgr)>

A list ref of field names in order sacctmgr will return them
Takes a B<Slurm::Sacctmgr> instance as an argument, because
in general this may depend on the version of Slurm/sacctmgr.
Must be overridden.

=item B<_sacctmgr_entity_name>

The name of sacctmgr entity associated with this Perl class.
Default is just derived from the class name.

=item B<_my_sacctmgr_where_clause>

The "where" clause to give to the sacctmgr list command to list
just the record corresponding to this instance in the database.
The default is "name=>$NameValue" where NameValue is the value of
the field named B<_sacctmgr_name_field>.  Should be a hash ref
of key => value pairs.

=item B<_sacctmgr_name_field>

Used to default B<_my_sacctmgr_where_clause> above.

=item B<_sacctmgr_fields_addable($sacctmgr)>

Only for child classes of B<EntityBaseAddDel>, this should return a list ref
of field names which can be included in a B<sacctmgr add> command for this
entity type.  As this in general may depend on the version of Slurm running,
includes a B<Slurm::Sacctmgr> instance (which will have version of Slurm).

=item B<_sacctmgr_fields_updatable($sacctmgr)>

Only for child classes of B<EntityBaseModifiable>, this should return a list ref
of field names which can be included in a B<sacctmgr update> command for this
entity type.  As this in general may depend on the version of Slurm running,
includes a B<Slurm::Sacctmgr> instance (which will have version of Slurm).


=back

Most useful methods are in subclasses depending on which commands
can be issues on entities of that type.  E.g, 

=over 4

=item B<EntityBaseListable> for entities supporting the "list" command

=item B<EntityBaseAddDel> for entities with the "add" and "delete" command

=item B<EntityBaseModifiable> for entities supporting the "modify" command

=item B<EntityBaseRW> for entities with the "list", "add", "delete" and "modify" commands

=back

=head2 EXPORT

None.  Pure OO interface.

=head1 SEE ALSO

B<EntityBaseListable>
B<EntityBaseAddDel>
B<EntityBaseModifiable>
B<EntityBaseRW>

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

