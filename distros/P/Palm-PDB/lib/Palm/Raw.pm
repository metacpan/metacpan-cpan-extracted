package Palm::Raw;
#
# Perl class for dealing with "raw" PDB databases. A "raw" database is
# one where the AppInfo and sort blocks, and all of the
# records/resources, are just strings of bytes.
# This is useful as a default PDB handler, for cases where you want to
# be able to handle any kind of database in a generic fashion.
# You may also find it useful to subclass this class, for cases where
# you don't care about every type of thing in a database.
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

use 5.006;
use strict;
use Palm::PDB;

our $VERSION = '1.400'; # VERSION
# This file is part of Palm-PDB 1.400 (March 7, 2015)

our @ISA = qw( Palm::PDB );

# ABSTRACT: Handler for "raw" Palm databases

#'

sub import
{
	# This package handles any PDB.
	&Palm::PDB::RegisterPDBHandlers(__PACKAGE__,
		[ "", "" ]
		);
}

# sub new
# sub new_Record
# These are just inherited.

sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;

	return $data;
}

sub ParseSortBlock
{
	my $self = shift;
	my $data = shift;

	return $data;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	return \%record;
}

sub ParseResource
{
	my $self = shift;
	my %resource = @_;

	return \%resource;
}

sub PackAppInfoBlock
{
	my $self = shift;

	return $self->{appinfo};
}

sub PackSortBlock
{
	my $self = shift;

	return $self->{sort};
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;

	return $record->{data};
}

sub PackResource
{
	my $self = shift;
	my $resource = shift;

	return $resource->{data};
}

1;

__END__

=head1 NAME

Palm::Raw - Handler for "raw" Palm databases

=head1 VERSION

This document describes version 1.400 of
Palm::Raw, released March 7, 2015
as part of Palm-PDB version 1.400.

=head1 SYNOPSIS

    use Palm::Raw;

For standalone programs.

    use Palm::Raw();
    @ISA = qw( Palm::Raw );

For Palm::PDB helper modules.

=head1 DESCRIPTION

The Raw PDB handler is a helper class for the Palm::PDB package. It is
intended as a generic handler for any database, or as a fallback
default handler.

If you have a standalone program and want it to be able to parse any
type of database, use

    use Palm::Raw;

If you are using Palm::Raw as a parent class for your own database
handler, use

    use Palm::Raw();

If you omit the parentheses, Palm::Raw will register itself as the
default handler for all databases, which is probably not what you
want.

The Raw handler does no processing on the database whatsoever. The
AppInfo block, sort block, records and resources are simply strings,
raw data from the database.

By default, the Raw handler only handles record databases (.pdb
files). If you want it to handle resource databases (.prc files) as
well, you need to call

    &Palm::PDB::RegisterPRCHandlers("Palm::Raw", "");

in your script.

=head2 AppInfo block

    $pdb->{appinfo}

This is a scalar, the raw data of the AppInfo block.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    @{$pdb->{records}Z<>};

Each element in the "records" array is a reference-to-hash. In
addition to the standard keys ("attributes", "category", and "id"),
this hash contains the key "data"; its value is a string with the raw
record data.

=head2 Resources

    @{$pdb->{resources}Z<>};

Each element in the "resources" array is a reference-to-hash. In
addition to the standard keys ("type" and "id"), it contains the key
"data"; its value is a string with the raw resource data.

=head1 SEE ALSO

L<Palm::PDB>

=head1 CONFIGURATION AND ENVIRONMENT

Palm::Raw requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHORS

Andrew Arensburger C<< <arensb AT ooblick.com> >>

Currently maintained by Christopher J. Madsen C<< <perl AT cjmweb.net> >>

Please report any bugs or feature requests
to S<C<< <bug-Palm-PDB AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Palm-PDB >>.

You can follow or contribute to Palm-PDB's development at
L<< https://github.com/madsen/Palm-PDB >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Andrew Arensburger.

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
