# -*- perl -*-
#
# $Id: ListDB.pm Mon Aug  5 19:57:50 2002 $
#
# DESCRIPTION	Sub class of Palm::PDB
#               specialized for listDB by Andrew Low
#
# COPYRIGHT (c)	2002 by Rudiger Peusquens
#		All rights reserved.
#               This program is free software; you can redistribute it
#	        and/or modify it under the same terms as Perl itself.
#
# AUTHOR	Rudiger Peusquens <rudy@peusquens.net>
#
# HISTORY
# $Log$
#
use strict;

package Palm::ListDB;

use Palm::StdAppInfo();
use Palm::Raw();
use Carp qw(carp);

use vars qw( $VERSION @ISA );

@ISA = qw( Palm::StdAppInfo Palm::Raw );
$VERSION = '0.25';

sub import {
    &Palm::PDB::RegisterPDBHandlers( __PACKAGE__,
				     [ "LSdb", "DATA" ],
				     [ "LSdb", "" ] );
}

sub new {
	my $classname	= shift;
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	$self->{name} = 'ListDB';	# give it a default name
	$self->{creator} = 'LSdb';
	$self->{type} = 'DATA';
	$self->{attributes}{resource} = 0;

	# Initialize the AppInfo block
	$self->{appinfo} = {
	    writeProtect => 0,		# *ListDb's* write protection
	    lastCategory => 0xff,	# default: All
	    field1 => '',
	    field2 => '',
	};

	# Add the standard AppInfo block stuff
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	# Give the PDB a blank sort block
	$self->{sort} = undef;

	# Give the PDB an empty list of records
	$self->{records} = [];

	return $self;
}

sub ParseAppInfoBlock {
    my ($self, $data) = @_;
    my $appinfo = {};

    &Palm::StdAppInfo::parse_StdAppInfo( $appinfo, $data );

    # don't know what first 2 bytes are for
    my ($C1, $C2, $field1, $field2) = unpack 'C2a16a16', $appinfo->{other};

    $appinfo->{ writeProtect } = $C1;
    $appinfo->{ lastCategory } = $C2;

    # trim after first NUL (renaming might have left "Foo\0bar")
    $field1 =~ s/\0.*$//;
    $field2 =~ s/\0.*$//;

    $appinfo->{field1} = $field1;
    $appinfo->{field2} = $field2;

    return $appinfo;
}

sub PackAppInfoBlock {
    my $self = shift;

    my %data = ( writeProtect => 0,
		 lastCategory => 0xff ); # default 0xff : "All"

    foreach my $attr (qw(field1 field2)) {
	if ( defined $self->{appinfo}{$attr} ) {
	    $data{$attr} = $self->{appinfo}{$attr};
	} else {
	    $data{$attr} = '';
	}
    }
    if ( $self->{appinfo}{writeProtect} ) {
	$data{writeProtect} = 1;
    }
    if ( defined $self->{appinfo}{lastCategory} ) {
	$data{lastCategory} = $self->{appinfo}{lastCategory};
    }

    # Pack the non-category part of the AppInfo block
    # We need to pad the last 202 bytes.
    $self->{appinfo}{other} = pack 'C2a16a16x202',
                                   @data{qw(writeProtect lastCategory
					    field1 field2)};

    # Pack the AppInfo block
    return &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});
}


sub ParseRecord {
    my ($self, %record) = @_;

    delete $record{offset};		# This is useless

    # split into fields
    # ignore first 3 chars; they are offsets
    my ($field1, $field2, $note) = split /\0/, substr( $record{ data }, 3 );

    $record{ field1 } = $field1 unless $field1 eq '';
    $record{ field2 } = $field2 unless $field2 eq '';
    unless ( $note eq '' ) {
	# make sure we have our local newlines
	( $record{ note } = $note ) =~ s/\012/\n/g;
    }

    delete $record{ data };

    return \%record;
}

sub PackRecord {
    my ($self, $record) = @_;

    my %data = ();
    foreach my $attr (qw(field1 field2 note)) {
	if ( defined $record->{$attr} ) {
	    $data{$attr} = $record->{$attr};
	} else {
	    $data{$attr} = '';
	}
    }

    # fix note if it's a array ref
    $data{note} = join "\012", @{ $data{note} }
        if ref $data{note} eq 'ARRAY';

    $data{note} =~ s/\r?\n\r?/\012/g;	# fix PalmOS newlines

    my $data = pack('CCC',
                    3,
                    4 + length( $data{field1} ),
                    5 + length( $data{field1} )
		      + length( $data{field2} ) );
    $data .= $data{field1} . "\0";
    $data .= $data{field2} . "\0";
    $data .= $data{note} . "\0";

    return $data ;
}

