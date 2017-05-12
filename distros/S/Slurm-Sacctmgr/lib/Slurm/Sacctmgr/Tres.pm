#!/usr/local/bin/perl
#
#Part of Slurm::Sacctmgr: Perl wrapper for Slurm's sacctmgr cmd
#Represents an Trackable Resource (TRES)

package Slurm::Sacctmgr::Tres;
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

#Accessors common to all versions of slurm > 15.x 
#(TRES not available at ALL before then)
my @simple_accessors = qw(
	name
	id
	type
);

my @all_accessors = (
	@simple_accessors,
);

__PACKAGE__->mk_accessors(@simple_accessors);

#-------------------------------------------------------------------
#	Overloaded methods
#-------------------------------------------------------------------

sub _rw_fields($)
{	my $class = shift;
	return [ @all_accessors ];
}

sub _sacctmgr_name_field($)
{	my $class = shift;
	return 'id';
}
 
sub _sacctmgr_fields_in_order($$)
{	my $class = shift;
	my $sacctmgr = shift;
	my @fields;
	if ( $sacctmgr->sacctmgr_cmd_supports('trackable_resources') )
	{	@fields= @all_accessors;
	} 

	return [ @fields ];
}

#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

#All inherited

1;
__END__

=head1 NAME

Slurm::Sacctmgr::Tres;

=head1 SYNOPSIS

  use Slurm::Sacctmgr::Tres;
  use Slurm::Sacctmgr;

  my $sacctmgr = new Slurm::Sacctmgr;
  my $list = Slurm::Sacctmgr::Tres->sacctmgr_list($sacctmgr);

  #List all TRESes known to sacctmgr
  foreach $tres (@$list)
  {	#tres is a Slurm::Sacctmgr::Tres object
  	$id = $tres->id;
	$name = $tres->name;
	$type = $tres->type
	my $qname = $type;
	$qname .= "/$name" if $name;
	print "${qname} $id\n";
  }

  ...


=head1 DESCRIPTION

Represents a Trackable Resource (TRES) entity in Slurm::Sacctmgr.  Together with an
instance of  B<Slurm::Sacctmgr>, this class allows one to issue
commands to the Slurm B<sacctmgr> command to list or
show sacctmgr entities of type "TRES".  

The B<Slurm::Sacctmgr> class provides a Perlish wrapper around
the actual Slurm B<sacctmgr> command, thus the methods provided
by this class largely map quite straightforwardly onto B<sacctmgr>
commands.  When using the B<sacctmgr_list> method for this class, the 
results from the sacctmgr command is automatically parsed and presented
as objects of this class.

Objects of this class contain the following data members:

=over 4

=item B<type>: the type of TRES (e.g. cpu, mem, energy, node, bb, gres, or license)

=item B<name>: the name of the TRES (for bb, gres, or license TRESes)

=item B<id>: the id of the TRES

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
all have a very similar tres interface (basically the differences are what
operations sacctmgr allows on different entity types, and how the results
of list/show operations get parsed).  

Sacctmgr does NOT allow the direct addition, deletion and/or modification of 
TRESes, only the viewing of defined TRESes.

As such, the only real method provided by this package is
B<sacctmgr_list($sacctmgr, %where)>.  This will return a list reference of all 
tress matching the "where" clause.  
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

Copyright (C) 2016 by the University of Maryland.

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

