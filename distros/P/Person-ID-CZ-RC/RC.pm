package Person::ID::CZ::RC;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use DateTime;
use English qw(-no_match_vars);
use Error::Pure qw(err);

# Version.
our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# RC number.
	$self->{'rc'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Check RC.
	if (! defined $self->{'rc'}) {
		err "Parameter 'rc' is required.";
	}

	# Parse.
	$self->_parse;

	# Object.
	return $self;
}

# Get alternate flag.
sub alternate {
	my $self = shift;
	return $self->{'alternate'};
}

# Get checksum.
sub checksum {
	my $self = shift;
	return $self->{'checksum'};
}

# Get day.
sub day {
	my $self = shift;
	return $self->{'day'};
}

# Get error.
sub error {
	my $self = shift;
	return $self->{'error'};
}

# Check validity.
sub is_valid {
	my $self = shift;
	return $self->{'validity'};
}

# Get month.
sub month {
	my $self = shift;
	return $self->{'month'};
}

# Get rc.
sub rc {
	my $self = shift;
	return $self->{'rc'};
}

# Get serial.
sub serial {
	my $self = shift;
	return $self->{'serial'};
}

# Get sex.
sub sex {
	my $self = shift;
	return $self->{'sex'};
}

# Get year.
sub year {
	my $self = shift;
	return $self->{'year'};
}

# Check validity.
sub _check_validity {
	my $self = shift;
	my $number = $self->{'rc'};
	$number =~ s/\///ms;
	$number = substr $number, 0, 9;
	my $checksum = $number % 11;
	if ($checksum == 10) {
		$checksum = 0;
	}
	if ($self->{'checksum'} == $checksum) {
		$self->{'validity'} = 1;
	} else {
		$self->{'error'} = "Checksum isn't valid.";
		$self->{'validity'} = 0;
	}
	return;
}