sub new_Record {
    my ($self, %args) = @_;
    my $record = $self->SUPER::new_Record();

    # maybe set category
    if ( defined( my $category = $args{category} ) ) {
	my @categories = @{ $self->{appinfo}{categories} };
	my $catIndex = undef;

	if ( $category eq '' ) {
	    # empty string silently mapped to Unfiled
	    $catIndex = 0;
	} elsif ( $category =~ /\D/ ) {
	    # category by name
	    foreach my $i ( 0 .. $#categories ) {
		my $cat = $categories[$i];
		if ( defined $cat->{name} and $cat->{name} eq $category ) {
		    $catIndex = $i;
		    last;
		}
	    }
	} elsif ( $category >= 0 and $category <= $#categories ) {
	    # category by index
	    $catIndex = $category;
	}

	# fall back to "Unfiled"
	unless ( defined $catIndex ) {
	    carp "Bad category `$category'. Using `Unfiled' (0)";
	    $catIndex = 0;
	}
	$record->{category} = $catIndex;
    }

    # set field1, field2 and note
    foreach my $field (qw(field1 field2 note)) {
	if ( defined $args{$field} ) {
	    $record->{$field} = $args{$field};
	} else {
	    $record->{$field} = undef;
	}
    }

    return $record;
}

1;	# module must return success

__END__

=head1 NAME

Palm::ListDB - Handler for ListDB databases

=head1 SYNOPSIS

  use Palm::ListDB;

  $pdb = new Palm::PDB;
  $pdb->Load("my_listdb_file.pdb");


=head1 DESCRIPTION

The ListDB PDB handler is a helper class for the Palm::PDB package.
It parses ListDB databases. ListDB is a lightweight flat file database
tool for PalmOS (tm) handhelds written by Andrew Low E<lt>roo@magma.caE<gt>.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

Other fields include:

    $pdb->{appinfo}{lastUniqueID}

This is a scalar, the ID of the last category assigned. Note that this
is B<not> the index in the array of categories stored in
$pdb-E<gt>{appinfo}{categories}!

    $pdb->{appinfo}{lastCategory}

This is a scalar, the index of the selected category.
Category B<Unfiled> should always be zero. Category B<All> is 0xff.
Note that this field B<does> refer to the index in the array
of categories stored in $pdb-E<gt>{appinfo}{categories}.

    $pdb->{appinfo}{writeProtect}

This is a scalar indicating the write protection within the ListDB tool.
If set, ListDB will not allow the PDA user to edit database records.
(Of course she can always customize the database settings.)

    $pdb->{appinfo}{field1}
    $pdb->{appinfo}{field2}

These are both scalars, the names of the to fields
the database records have.

=head2 Sort block

    $pdb->{sort}

This is not defined. ListDB databases do not have a sort block.

=head2 Records

    $record = $pdb->{records}[n]

    $record->{field1}
    $record->{field1}
    $record->{note}

These are scalars, the values for the to database fields of a record and
an optional note. If a field does not exist, the corresponding field of the
record have will either not exists or contain the empty string.

    $record->{category}

This is a scalar that contains the index of the category this record
belongs to. This field refers to the index in the array of categories
stored in $pdb-E<gt>{appinfo}{categories}.

=head1 METHODS

=head2 new

    $pdb = new Palm::ListDB;

Create a new PDB, initialized with the various Palm::ListDB fields
and an empty record list.

Use this method if you want to create a ListDB PDB from scratch.

=head2 new_Record

    $record = $pdb->new_ Record( category => $cat,
				 field1   => 'field1',
				 field1   => 'field1',
				 note     => 'note' );

Creates and appends a new record to $pdb. All arguments are optional.
The value to I<category> can either be an index from the
C<$pdb-E<gt>{appinfo}{categories}> array or an existing category's name.
Empty category strings will silently be mapped the the Unfiled category.

C<new_Record> does B<not> add the new record to $pdb. For that,
you want C<$pdb-E<gt>append_Record>.

=head1 AUTHOR

Rudiger Peusquens E<lt>rudy@peusquens.netE<gt>

Palm::PDB is written by Andrew Arensburger E<lt>arensb@ooblick.comE<gt>

ListDB is written by Andrew Low E<lt>roo@magma.caE<gt>.
You can get a copy at http://www.magma.ca/~roo.

=head1 SEE ALSO

Palm::PDB(3)

Palm::StdAppInfo(3)

=cut
