package Palm::Datebook;
#
# ABSTRACT: Handler for Palm OS DateBook and Calendar databases
#
#	Copyright (C) 1999-2001, Andrew Arensburger.
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
		[ "date", "DATA" ],
		[ "PDat", "DATA" ],
		);
}

#'

# new
# Create a new Palm::Datebook database, and return it
sub new
{
	my $classname	= shift;
	my $params    = $_[0] || {};
	my $self	= $classname->SUPER::new(@_);
			# Create a generic PDB. No need to rebless it,
			# though.

	if ($params->{app} eq 'Calendar' || $self->{creator} eq 'PDat') {
		$self->{name} ||= "CalendarDB-PDat";	# Default
		$self->{creator} = "PDat" if $self->{creator} eq "\0\0\0\0";
	} else {
		$self->{name} ||= "DatebookDB";	# Default
		$self->{creator} = "date" if $self->{creator} eq "\0\0\0\0";
	}
	$self->{type} = "DATA" if $self->{type} eq "\0\0\0\0";
	$self->{attributes}{resource} = 0;
				# The PDB is not a resource database by
				# default, but it's worth emphasizing,
				# since DatebookDB is explicitly not a PRC.
	$self->{appinfo} = {
		start_of_week	=> 0,	# XXX - This is bogus
	};
	&Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

	$self->{sort} = undef;	# Empty sort block

	$self->{records} = [];	# Empty list of records

	return $self;
}


sub new_Record
{
	my $classname = shift;
	my $retval = $classname->SUPER::new_Record(@_);

	# By default, the new record is an untimed event that occurs
	# today.
	my @now = localtime(time);

	$retval->{day}		= $now[3];
	$retval->{month}	= $now[4] + 1;
	$retval->{year}		= $now[5] + 1900;

	$retval->{start_hour} =
	$retval->{start_minute} =
	$retval->{end_hour} =
	$retval->{end_minute} = 0xff;

	# Set the alarm. Defaults to 10 minutes before the event.
	$retval->{alarm}{advance} = 10;
	$retval->{alarm}{unit} = 0;		# Minutes

	$retval->{repeat} = {};			# No repeat
	$retval->{exceptions} = [];		# No exceptions

	$retval->{description} = "";
	$retval->{note} = undef;
	$retval->{location} = undef;

	return $retval;
}

# ParseAppInfoBlock
# Parse the AppInfo block for Datebook databases.
# There appears to be one byte of padding at the end.
sub ParseAppInfoBlock
{
	my $self = shift;
	my $data = shift;
	my $startOfWeek;
	my $i;
	my $appinfo = {};
	my $std_len;

	# Get the standard parts of the AppInfo block
	$std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

	$data = $appinfo->{other};		# Look at non-category part

	# Get the rest of the AppInfo block
	my $unpackstr =		# Argument to unpack(), since it's hairy
		"x2" .			# Padding
		"C";			# Start of week

	# XXX - This is actually "sortOrder". Dunno what that is,
	# though.
	($startOfWeek) = unpack $unpackstr, $data;

	$appinfo->{start_of_week} = $startOfWeek;

	return $appinfo;
}

sub PackAppInfoBlock
{
	my $self = shift;
	my $retval;

	# Pack the non-category part of the AppInfo block
	$self->{appinfo}{other} =
		pack("x2 C x", $self->{appinfo}{start_of_week});

	# Pack the standard part of the AppInfo block
	$retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

	return $retval;
}

