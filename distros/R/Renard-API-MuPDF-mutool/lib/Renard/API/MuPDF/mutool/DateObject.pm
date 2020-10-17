use Renard::Incunabula::Common::Setup;
package Renard::API::MuPDF::mutool::DateObject;
# ABSTRACT: An object to store the date
$Renard::API::MuPDF::mutool::DateObject::VERSION = '0.005';
use Moo;
use Renard::Incunabula::Common::Types qw(Str HashRef InstanceOf);

use overload '""' => \&stringify, eq => \&_string_eq;

has string => (
	is => 'ro',
	isa => Str,
	required => 1,
);

has data => (
	is => 'lazy',
	isa => HashRef,
);

method _build_data() {
	my $date_string = $self->string;

	# § 3.8.3 Dates (pg. 160)
	# (D:YYYYMMDDHHmmSSOHH'mm')
	# where
	my $date_re = qr/
		(?<Prefix>D:)?
		(?<Year> \d{4} )        # YYYY is the year
		(?<Month> \d{2} )?      # MM is the month
		(?<Day> \d{2} )?        # DD is the day (01–31)
		(?<Hour> \d{2} )?       # HH is the hour (00–23)
		(?<Minute> \d{2} )?     # mm is the minute (00–59)
		(?<Second> \d{2} )?     # SS is the second (00–59)
		(?<TzOffset> [-+Z] )?   # O is the relationship of local time
		                        # to Universal Time (UT), denoted by
		                        # one of the characters +, −,
		                        # or Z (see below)
		(?<TzHourW>
			(?<TzHour> \d{2})
			'
		)? # HH followed by ' is the absolute
		   # value of the offset from UT in hours
		   # (00–23)
		(?<TzMinuteW>
			(?<TzMinute> \d{2})
			'
		)? # mm followed by ' is the absolute
		   # value of the offset from UT in
		   # minutes (00–59)
	/x;

	my $time = {};

	die "Not a date string" unless $date_string =~ $date_re;

	$time->{year} = $+{Year};
	$time->{month} = $+{Month} // '01';
	$time->{day} = $+{Day} // '01';

	$time->{hour} = $+{Hour} // '00';
	$time->{minute} = $+{Minute} // '00';
	$time->{second} = $+{Second} // '00';

	if( exists $+{TzOffset} ) {
		$time->{tz}{offset} = $+{TzOffset};
		$time->{tz}{hour} = $+{TzHour} // '00';
		$time->{tz}{minute} = $+{TzMinute} // '00';
	}

	$time;
}

method as_DateTime() :ReturnType(InstanceOf['DateTime']) {
	eval { require DateTime; 1 } or die "require DateTime";

	my $dt_hash = $self->data;
	my $dt_timezone = 'floating';
	if( exists $dt_hash->{tz} ) {
		if( $dt_hash->{tz}{offset} eq 'Z' ) {
			$dt_timezone = 'UTC'; # UTC
		} else {
			$dt_timezone = join '', (
				$dt_hash->{tz}{offset}, # ±
				$dt_hash->{tz}{hour},
				$dt_hash->{tz}{minute},
			);
		}
	}

	return DateTime->new(
		year => $dt_hash->{year},
		month => $dt_hash->{month},
		day => $dt_hash->{day},

		hour => $dt_hash->{hour},
		minute => $dt_hash->{minute},
		second => $dt_hash->{second},

		time_zone => $dt_timezone,
	);
}

method stringify() {
	my $dt_part = sprintf(
		"%4d-%02d-%02dT%02d:%02d:%02d",
			$self->data->{year},
			$self->data->{month},
			$self->data->{day},

			$self->data->{hour},
			$self->data->{minute},
			$self->data->{second},
	);

	my $tz_part = '';
	if( exists $self->data->{tz} ) {
		if( $self->data->{tz}{offset} eq 'Z' ) {
			$tz_part = 'Z'; # UTC
		} else {
			$tz_part = $self->data->{tz}{offset} # ±
				. $self->data->{tz}{hour}
				. ":"
				.  $self->data->{tz}{minute};
		}
	}


	$dt_part . $tz_part;
}

fun _string_eq($a, $b, $swap) {
	"$a" eq "$b";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::API::MuPDF::mutool::DateObject - An object to store the date

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 string

A PDF date string in C<string> which are in the form:

  D:YYYYMMDDHHmmSSOHH'mm'

=head2 data

A C<HashRef> in the form

  Dict[
    year   => Str,   # YYYY
    month  => Str,   # MM: 01-12
    day    => Str,   # DD: 01-31

    hour   => Str,   # HH: 00-23
    minute => Str,   # mm: 00-59
    second => Str,   # SS: 00-59

    tz     => Dict[
      offset => Str, # O: /[-+Z]/
      hour   => Str, # HH': 00-59
      minute => Str, # mm': 00-59
    ],
  ]

=head1 METHODS

=head2 as_DateTime

  method as_DateTime() :ReturnType(InstanceOf['DateTime'])

Returns a L<DateTime> representation of the date.

=head2 stringify

  method stringify()

Returns a C<Str> representation of the date.

This follows the ISO 8601 format of

  YYYY-MM-DDThh:mm:ss±hh:mm

which includes the timezone (either as an offset C<±hh:mm> or as C<Z> for UTC)
and using a C<T> separator for the date and time.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
