package Person::ID::CZ::RC::Generator;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use DateTime;
use English qw(-no_match_vars);
use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Random::Day;
use Readonly;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $YEAR_FROM => 1855;
Readonly::Scalar our $YEAR_TO => 2054;

# Version.
our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Alternate flag.
	$self->{'alternate'} = undef;

	# Day.
	$self->{'day'} = undef;

	# Month.
	$self->{'month'} = undef;

	# RC number separator.
	$self->{'rc_sep'} = $EMPTY_STR;

	# Serial.
	$self->{'serial'} = undef;

	# Sex.
	$self->{'sex'} = undef;

	# Year.
	$self->{'year'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Check RC separator.
	if (none { $self->{'rc_sep'} eq $_ } ('', '/')) {
		err "Parameter 'rc_sep' has bad value.";
	}

	# Check serial part of RC.
	if (defined $self->{'serial'}) {
		if ($self->{'serial'} !~ m/^\d+$/ms) {
			err "Parameter 'serial' isn't number.";
		} elsif ($self->{'serial'} < 1) {
			err "Parameter 'serial' is lesser than 1.";
		} elsif ($self->{'serial'} > 999) {
			err "Parameter 'serial' is greater than 999.";
		}
	}

	# Check sex.
	if (defined $self->{'sex'}
		&& none { $self->{'sex'} eq $_ } qw(male female)) {

		err "Parameter 'sex' has bad value.";
	}

	# Check year.
	if (defined $self->{'year'}) {
		if ($self->{'year'} < $YEAR_FROM) {
			err "Parameter 'year' is lesser than $YEAR_FROM.";
		} elsif ($self->{'year'} > $YEAR_TO) {
			err "Parameter 'year' is greater than $YEAR_TO.";
		}
	}

	# Object.
	return $self;
}

# Get rc.
sub rc {
	my $self = shift;

	# Construct date.
	my $date = Random::Day->new(
		'day' => $self->{'day'},
		'dt_from' => DateTime->new(
			'day' => 1,
			'month' => 1,
			'year' => $YEAR_FROM,
		),
		'dt_to' => DateTime->new(
			'day' => 31,
			'month' => 12,
			'year' => $YEAR_TO,
		),
		'month' => $self->{'month'},
		'year' => $self->{'year'},
	)->get;

	# Sex.
	my $sex = $self->{'sex'};
	if (! defined $sex) {
		$sex = int(rand(2)) ? 'male' : 'female';
	}

	# Get month part.
	my $month = $date->month;
	if ($sex eq 'female') {
		$month += 50;
	}

	# Alternate number.
	if ($self->{'alternate'}) {
		$month += 20;
	}

	# Construct date part.
	my $date_part = (sprintf '%02d%02d%02d', (substr $date->year, 2), $month, $date->day);

	# Add serial.
	my $serial = $self->{'serial'};
	if (! defined $serial) {
		$serial = int(rand(1000)) + 1;
	}
	my $serial_part = sprintf '%03d', $serial;

	# Add checksum.
	if ($date->year > 1954) {
		$serial_part = $self->_checksum($date_part, $serial_part);
	}

	# Construct rc.
	my $rc = $date_part.$self->{'rc_sep'}.$serial_part;

	# Return $rc.
	return $rc;
}

# Compute checksum.
sub _checksum {
	my ($self, $date_part, $serial_part) = @_;
	my $num = $date_part.$serial_part;
	my $num_11 = $num % 11;
	my $checksum;
	if ($num_11 == 10) {
		$checksum = 0;
	} else {
		$checksum = $num_11;
	}
	return $serial_part.$checksum;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Person::ID::CZ::RC::Generator - Perl class for Czech RC identification generation.

=head1 SYNOPSIS

 use Person::ID::CZ::RC::Generator;
 my $obj = Person::ID::CZ::RC::Generator->new(%params);
 my $rc = $obj->rc;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<alternate>

 Alternate flag.
 Default value is undef.

=item * C<day>

 Day.
 Default value is undef.

=item * C<month>

 Month.
 Default value is undef.

=item * C<rc_sep>

 RC number separator.
 Possible values are:
 - empty string
 - /
 Default value is empty string.

=item * C<serial>

 Serial number from 1 to 999.
 Default value is undef.

=item * C<sex>

 Sex.
 Possible values are:
 - male
 - female
 Default value is undef.

=item * C<year>

 Year.
 Possible values are between 1946 and 2054.
 Default value is undef.

=back

=item C<rc()>

 Get rc identification.
 Returns string with rc identification.

=back

=head1 ERRORS

 new():
         Parameter 'rc_sep' has bad value.
         Parameter 'serial' is greater than 999.
         Parameter 'serial' is lesser than 1.
         Parameter 'serial' isn't number.
         Parameter 'sex' has bad value.
         Parameter 'year' is greater than 2054.
         Parameter 'year' is lesser than 1855.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC::Generator;

 # Object.
 my $obj = Person::ID::CZ::RC::Generator->new(
         'day' => 1,
         'month' => 5,
         'rc_sep' => '/',
         'serial' => 133,
         'sex' => 'male',
         'year' => 1984,
 );

 # Print out.
 print "Personal number: ".$obj->rc."\n";

 # Output:
 # Personal number: 840501/1330

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC::Generator;

 # Object.
 my $obj = Person::ID::CZ::RC::Generator->new(
         'day' => 1,
         'month' => 5,
         'rc_sep' => '/',
         'serial' => 133,
         'sex' => 'male',
         'year' => 1952,
 );

 # Print out.
 print "Personal number: ".$obj->rc."\n";

 # Output:
 # Personal number: 520501/133

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC::Generator;

 # Object.
 my $obj = Person::ID::CZ::RC::Generator->new(
         'rc_sep' => '/',
 );

 # Print out.
 print "Personal number: ".$obj->rc."\n";

 # Output like:
 # Personal number: qr{\d\d\d\d\d\d\/\d\d\d\d?}

=head1 DEPENDENCIES

L<Class::Utils>,
L<DateTime>,
L<English>,
L<Error::Pure>,
L<List::MoreUtils>,
L<Random::Day>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Business::DK::CPR>

Danish CPR (SSN) number generator/validator

=item L<No::PersonNr>

Check Norwegian Social security numbers

=item L<Person::ID::CZ::RC>

Perl class for Czech RC identification.

=item L<Se::PersonNr>

Module for validating and generating a Swedish personnummer.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Person::ID::CZ::RC::Generator>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2013-2015
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