sub ParseRecord
{
	my $self = shift;
	my %record = @_;
	my $data;
	my $iscal = ($self->{creator} eq 'PDat');

	delete $record{offset};	# This is useless

	# Untimed events have 0xff for $startHour, $startMinute,
	# $endHour and $endMinute.
	my $startHour;		# In 24-hour format
	my $startMinute;
	my $endHour;		# In 24-hour format
	my $endMinute;
	my $rawDate;
	my $flags;
	my $unpackstr =		# Argument to unpack().
		"C C" .		# Start hour, minute
		"C C" .		# End hour, minute
		"n" .		# Raw date
		"n";		# Flags

	$data = $record{data};
	($startHour, $startMinute, $endHour, $endMinute, $rawDate,
	 $flags) =
		unpack $unpackstr, $data;
	$data = substr $data, 8;	# Chop off the part we've just parsed

	my $year;
	my $month;
	my $day;

	$day   =  $rawDate       & 0x001f;	# 5 bits
	$month = ($rawDate >> 5) & 0x000f;	# 4 bits
	$year  = ($rawDate >> 9) & 0x007f;	# 7 bits (years since 1904)
	$year += 1904;

	$record{start_hour} = $startHour;
	$record{start_minute} = $startMinute;
	$record{end_hour} = $endHour;
	$record{end_minute} = $endMinute;
	$record{day} = $day;
	$record{month} = $month;
	$record{year} = $year;

	# Flags
	my $when_changed	    = ($flags & 0x8000 ? 1 : 0);
	my $have_alarm		    = ($flags & 0x4000 ? 1 : 0);
	my $have_repeat		    = ($flags & 0x2000 ? 1 : 0);
	my $have_note		    = ($flags & 0x1000 ? 1 : 0);
	my $have_exceptions	    = ($flags & 0x0800 ? 1 : 0);
	my $have_description	= ($flags & 0x0400 ? 1 : 0);
	my $have_location	    = (($iscal && ($flags & 0x0200)) ? 1 : 0);

	$record{other_flags} = $flags & ($iscal ? 0x01ff : 0x03ff);

	if ($when_changed)
	{
		$record{when_changed} = 1;
	}

	if ($have_alarm)
	{
		my $advance;
		my $adv_unit;

		($advance, $adv_unit) = unpack "cC", $data;
		$data = substr $data, 2;	# Chop off alarm data

		$record{alarm}{advance} = $advance;
		$record{alarm}{unit} = $adv_unit;
	}

	if ($have_repeat)
	{
		my $type;
		my $endDate;
		my $frequency;
		my $repeatOn;
		my $repeatStartOfWeek;
		my $unknown;

		($type, $endDate, $frequency, $repeatOn, $repeatStartOfWeek,
		 $unknown) =
			unpack "Cx n C C C C", $data;
		$data = substr $data, 8;	# Chop off repeat part

		$record{repeat}{type} = $type;
		$record{repeat}{unknown} = $unknown;

		if ($endDate != 0xffff)
		{
			my $endYear;
			my $endMonth;
			my $endDay;

			$endDay   =  $endDate       & 0x001f;	# 5 bits
			$endMonth = ($endDate >> 5) & 0x000f;	# 4 bits
			$endYear  = ($endDate >> 9) & 0x007f;	# 7 bits (years
			$endYear += 1904;			# since 1904)

			$record{repeat}{end_day} = $endDay;
			$record{repeat}{end_month} = $endMonth;
			$record{repeat}{end_year} = $endYear;
		}

		$record{repeat}{frequency} = $frequency;
		if ($type == 2)
		{
			# "Weekly" repeat
			my $i;
			my @days;

			# Build an array of 7 elements (one for each
			# day of the week). Each element is set iff
			# the appointment repeats on that day.
			for ($i = 0; $i < 7; $i++)
			{
				if ($repeatOn & (1 << $i))
				{
					$days[$i] = 1;
				} else {
					$days[$i] = 0;
				}
			}

			$record{repeat}{repeat_days} = [ @days ];
			$record{repeat}{start_of_week} =
				$repeatStartOfWeek;
					# I don't know what this is,
					# but the Datebook app appears
					# to perform some hairy
					# calculations involving this.
		} elsif ($type == 3) {
			# "Monthly by day" repeat
			# If "weeknum" is 5, it means the last week of
			# the month
			$record{repeat}{weeknum} = int($repeatOn / 7);
			$record{repeat}{daynum} = $repeatOn % 7;
		}
	}

	if ($have_exceptions)
	{
		my $numExceptions;
		my @exceptions;

		$numExceptions = unpack "n", $data;
		$data = substr $data, 2;
		@exceptions = unpack "n" x $numExceptions, $data;
		$data = substr $data, 2 * $numExceptions;

		my $exception;
		foreach $exception (@exceptions)
		{
			my $year;
			my $month;
			my $day;

			$day   =  $exception       & 0x001f;
			$month = ($exception >> 5) & 0x000f;
			$year  = ($exception >> 9) & 0x007f;
			$year += 1904;

			push @{$record{exceptions}},
				[ $day, $month, $year ];
		}
	}

	my @fields = split /\0/, $data, -1;

	if ($have_description)
	{
		my $description;

		$description = shift @fields;
		$record{description} = $description;
	}

	if ($have_note)
	{
		my $note;

		$note = shift @fields;
		$record{note} = $note;
	}

	if ($have_location)
	{
		my $location;

		$location = shift @fields;
		$record{location} = $location;
	}

	my $other_data= join ("\0", @fields);

	if ($iscal && length ($other_data) >= 21 && substr ($other_data, 0, 4) eq 'Bd00') {
		my $len= unpack ('n', substr ($other_data, 4, 2));
		if ($len+6 <= length ($other_data)) {
			my $tzdata= substr ($other_data, 6, $len);
			$other_data= substr ($other_data, $len+6);
			@{$record{timezone}}{qw(offset start_hour start_daynum start_weeknum start_month
											 end_hour   end_daynum   end_weeknum   end_month
									dst_adjustment country flags name)}= unpack ('n C8 n C2 a*', $tzdata);
			$record{timezone}{name} =~ s/\0$//;
			$record{timezone}{offset}=         $record{timezone}{offset}        -65536
				if $record{timezone}{offset}         > 32767;  # signed short
			$record{timezone}{dst_adjustment}= $record{timezone}{dst_adjustment}-65536
				if $record{timezone}{dst_adjustment} > 32767;  # signed short
			$record{timezone}{custom}= ($record{timezone}{flags} & 0x80) ? 1 : 0;
			$record{timezone}{flags} &= 0x7f;
			$record{timezone}{data}= $tzdata;
		}
	}

	$record{other_data}= $other_data if $other_data ne '';

	delete $record{data};

	return \%record;
}

