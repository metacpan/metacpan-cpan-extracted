#!/usr/local/bin/perl
#
#Base class for sacctmgr entities which can do all of
#"list", "modify", "add" and "delete".
#I.e. have full read/write capabilities

package Slurm::Sacctmgr::EntityBaseRW;
use strict;
use warnings;
use base qw(
	Slurm::Sacctmgr::EntityBaseListable
	Slurm::Sacctmgr::EntityBaseModifiable
	Slurm::Sacctmgr::EntityBaseAddDel
);
use Carp qw(carp croak);

sub _compare_values_deeply($$$)
#Takes a pair of values and compares them
#Returns false if they are equal, true if they are different
#Values can be:
#	undef: only equal to undef
#	non-ref scalar: if both look like number, compare using '==', 
#		otherwise compare using 'eq'
#	array ref: Returns false unless are of same length
# 		if of same length, compare recursively on each element.
#	hash ref: Returns false unless list of keys are same,
#		if same, compare recursively on each element
#
#
#Returns false if the two are equal
#Returns true (text on diff) if not equal
{	my $class = shift;
	my $val1 = shift;
	my $val2 = shift;
	my $me = __PACKAGE__ . '::_compare_values_deeply';

	my ($i, $len1, $len2, $tmp, $tmp1, $tmp2);

	unless ( defined $val1 )
	{	#val1 undefined, mismatch unless val2 also undef
		return 'val1 undef, val2 defined' if defined $val2;
		#both undef
		return 0;
	}

	#val1 is defined if reach here

	return 'val1 defined, val2 not' unless defined $val2;

	#Both val1 and val2 defined after this point

	if ( ref($val1) eq 'ARRAY' )
	{	return 'val1 aref, val2 not' unless ref($val2) eq 'ARRAY';

		#Compare array refs
		my $len1 = scalar(@$val1);
		my $len2 = scalar(@$val2);
		return 'arefs of different lengths' unless $len1 == $len2;

		$i=0;
		AREF_LOOP: while ( $i < $len1 )
		{	$tmp1 = $val1->[$i];
			$tmp2 = $val2->[$i];
			$tmp = $class->_compare_values_deeply($tmp1,$tmp2);

			if ( $tmp )
			{	return "arefs differ elem# $i: $tmp";
			}
			$i++;
		}
		#All elements agree, so matches
		return 0;
	}

	if ( ref($val1) eq 'HASH' )
	{	return 'val1 href, val2 not' unless ref($val2) eq 'HASH';

		#Compare hash refs
		my @keys1 = sort ( keys %$val1);
		my @keys2 = sort ( keys %$val2);
		$tmp = $class->_compare_values_deeply( [@keys1], [@keys2] );
		return "hrefs with different keys: $tmp" if $tmp;

		HREF_LOOP: foreach $i (@keys1)
		{	$tmp1 = $val1->{$i};
			$tmp2 = $val2->{$i};
			$tmp = $class->_compare_values_deeply($tmp1,$tmp2);
			next HREF_LOOP unless $tmp;

			return "arefs differ at key '$i': $tmp";
		}
		#All elements agree, so matches
		return 0;
	}

	if ( ref($val1) )
	{	$tmp1 = ref($val1);
		$tmp2 = ref($val2);
		$tmp = $tmp2 || '<non-ref scalar>';
		return "val1 is $tmp2, val2 is $tmp" unless $tmp1 eq $tmp2;

		carp "$me: Don't know how to handle ref type $tmp1, treating as equal???";
		return 0;
	}

	#val1 is non-ref scalar
	$tmp = ref($val2);
	return "val1 is non-ref scalar, val2 is $tmp" if $tmp;

	#val1 and val2 are both non-ref scalars

	#Does val1 look like a number
	#First regexp should be true for any pos/neg int or real number (but not scientific notation)
	#However, will also accept some non-numbers, eg. "+", "-.", ".", or "   ", so require a digit as well
	#Probably is a better way
	if ( $val1 =~ /^\s*[-+]?\d*\.?\d*\s*$/ && $val1 =~ /\d/ )
	{	#val1 looks like a number
		if ( $val2 =~ /^\s*[-+]?\d*\.?\d*\s*$/ && $val2 =~ /\d/ )
		{	#val1 and val2 both look like numbers
			return 0 if $val1 == $val2;
			return "$val1 != $val2";
		}
	}
	#At least one did not look like a number, so do string comparison
	return 0 if $val1 eq $val2;
	return "$val1 ne $val2";
}

