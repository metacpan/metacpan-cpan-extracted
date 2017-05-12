package Palm::Memo;
#
# ABSTRACT: Read/write Palm OS Memo databases
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.

use strict;
use Palm::Raw();
use Palm::StdAppInfo();
use vars qw( $VERSION @ISA );

# One liner, to allow MakeMaker to work.
$VERSION = '1.400';
# This file is part of Palm 1.400 (March 14, 2015)

@ISA = qw( Palm::StdAppInfo Palm::Raw );

#'

sub import
{
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "memo", "DATA" ],
		);
}

#'
sub new
{
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = "MemoDB";	# Default
	$self->{creator} = "memo";
	$self->{type} = "DATA";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since MemoDB is explicitly not a PRC.

	# Initialize the AppInfo block
	$self->{appinfo} = {
		sortOrder	=> undef,	# XXX - ?
	};

	# Add the standard AppInfo block stuff
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	# Give the PDB a blank sort block
	$self->{sort} = undef;

	# Give the PDB an empty list of records
	$self->{records} = [];

	return $self;
}


sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	$retval->{data} = "";

	return $retval;
}

# ParseAppInfoBlock
# Parse the AppInfo block for Memo databases.
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $sortOrder;
	my $i;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at the non-category part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack()
		"x4" .		# Padding
		"C";		# Sort order

	($sortOrder) = unpack $unpackstr, $data;

	$appinfo->{sortOrder} = $sortOrder;

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;
	my $i;

	# Pack the non-category part of the AppInfo block
	$self->{appinfo}{other} =
		pack("x4 C x1", $self->{appinfo}{sortOrder});

	# Pack the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

sub PackSortBlock
{
	# XXX
	return undef;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	delete $record{offset};		# This is useless
	$record{data} =~ s/\0$//;	# Trim trailing NUL

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;

	return $record->{data} . "\0";	# Add the trailing NUL
}

1;

__END__

=head1 NAME

Palm::Memo - Handler for Palm Memo databases.

=head1 VERSION

This document describes version 1.400 of
Palm::Memo, released March 14, 2015
as part of Palm version 1.400.

=head1 SYNOPSIS

    use Palm::Memo;

=head1 DESCRIPTION

The Memo PDB handler is a helper class for the Palm::PDB package. It
parses Memo databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{sortOrder}

I don't know what this is.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N]

    $record->{data}

A string, the text of the memo.

=head2 new

  $pdb = new Palm::Memo;

Create a new PDB, initialized with the various Palm::Memo fields
and an empty record list.

Use this method if you're creating a Memo PDB from scratch.

=head2 new_Record

  $record = $pdb->new_Record;

Creates a new Memo record, with blank values for all of the fields.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<$pdb-E<gt>append_Record>.

=head1 SEE ALSO

L<Palm::PDB>

L<Palm::StdAppInfo>

=head1 CONFIGURATION AND ENVIRONMENT

Palm::Memo requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHORS

Andrew Arensburger C<< <arensb AT ooblick.com> >>

Currently maintained by Christopher J. Madsen C<< <perl AT cjmweb.net> >>

Please report any bugs or feature requests
to S<C<< <bug-Palm AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Palm >>.

You can follow or contribute to p5-Palm's development at
L<< https://github.com/madsen/p5-Palm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Andrew Arensburger & Alessandro Zummo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