sub PackRecord
{
	my $self = shift;
	my $record = shift;
	my $retval;

	my $rawDate;
	my $flags;
	my $iscal = ($self->{creator} eq 'PDat');

	$rawDate = ($record->{day}            & 0x001f) |
		  (($record->{month}          & 0x000f) << 5) |
		  ((($record->{year} - 1904)  & 0x007f) << 9);

	# XXX - Better to collect data first, then build flags.
	$flags = $record->{other_flags};
#  	$flags |= 0x8000 if $record->{when_changed};
#  	$flags |= 0x4000 if keys %{$record->{alarm} } ne ();
#  	$flags |= 0x2000 if keys %{$record->{repeat} } ne ();
#  	$flags |= 0x1000 if $record->{note} ne "";
#  	$flags |= 0x0800 if $#{$record->{exceptions} } >= 0;
#  	$flags |= 0x0400 if $record->{description} ne "";
#  	$flags |= 0x0200 if $iscal && $record->{location} ne "";

#  	$retval = pack "C C C C n n",
#  		$record->{start_hour},
#  		$record->{start_minute},
#  		$record->{end_hour},
#  		$record->{end_minute},
#  		$rawDate,
#  		$flags;

	if ($record->{when_changed})
	{
		$flags |= 0x8000;
	}

	my $alarm = undef;

	if (defined($record->{alarm}) && %{$record->{alarm}})
	{
		$flags |= 0x4000;
		$alarm = pack "c C",
			$record->{alarm}{advance},
			$record->{alarm}{unit};
	}

	my $repeat = undef;

	if (defined($record->{repeat}) && %{$record->{repeat}})
	{
		my $type;		# Repeat type
		my $endDate = 0xffff;	# No end date defined by default
		my $repeatOn = 0;
		my $repeatStartOfWeek = 0;

		$flags |= 0x2000;

		if (defined($record->{repeat}{end_day}))
		{
			# End date defined
			$endDate =
				($record->{repeat}{end_day} & 0x001f) |
				(($record->{repeat}{end_month}
					& 0x000f) << 5) |
				((($record->{repeat}{end_year} - 1904)
					& 0x007f) << 9);
		}

		if ($record->{repeat}{type} == 2)
		{
			# Weekly repeat
			my $i;

			$repeatOn = 0;
			for ($i = 0; $i < 7; $i++)
			{
				if ($record->{repeat}{repeat_days}[$i])
				{
					$repeatOn |= (1 << $i);
				}
			}
			$repeatStartOfWeek = $record->{repeat}{start_of_week};
		} elsif ($record->{repeat}{type} == 3)
		{
			# "Monthly by day" repeat
			my $weeknum = $record->{repeat}{weeknum};

			if ($weeknum > 5)
			{
				$weeknum = 5;
			}
			$repeatOn = ($record->{repeat}{weeknum} * 7) +
				($record->{repeat}{daynum} % 7);
		}

		$repeat = pack "Cx n C C C C",
			$record->{repeat}{type},
			$endDate,
			$record->{repeat}{frequency},
			$repeatOn,
			$repeatStartOfWeek,
			$record->{repeat}{unknown};
	}

	my $exceptions = undef;

	if (defined($record->{exceptions}) && @{$record->{exceptions}})
	{
		my $numExceptions = $#{$record->{exceptions}} + 1;
		my $exception;

		$flags |= 0x0800;

		$exceptions = pack("n", $numExceptions);

		foreach $exception (@{$record->{exceptions}})
		{
			my $day		= $exception->[0];
			my $month	= $exception->[1];
			my $year	= $exception->[2];

			$exceptions .= pack("n",
				($day & 0x001f) |
				(($month & 0x000f) << 5) |
				((($year - 1904) & 0x007f) << 9));
		}
	}

	my $description = undef;

	if (defined($record->{description}) && ($record->{description} ne ""))
	{
		$flags |= 0x0400;
		$description = $record->{description} . "\0";
	}

	my $note = undef;

	if (defined($record->{note}) && ($record->{note} ne ""))
	{
		$flags |= 0x1000;
		$note = $record->{note} . "\0";
	}

	my $location = undef;

	if ($iscal && defined($record->{location}) && ($record->{location} ne ""))
	{
		$flags |= 0x0200;
		$location = $record->{location} . "\0";
	}

	$retval = pack "C C C C n n",
		$record->{start_hour},
		$record->{start_minute},
		$record->{end_hour},
		$record->{end_minute},
		$rawDate,
		$flags;

	$retval .= $alarm	    if defined($alarm);
	$retval .= $repeat	    if defined($repeat);
	$retval .= $exceptions	if defined($exceptions);
	$retval .= $description	if defined($description);
	$retval .= $note        if defined($note);
	$retval .= $location	if defined($location);

	if ($iscal && $record->{timezone}) {
		my $tzflags= $record->{timezone}{flags};
		$tzflags |= 0x80 if $record->{timezone}{custom};
		my $tzdata = pack ('n C8 n C2',
						   @{$record->{timezone}}{qw(offset start_hour start_daynum start_weeknum start_month
															  end_hour   end_daynum   end_weeknum   end_month
													 dst_adjustment country)}, $tzflags);
		$tzdata .= "$record->{timezone}{name}\0";
		$retval .= 'Bd00';
		$retval .= pack ('n', length ($tzdata));
		$retval .= $tzdata;
	}

	$retval .= $record->{other_data} if exists $record->{other_data};

	return $retval;
}

