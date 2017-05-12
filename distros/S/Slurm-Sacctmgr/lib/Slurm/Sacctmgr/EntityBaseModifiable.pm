#!/usr/local/bin/perl
#
#Base class for sacctmgr entities which can be do "modify"

package Slurm::Sacctmgr::EntityBaseModifiable;
use strict;
use warnings;
use base qw(Slurm::Sacctmgr::EntityBase);
use Carp qw(carp croak);

#This is intended for regression tests only
my $_last_raw_output;
sub _ebmod_last_raw_output($)
{       return $_last_raw_output;
}
sub _clear_ebmod_last_raw_output($)
{	$_last_raw_output = [];
}

sub _sacctmgr_modify_cmd($)
{	my $class = shift;
	$class = ref($class) if ref($class);

	my $base = $class->_sacctmgr_entity_name;
	return [ '-i', 'modify', $base ];
}

sub _sacctmgr_fields_updatable($$)
#This lists the fields we can include in a sacctmgr modify call
#May in general depend on version of slurm, hence sacctmgr argument.
#Should be overloaded in all children classes
{       my $class = shift;
        my $sacctmgr = shift;
        $class = ref($class) if ref($class);
        die "Class $class forgot to overload _sacctmgr_fields_updatable";
}

sub sacctmgr_modify($$$$;$)
#Does sacctmgr update one or more entities of this type, as specified
#by $where hash ref (as key=>value pairs) to values in $update hash ref
#(again key=>value pairs).  Any non-string values in update hash are
#stringified using _stringify_value.
{	my $class = shift;
	my $sacctmgr = shift;
	my $where = shift || {};
	my $update = shift;
	my $quiet = shift;

	my $me = 'sacctmgr_modify';
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);
	croak "No/invalid update hash passed to $me at " 
		unless $update && ref($update) eq 'HASH' && 
		scalar(keys %$update);

	my $cmd = $class->_sacctmgr_modify_cmd;
	my @cmd = @$cmd;

	my ($key, $val);

	my @where = ();
	foreach $key (sort (keys %$where))
	{	$val = $where->{$key};
		#$val = '' unless defined $val;
		$val = $class->_stringify_value($val);
		#push @where, "$key='$val'";
		#No need for quoting argument, not going through shell
		#and in some cases might cause problems with sacctmgr interpretting
		#quotes as part of text
		push @where, "$key=$val";
	}
	if (@where )
	{	push @cmd, 'where', @where;
	}

	my @set = ();
	foreach $key (sort (keys %$update))
	{	$val = $update->{$key};
		#$val = '' unless defined $val;
		$val = $class->_stringify_value($val);
		#push @set, "$key='$val'";
		#No need for quoting argument, not going through shell
		#and in some cases might cause problems with sacctmgr interpretting
		#quotes as part of text (e.g. setting grptresmins)
		push @set, "$key=$val";
	}
	unless (@set )
	{	croak "No fields to set for $me at ";
	}
	push @cmd, 'set', @set;

	my $list = $sacctmgr->run_generic_sacctmgr_cmd(@cmd);
	unless ( $list && ref($list) eq 'ARRAY' )
	{	croak "Error running modify cmd for $class: $list at ";
	}

	if ( scalar(@$list) && ! $quiet )
	{	my $tmp = join "\n", @$list;
		if ( $tmp !~ /^\s*Modified / )
		{	#We got something other than the normal 
			#' Modified _entity_ ...' message
			warn "sacctmgr_modify returned:\n$tmp\n at ";
		}
	}
	$_last_raw_output = $list;
	return;
}

sub sacctmgr_modify_me($$@)
#Does sacctmgr update to the sacctmgr entity corresponding to this Perl
#object instance, setting to the %update values as key => value
{	my $obj = shift;
	my $sacctmgr = shift;
	my %update = @_;
	my $quiet = delete $update{QUIET};

	my $me = 'sacctmgr_modify_me';
	croak "$me must be called as an instance method at "
		unless $obj && ref($obj);
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $where = $obj->_my_sacctmgr_where_clause;
	return $obj->sacctmgr_modify($sacctmgr, $where, \%update, $quiet);
}

1;
__END__

=head1 NAME

Slurm::Sacctmgr::EntityBaseModifiable

=head1 SYNOPSIS

  package Slurm::Sacctmgr::Job;
  use base qw(Slurm::Sacctmgr::EntityBaseModifiable);


=head1 DESCRIPTION

This is the base class for entities managed by sacctmgr, for entities
which can be use the "modify" commands.
It provides the B<sacctmgr_add> and B<sacctmgr_del> methods.  The heavy liting is actually
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

=item B<_sacctmgr_modify_cmd>

The sacctmgr command to modify entities of this type.
Default is "-i modify $entity" where $entity is B<_sacctmgr_entity_name>.

=item B<sacctmgr_modify($sacctmgr, $where, $update)>

This calls Slurm::Sacctmgr::run_generic_command to modify one or
more entities of given type.  The entities to update are selected
by the key=>value pairs in the $where hash ref; if omitted will act on
ALL entities.  The fields to update are given by key=>value pairs in
the $update hash ref.

=item B<sacctmgr_modify_me($sacctmgr, [ fld1 => val1 [, fld2=>val2 ... ])>

This is an instance method, and calls B<sacctmgr_modify> 
to modify the entity represented by the Perl object as indicated.


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