sub compare($$)
#Compare two instances, field by field (using
#Returns a list ref of triplets [ fieldname, value1, value2 ] for every
#field that differs.  If no differences, returns undef.
#value1 is the value for the invocant, value2 is the value of the field
#of the explicit argument.
#
#Compares fieldsd from _sacctmgr_fields; 
{	my $obj1 = shift;
	my $obj2 = shift;

	my $me = 'compare';
	croak "$me must be called as an instance method at "
		unless $obj1 && ref($obj1);
	croak "Bad invalid argument to $me: $obj2"
		unless $obj2 && ref($obj2) eq ref($obj1);

	my $fields = $obj1->_sacctmgr_fields;

	my @diffs = ();
	foreach my $fld (@$fields)
	{	my $meth = $fld;
		my $val1 = $obj1->$meth;
		my $val2 = $obj2->$meth;

		my $tmp = $obj1->_compare_values_deeply($val1,$val2);
		push @diffs, [ $fld, $val1, $val2 ] if $tmp;
	}

	return unless @diffs;
	return [@diffs];
}

sub sacctmgr_save_me($$@)
{	my $obj = shift;
	my $sacctmgr = shift;
	my %extra = @_;
	my $quiet = delete $extra{QUIET};

	my $me = 'sacctmgr_save_me';
	croak "$me must be called as an instance method at "
		unless $obj && ref($obj);
	croak "No/invalid Slurm::Sacctmgr object passed to $me at "
		unless $sacctmgr && ref($sacctmgr);

	my $current = $obj->sacctmgr_list_me($sacctmgr);
	unless ( defined $current )
	{	#No current entity matching me, so just do sacctmgr_add_me
		return $obj->sacctmgr_add_me($sacctmgr, %extra);
	}
	croak "Error looking up entity in $me : $current at"
		unless ref($current);

	my $diffs = $obj->compare($current);
	return unless ( $diffs || scalar(%extra) ); #Nothing to do

	my $modifiable_fields = $obj->_sacctmgr_fields_updatable($sacctmgr) || [];
	my %modifiable = map { $_ => undef } @$modifiable_fields;
	my $mdiffs = [ grep { exists $modifiable{$_->[0]} } @$diffs ];
	
	#Should we alert here if there are diffs we cannot save?
	#But how to determine.  Certainly mdiffs empty indicates such an issue,
	#but there are many other cases.  And mdiffs will in general not equal
	#diffs; e.g. even when changing a TRES value which is available nonTRES.
	#For now, warn on nothing since cant figure out how to easily warn
	return unless ( scalar(@$mdiffs) || scalar(%extra) );
	
	my %updates = ();
	foreach my $rec (@$mdiffs)
	{	my ($fld, $val1, $val2) = @$rec;
		#$val1 = '' unless defined $val1;
		$updates{$fld} = $obj->_stringify_value($val1, $me);
	}
	%updates = ( %updates, %extra );

	$obj->sacctmgr_modify_me($sacctmgr, %updates, QUIET=>$quiet);
}


1;
__END__

=head1 NAME

Slurm::Sacctmgr::EntityBaseAddDel

=head1 SYNOPSIS

  package Slurm::Sacctmgr::Account;
  use base qw(Slurm::Sacctmgr::EntityBaseRW);


=head1 DESCRIPTION

This is the base class for entities managed by sacctmgr, for entities
which support the full set of read/write commands, i.e. can do all
of

=over 4

=item add (i.e. inherits from B<Slurm::Sacctmgr::EntityBaseAddDel> )

=item delete (i.e. inherits from B<Slurm::Sacctmgr::EntityBaseAddDel> )

=item list (i.e. inherits from B<Slurm::Sacctmgr::EntityBaseListable> )

=item modify (i.e. inherits from B<Slurm::Sacctmgr::EntityBaseModifiable> )

=back

And for most part, this class just inherits from the classes above.
But it also defines

=over 4

=item B<compare>($sacctmgr, $instance2)

This compares the invocant to $instance2, field by field.
It returns undef if no differences, or a list of triplets
[ fieldname, value1, value2 ] for each field fieldname that
differs, with value1 being the value in the invocant and
value2 the value in instance2.
Compares fields from B<_sacctmgr_fields>.  Array and hash
refs are compared element by element; non-ref scalars that
look like numbers are compared as numbers, otherwise as strings.

=item B<sacctmgr_save_me>($sacctmgr, [ extra1 => val1, [ extra2=>val2 ... ]])

This is an instance method, and calls B<sacctmgr_modify> to update the
entity with the same name to the values of the Perl object.  Obviously
cannot be used to change the name of an object.  If no entity exists in
sacctmgr db, does same as B<sacctmgr_add_me>.

B<NOTE:> The extra arguments will override data members if there is a conflict.

B<NOTE:> This method currently silently ignores differences in fields which
cannot be updated.  This includes values that can be read but not updated with a B<sacctmgr>
invocation on the particular entity type (e.g. 'coordinators' field for 
B<Slurm::Sacctmgr::Account>), or fields that are not supported for the particular
version of Slurm (while a value for a resource in a TRES variable that has a non-TRES
analog will be set in non-TRES supporting Slurms, e.g. the B<cpu> field of B<GrpTRESMins>
will be set via the B<GrpCPUMins> analog, resource settings for which no such analog
exists, e.g. B<gres/gpu>, will just be silently ignored).

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

