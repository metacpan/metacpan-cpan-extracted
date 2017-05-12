# Palm::DiabetesPilot.pm
#
# Palm::PDB helper for handling Diabetes Pilot databases
#
# Copyright (C) 2003 Christophe Beauregard
#
# $Id: DiabetesPilot.pm,v 1.8 2004/09/08 23:23:00 cpb Exp $

use strict;

package Palm::DiabetesPilot;

use Palm::PDB;
use Palm::Raw();
use Palm::StdAppInfo();
use vars qw( $VERSION @ISA );

$VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( Palm::StdAppInfo Palm::Raw );

=head1 NAME

Palm::DiabetesPilot - Handler for Diabetes Pilot databases

=head1 SYNOPSIS

use Palm::DiabetesPilot;

=head1 DESCRIPTION

Helper for reading Diabetes Pilot (www.diabetespilot.com) databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.  Diabetes Pilot doesn't have any
application-specific extensions here.

=head2 Records

	$record = $pdb->{records}{$i}

	$record->{year}
	$record->{month}
	$record->{day}
	$record->{hour}
	$record->{minute}

The time of the record entry.

	$record->{type}

The type of record. This will be one of C<gluc>, C<meal>, C<med>,
C<exer>, or C<note>.

	$record->{quantity}

The quantity associated with the record. For a glucose reading, this is the
level (in the appropriate units). For a meal, it's a carb value. For the
medication, it's whatever units are appropriate. For the exercise, it's
associated with the specific exercise selection.

	$record->{note}

Any record type can have a note associated with it.

	$record->{med}

In a C<med> record, this indicates the type of medication taken. Meds are
just text strings.

	$record->{exer}

In an C<exercise> record, this is a comment describing the type of
exercise and the quantity associated with it.

	$record->{items}

In a C<meal> record, this is a reference to an array of individual meal
items. Each item is a hash reference containing the following fields:
C<servings>, C<carbs>, C<fat>, C<protein>, C<fiber>, C<calories>, C<name>.
C<name> is the textual description of the item and also generally includes
the serving size and units.
	
=cut
#'

sub import
{
	&Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ "DGA1", "DATA" ], );
}

sub new
{
	die( "Palm::DiabetesPilot does not support new databases" );
}

sub new_Record
{
	die( "Palm::DiabetesPilot does not support new records" );
}

sub ParseAppInfoBlock($$)
{
	my ($self,$data) = @_;
	$self->{'appinfo'} = {};

	&Palm::StdAppInfo::parse_StdAppInfo($self->{'appinfo'}, $data);

	return $self->{'appinfo'};
}

sub PackAppInfoBlock
{
	die( "Palm::DiabetesPilot does not support writing appinfo" );
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;

	# catch empty records
	return \%record unless length $record{'data'} >= 20;

	my ($sec,$min,$hour,$day,$mon,$year,$type,$quantity,$data)
		= unpack( "nnnnnn x2 C x3 n a*", $record{'data'} );

	# quantities are always multiplied by ten for storage
	$quantity /= 10.0;

	# notes are NUL terminated and follow quantities
	my $note = (split /\0/, $data)[0];
	chomp($note);

	$record{'second'} = $sec;
	$record{'minute'} = $min;
	$record{'hour'} = $hour;
	$record{'day'} = $day;
	$record{'month'} = $mon;
	$record{'year'} = $year;
	$record{'quantity'} = $quantity;
	$record{'note'} = $note if $note ne "";

	# type-specific structures seem to be appended, word aligned, right after
	# the note ends. We've already extracted what we need from $data.
	my $nl = length($note)+1;
	$data = substr( $data, $nl + $nl % 2 );

	# type is a bitmask.
	if( $type & 0x1 ) {
		$record{'type'} = 'meal';

		# we think it's the size of the data section in bytes, although it
		# doesn't always jive.
		my ($dlen,$items) = unpack( "n n", $data );
		my @servings = unpack( "n$items", substr($data,4) );
		@servings = map { $_/10.0 } @servings;

		# skip the 4+2*items header
		$data = substr( $data, 4+($items*2) );

		my @items = ();

		for( my ($i,$pos) = (0,0); $i < $items; $i ++ ) {
			# records are 34 bytes, followed by a text description. There's
			# a lot in the records we don't know about, although some will
			# probably be food classification (as per the database), some
			# might be extended nutritional info, etc. None exactly relevant
			# at the moment.
			# there's some really odd record alignment, too. All records are
			# word aligned, but there's always going to be at least one
			# non-data byte between consecutive records (the NUL string
			# terminator counts as data).

			my $item = substr( $data, $pos, 34 );
			last if length $item < 34;
			my ($calories,$fat,$carbs,$fiber,$protein)
				= unpack( "x6 n x2 n x6 n n x2 n x8", $item );
			$fat /= 10.0;
			$carbs /= 10.0;
			$fiber /= 10.0;
			$protein /= 10.0;
			$calories /= 10.0;

			my $name = substr( $data, 34 + $pos );
			$name = (split /\0/, $name)[0];

			push @items,
				{ 'servings' => $servings[$i],
				'carbs' => $carbs,
				'fat' => $fat,
				'protein' => $protein,
				'fiber' => $fiber,
				'calories' => $calories,
				'name' => $name,
				};

			my $nl = length($name)+1;

			# word aligned, but if the string ends on a word boundary the
			# following word is skipped.
			$nl += ($nl%2) ? 1 : 2;

			$pos += 34 + $nl;

		}

		$record{'items'} = \@items;

	} elsif( $type & 0x2 ) {
		$record{'type'} = 'gluc';
	} elsif( $type & 0x4 ) {
		# dword length indicates the med string
		$record{'med'} = substr( $data, 2, unpack( "n", $data )-1 );
		chomp( $record{'med'} );

		$record{'type'} = 'med';
	} elsif( $type & 0x8 ) {
		$record{'exercise'} = substr( $data, 2, unpack( "n", $data )-1 );
		chomp( $record{'exercise'} );

		$record{'type'} = 'exer';
	} elsif( $type & 0x10 ) {
		delete $record{'quantity'};	# notes don't have valid quantities

		$record{'type'} = 'note';
	} else {
		return undef;
	}

	delete $record{'offset'};
	delete $record{'data'};

	return \%record;
}

sub PackRecord
{
	die( "Palm::DiabetesPilot does not support writing records" );
}

1;
__END__

=head1 BUGS

Not strictly a bug, but writing databases is unsupported. This is an incomplete
reverse-engineering of medical journalling software. As such, it's unlikely
that we'll ever handle writing.

=head1 AUTHOR

Christophe Beauregard E<lt>cpb@cpan.orgE<gt>

=head1 SEE ALSO

Palm::PDB(3)

Palm::StdAppInfo(3)

=cut