1;

__END__

=head1 NAME

Palm::Datebook - Handler for Palm OS DateBook and Calendar databases

=head1 VERSION

This document describes version 1.400 of
Palm::Datebook, released March 14, 2015
as part of Palm version 1.400.

=head1 SYNOPSIS

    use Palm::Datebook;

=head1 DESCRIPTION

The Datebook PDB handler is a helper class for the Palm::PDB package.
It parses DateBook and Calendar databases.

=head2 AppInfo block

The AppInfo block begins with standard category support. See
L<Palm::StdAppInfo> for details.

=head2 Sort block

    $pdb->{sort}

This is a scalar, the raw data of the sort block.

=head2 Records

    $record = $pdb->{records}[N]

    $record->{day}
    $record->{month}
    $record->{year}

The day, month and year of the event. The day and month start at 1
(I<i.e.>, for January, C<< $record->{month} >> is set to 1). The year
is a four-digit number (for dates in 2001, C<< $record->{year} >> is
"2001").

For repeating events, these fields specify the first date at which the
event occurs.

    $record->{start_hour}
    $record->{start_minute}
    $record->{end_hour}
    $record->{end_minute}

The start and end times of the event. For untimed events, all of these
are 0xff.

    $record->{when_changed}

This is defined and true iff the "when info" for the record has
changed. I don't know what this means.

    $record->{alarm}{advance}
    $record->{alarm}{unit}

If the record has an alarm associated with it, the
%{$record->{alarm}Z<>} hash exists. The "unit" subfield is an integer:
0 for minutes, 1 for hours, 2 for days. The "advance" subfield
specifies how many units before the event the alarm should ring.
I<e.g.>, if "unit" is 1 and "advance" is 5, then the alarm will sound
5 hours before the event.

If C<advance> is -1, then there is no alarm associated with this event.
New records created via C<new_Record> have a 10 minute alarm set by
default. C<< undef $record->{alarm} >> to remove this alarm before writing.
An alarm icon will still show up in the Datebook if the C<alarm>
field exists, even with C<advance> set to -1.

    %{ $record->{repeat} }

This exists iff this is a repeating event.

    $record->{repeat}{type}

An integer which specifies the type of repeat:

=over 4

=item 0

no repeat.

=item 1Z<>

a daily event, one that occurs every day.

=item 2Z<>

a weekly event, one that occurs every week on the same dayZ<>(s). An
event may occur on several days every week, I<e.g.>, every Monday,
Wednesday and Friday.