# Parse.
sub _parse {
	my $self = shift;
	if ($self->{'rc'} =~ m/^(\d\d)(\d\d)(\d\d)\/(\d\d\d)(\d)$/ms
		|| $self->{'rc'} =~ m/^(\d\d)(\d\d)(\d\d)(\d\d\d)(\d)$/ms) {

		$self->{'year'} = int(1900 + $1);
		if ($2 > 70) {
			$self->{'alternate'} = 1;
			$self->{'month'} = int($2 - 70);
			$self->{'sex'} = 'female';
		} elsif ($2 > 50) {
			$self->{'month'} = int($2 - 50);
			$self->{'sex'} = 'female';
			$self->{'alternate'} = 0;
		} elsif ($2 > 20) {
			$self->{'month'} = int($2 - 20);
			$self->{'alternate'} = 1;
			$self->{'sex'} = 'male';
		} else {
			$self->{'alternate'} = 0;
			$self->{'month'} = int($2);
			$self->{'sex'} = 'male';
		}
		$self->{'day'} = int($3);
		$self->{'serial'} = $4;
		$self->{'checksum'} = $5;

		# Check validity.
		$self->_check_validity;

	# To 31. 12.1953.
	} elsif ($self->{'rc'} =~ m/^(\d\d)(\d\d)(\d\d)\/(\d\d\d)$/ms
		|| $self->{'rc'} =~ m/^(\d\d)(\d\d)(\d\d)(\d\d\d)$/ms) {

		$self->{'year'} = int(1900 + $1);
		if ($2 > 50) {
			$self->{'month'} = int($2 - 50);
			$self->{'sex'} = 'female';
		} else {
			$self->{'month'} = int($2);
			$self->{'sex'} = 'male';
		}
		$self->{'day'} = int($3);
		$self->{'serial'} = $4;
		$self->{'checksum'} = '-';
		if ($self->{'year'} <= 1953) {
			$self->{'validity'} = 1;
		} else {
			$self->{'error'} = "Format of rc identification ".
				"hasn't checksum.";
			$self->{'validity'} = 0;
		}
		$self->{'alternate'} = 0;

	# Not valid.
	} else {
		$self->{'alternate'} = '-';
		$self->{'checksum'} = '-';
		$self->{'year'} = '-';
		$self->{'month'} = '-';
		$self->{'day'} = '-';
		$self->{'serial'} = '-';
		$self->{'sex'} = '-';
		$self->{'error'} = "Format of rc identification isn't valid.";
		$self->{'validity'} = 0;
	}

	# Check date.
	if ($self->{'validity'}) {
		eval {
			DateTime->new(
				'year' => $self->{'year'},
				'month' => $self->{'month'},
				'day' => $self->{'day'},
			);
		};
		if ($EVAL_ERROR) {
			$self->{'error'} = "Date isn't valid.";
			$self->{'validity'} = 0;
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Person::ID::CZ::RC - Perl class for Czech RC identification.

=head1 SYNOPSIS

 use Person::ID::CZ::RC;
 my $obj = Person::ID::CZ::RC->new(%params);
 my $alternate = $obj->alternate;
 my $checksum = $obj->checksum;
 my $error = $obj->error;
 my $is_valid = $obj->is_valid;
 my $month = $obj->month;
 my $rc = $obj->rc;
 my $serial = $obj->serial;
 my $sex = $obj->sex;
 my $year = $obj->year;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<rc>

 Input Czech RC identification.
 It is required.

=back

=item C<alternate()>

 Get flag, that means alternate RC identification.
 Returns 0/1.

=item C<checksum()>

 Get checksum.
 Returns string with one number character or '-'.

=item C<day()>

 Get day of birth.
 Returns string with day.

=item C<error()>

 Get error.
 Returns error string or undef.

=item C<is_valid()>

 Get flag, that means validity of rc identification.
 Returns 0/1.

=item C<month()>

 Get month of birth.
 Returns string with month.

=item C<rc()>

 Get rc identification.
 Returns string with rc identification.

=item C<serial()>

 Get serial part of rc identification.
 Returns string with three numbers.

=item C<sex()>

 Get flag, that means sex of person.
 Returns male/female string.

=item C<year()>

 Get year of birth.
 Returns string with year.

=back

=head1 ERRORS

 new():
         Parameter 'rc' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC;

 # Object.
 my $obj = Person::ID::CZ::RC->new(
         'rc' => '840501/1330',
 );

 # Get error.
 my $error = $obj->error || '-';

 # Print out.
 print "Personal number: ".$obj->rc."\n";
 print "Year: ".$obj->year."\n";
 print "Month: ".$obj->month."\n";
 print "Day: ".$obj->day."\n";
 print "Sex: ".$obj->sex."\n";
 print "Serial: ".$obj->serial."\n";
 print "Checksum: ".$obj->checksum."\n";
 print "Alternate: ".$obj->alternate."\n";
 print "Valid: ".$obj->is_valid."\n";
 print "Error: ".$error."\n";

 # Output:
 # Personal number: 840501/1330
 # Year: 1984
 # Month: 05
 # Day: 01
 # Sex: male
 # Serial: 133
 # Checksum: 0
 # Alternate: 0
 # Valid: 1
 # Error: -

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC;

 # Object.
 my $obj = Person::ID::CZ::RC->new(
         'rc' => '840230/1337',
 );

 # Get error.
 my $error = $obj->error || '-';

 # Print out.
 print "Personal number: ".$obj->rc."\n";
 print "Year: ".$obj->year."\n";
 print "Month: ".$obj->month."\n";
 print "Day: ".$obj->day."\n";
 print "Sex: ".$obj->sex."\n";
 print "Serial: ".$obj->serial."\n";
 print "Checksum: ".$obj->checksum."\n";
 print "Alternate: ".$obj->alternate."\n";
 print "Valid: ".$obj->is_valid."\n";
 print "Error: ".$error."\n";

 # Output:
 # Personal number: 840230/1337
 # Year: 1984
 # Month: 02
 # Day: 30
 # Sex: male
 # Serial: 133
 # Checksum: 7
 # Alternate: 0
 # Valid: 0
 # Error: Date isn't valid.

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC;

 # Object.
 my $obj = Person::ID::CZ::RC->new(
         'rc' => '840229/1330',
 );

 # Get error.
 my $error = $obj->error || '-';

 # Print out.
 print "Personal number: ".$obj->rc."\n";
 print "Year: ".$obj->year."\n";
 print "Month: ".$obj->month."\n";
 print "Day: ".$obj->day."\n";
 print "Sex: ".$obj->sex."\n";
 print "Serial: ".$obj->serial."\n";
 print "Checksum: ".$obj->checksum."\n";
 print "Alternate: ".$obj->alternate."\n";
 print "Valid: ".$obj->is_valid."\n";
 print "Error: ".$error."\n";

 # Output:
 # Personal number: 840229/1330
 # Year: 1984
 # Month: 02
 # Day: 29
 # Sex: male
 # Serial: 133
 # Checksum: 0
 # Alternate: 0
 # Valid: 0
 # Error: Checksum isn't valid.

=head1 EXAMPLE4

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC;

 # Object.
 my $obj = Person::ID::CZ::RC->new(
         'rc' => '840229/133',
 );

 # Get error.
 my $error = $obj->error || '-';

 # Print out.
 print "Personal number: ".$obj->rc."\n";
 print "Year: ".$obj->year."\n";
 print "Month: ".$obj->month."\n";
 print "Day: ".$obj->day."\n";
 print "Sex: ".$obj->sex."\n";
 print "Serial: ".$obj->serial."\n";
 print "Checksum: ".$obj->checksum."\n";
 print "Alternate: ".$obj->alternate."\n";
 print "Valid: ".$obj->is_valid."\n";
 print "Error: ".$error."\n";

 # Output:
 # Personal number: 840229/133
 # Year: 1984
 # Month: 02
 # Day: 29
 # Sex: male
 # Serial: 133
 # Checksum: -
 # Alternate: 0
 # Valid: 0
 # Error: Format of rc identification hasn't checksum.

=head1 EXAMPLE5

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Person::ID::CZ::RC;

 # Object.
 my $obj = Person::ID::CZ::RC->new(
         'rc' => '840229|1330',
 );

 # Get error.
 my $error = $obj->error || '-';

 # Print out.
 print "Personal number: ".$obj->rc."\n";
 print "Year: ".$obj->year."\n";
 print "Month: ".$obj->month."\n";
 print "Day: ".$obj->day."\n";
 print "Sex: ".$obj->sex."\n";
 print "Serial: ".$obj->serial."\n";
 print "Checksum: ".$obj->checksum."\n";
 print "Alternate: ".$obj->alternate."\n";
 print "Valid: ".$obj->is_valid."\n";
 print "Error: ".$error."\n";

 # Output:
 # Personal number: 840229|1330
 # Year: -
 # Month: -
 # Day: -
 # Sex: -
 # Serial: -
 # Checksum: -
 # Alternate: -
 # Valid: 0
 # Error: Format of rc identification isn't valid.

=head1 DEPENDENCIES

L<Class::Utils>,
L<DateTime>,
L<English>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Business::DK::CPR>

Danish CPR (SSN) number generator/validator

=item L<No::PersonNr>

Check Norwegian Social security numbers

=item L<Person::ID::CZ::RC::Generator>

Perl class for Czech RC identification generation.

=item L<Se::PersonNr>

Module for validating and generating a Swedish personnummer.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Person::ID::CZ::RC>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2013-2015
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