For weekly events, the following fields are defined:

    @{ $record->{repeat}{repeat_days} }

This is an array of 7 elements; each element is true iff the event
occurs on the corresponding day. Element 0 is Sunday, element 1 is
Monday, and so forth.

    $record->{repeat}{start_of_week}

Day the week starts on (0 for Sunday, 1 for Monday). This affects
the phase of events that repeat every 2nd (or more) Sunday.

=item 3Z<>

a "monthly by day" event, I<e.g.>, one that occurs on the second
Friday of every month.

For "monthly by day" events, the following fields are defined:

    $record->{repeat}{weeknum}

The number of the week on which the event occurs. 0 means the first
week of the month, 1 means the second week of the month, and so forth.
A value of 5 means that the event occurs on the last week of the
month.

    $record->{repeat}{daynum}

An integer, the day of the week on which the event occurs. 0 means
Sunday, 1 means Monday, and so forth.

=item 4Z<>

a "monthly by date" event, I<e.g.>, one that occurs on the 12th of
every month.

=item 5Z<>

a yearly event, I<e.g.>, one that occurs every year on December 25th.

    $record->{repeat}{frequency}

Specifies the frequency of the repeat. For instance, if the event is a
daily one, and $record->{repeat}{frequency} is 3, then the event
occurs every 3 days.

=back

    $record->{repeat}{unknown}

I don't know what this is.

    $record->{repeat}{end_day}
    $record->{repeat}{end_month}
    $record->{repeat}{end_year}

The last day, month and year on which the event occurs.

    @{ $record->{exceptions} }
    $day   = $record->{exceptions}[N][0]
    $month = $record->{exceptions}[N][1]
    $year  = $record->{exceptions}[N][2]

If there are any exceptions to a repeating event, I<e.g.> a weekly
meeting that was cancelled one time, then the
@{$record->{exceptions}Z<>} array is defined.

Each element in this array is a reference to an anonymous array with
three elements: the day, month, and year of the exception.

    $record->{description}

A text string, the description of the event.

    $record->{location}

A text string, the location (if any) of the event (Calendar database only).

    $record->{note}

A text string, the note (if any) attached to the event.

    %{ $record->{timezone} }

This exists iff a time zone has been set for the event.

    $record->{timezone}{name}

The time zone name, I<e.g.>, "London" or "San Francisco".

    $record->{timezone}{country}

The country the time zone is in. This is an integer defined in Core/System/PalmLocale.h.

    $record->{timezone}{offset}

This gives the offset from UTC, in minutes, of the time zone.

    $record->{timezone}{dst_adjustment}

This gives the additional offset while daylight savings time is in effect.
The offset from UTC is $record->{timezone}{offset} + $record->{timezone}{dst_adjustment}
(actually only 0 or 60 are used).

    $record->{timezone}{custom}

Should indicate whether this location was created by the user, though this
always seems to be true.

    $record->{timezone}{flags}

Reserved flags.

    $record->{timezone}{start_hour}
    $record->{timezone}{start_daynum}
    $record->{timezone}{start_weeknum}
    $record->{timezone}{start_month}
    $record->{timezone}{end_hour}
    $record->{timezone}{end_daynum}
    $record->{timezone}{end_weeknum}
    $record->{timezone}{end_month}

These define the period during which daylight savings time is in effect
if $record->{timezone}{dst_adjustment} is non-zero.
daynum specifies the day of week (0=Sunday, 6=Saturday) and weeknum specifies the week of month
(0=1st, 3=4th, 4=last), analagously to the "monthly by day" repeating event.
I<e.g.>, The "London" time zone has DST starting on the last Sunday of March, which
is indicated with start_daynum=0 (Sunday), start_weeknum=4 (last week of the month),
and start_month=3 (March).

=head1 METHODS

=head2 new

  $pdb = new Palm::Datebook;
  $pdb = new Palm::Datebook({app => 'Calendar'});

Create a new PDB, initialized with the various Palm::Datebook fields
and an empty record list. Creates a Datebook PDB by default.
Specify the app parameter as 'Calendar' to create a Calendar PDB.

=head2 new_Record

  $record = $pdb->new_Record;

Creates a new Datebook record, with blank values for all of the fields.

C<new_Record> does B<not> add the new record to C<$pdb>. For that,
you want C<< $pdb->append_Record >>.

=head1 SEE ALSO

L<Palm::PDB>

L<Palm::StdAppInfo>

=head1 CONFIGURATION AND ENVIRONMENT

Palm::Datebook requires no configuration files or environment variables.

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
