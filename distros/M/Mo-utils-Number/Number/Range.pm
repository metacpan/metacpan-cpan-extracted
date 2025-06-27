package Mo::utils::Number::Range;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Mo::utils::Number qw(check_int check_natural check_number check_percent
	check_positive_natural);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_int_range check_natural_range
	check_number_range check_percent_range check_positive_natural_range);

our $VERSION = 0.04;

# ... -2, -1, 0, 1, 2, ...
sub check_int_range {
	my ($self, $key, $min, $max) = @_;

	_check_key($self, $key) && return;

	check_int($self, $key);

	if ($self->{$key} < $min || $self->{$key} > $max) {
		err "Parameter '".$key."' must be a integer between $min and $max.",
			'Value', $self->{$key},
		;
	}

	return;
}

# 0, 1, 2 ...
sub check_natural_range {
	my ($self, $key, $min, $max) = @_;

	_check_key($self, $key) && return;

	check_natural($self, $key);

	if ($self->{$key} < $min || $self->{$key} > $max) {
		err "Parameter '".$key."' must be a natural number between $min and $max.",
			'Value', $self->{$key},
		;
	}

	return;
}

# Common number.
sub check_number_range {
	my ($self, $key, $min, $max) = @_;

	_check_key($self, $key) && return;

	check_number($self, $key);

	if ($self->{$key} < $min || $self->{$key} > $max) {
		err "Parameter '".$key."' must be a number between $min and $max.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_percent_range {
	my ($self, $key, $min, $max) = @_;

	_check_key($self, $key) && return;

	check_percent($self, $key);

	my $value = $self->{$key};
	$value =~ s/%$//ms;
	if ($value < $min || $value > $max) {
		err "Parameter '".$key."' must be a percent between $min% and $max%.",
			'Value', $self->{$key},
		;
	}

	return;
}

# 1, 2 ...
sub check_positive_natural_range {
	my ($self, $key, $min, $max) = @_;

	_check_key($self, $key) && return;

	check_positive_natural($self, $key);

	if ($self->{$key} < $min || $self->{$key} > $max) {
		err "Parameter '".$key."' must be a positive natural number between $min and $max.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub _check_key {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		return 1;
	}

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Number::Range - Mo number utilities for ranges.

=head1 SYNOPSIS

 use Mo::utils::Number::Range qw(check_int_range check_natural_range check_number_range check_percent_range check_positive_natural_range);

 check_int_range($self, $key);
 check_natural_range($self, $key);
 check_number_range($self, $key);
 check_percent_range($self, $key);
 check_positive_natural_range($self, $key);

=head1 DESCRIPTION

Mo number range utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_int_range>

 check_int_range($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> if it's in range of integer numbers (... -2, -1, 0, 1, 2, ...).
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_natural_range>

 check_natural_range($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> if it's in range of natural numbers (0, 1, 2, ...).
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_number_range>

 check_number_range($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> which is in range of numbers (positive or negative) or not.
Number could be integer, float, exponencial and negative.
Implementation is via L<Scalar::Util/looks_like_number>.

Put error if check isn't ok.

Returns undef.

=head2 C<check_percent_range>

 check_percent_range($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> if it's in range of percent numbers.
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_positive_natural_range>

 check_positive_natural_range($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> if it's in range of positive natural numbers (1, 2, ...).
Value could be undefined or doesn't exist.

Returns undef.

=head1 ERRORS

 check_int_range():
         Parameter '%s' must be a integer.
                 Value: %s
         Parameter '%s' must be a integer between %s and %s.
                 Value: %s
 check_natural_range():
         Parameter '%s' must be a natural number.
                 Value: %s
         Parameter '%s' must be a natural number between %s and %s.
                 Value: %s
 check_number_range():
         Parameter '%s' must be a number.
                 Value: %s
         Parameter '%s' must be a number between %s and %s.
                 Value: %s
 check_percent_range():
         Parameter '%s' has bad percent value.
                 Value: %s
         Parameter '%s' has bad percent value (missing %).
                 Value: %s
         Parameter '%s' must be a percent between %s% and %s%.
                 Value: %s
 check_positive_natural_range():
         Parameter '%s' must be a positive natural number.
                 Value: %s
         Parameter '%s' must be a positive natural number between %s and %s.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_int_range_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number::Range qw(check_int_range);

 my $self = {
         'key' => -2,
 };
 check_int_range($self, 'key', -3, -1);

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_int_range_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Number::Range qw(check_int_range);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => -2,
 };
 check_int_range($self, 'key', 1, 2);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Range.pm:?] Parameter 'key' must be a integer between 1 and 2.

=head1 EXAMPLE3

=for comment filename=check_natural_range_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number::Range qw(check_natural_range);

 my $self = {
         'key' => 0,
 };
 check_natural_range($self, 'key', -1, 1);

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_natural_range_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Number::Range qw(check_natural_range);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 4,
 };
 check_natural_range($self, 'key', 0, 3);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Range.pm:?] Parameter 'key' must be a natural number between 0 and 3.

=head1 EXAMPLE5

=for comment filename=check_number_range_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number::Range qw(check_number_range);

 my $self = {
         'key' => '10',
 };
 check_number_range($self, 'key', 1.1, 11);

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_number_range_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils::Number::Range qw(check_number_range);

 my $self = {
         'key' => 11,
 };
 check_number_range($self, 'key', 1, 10);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Range.pm:?] Parameter 'key' must be a number between 1 and 10.

=head1 EXAMPLE7

=for comment filename=check_percent_range_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number::Range qw(check_percent_range);

 my $self = {
         'key' => '10%',
 };
 check_percent_range($self, 'key', 1.1, 11);

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE8

=for comment filename=check_percent_range_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils::Number::Range qw(check_percent_range);

 my $self = {
         'key' => 11,
 };
 check_percent_range($self, 'key', 1, 10);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Range.pm:?] Parameter 'key' has bad percent value (missing %).

=head1 EXAMPLE9

=for comment filename=check_positive_natural_range_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number::Range qw(check_positive_natural_range);

 my $self = {
         'key' => '10',
 };
 check_positive_natural_range($self, 'key', 1.1, 11);

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE10

=for comment filename=check_positive_natural_range_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils::Number::Range qw(check_positive_natural_range);

 my $self = {
         'key' => -2,
 };
 check_positive_natural_range($self, 'key', 1, 10);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Range.pm:?] Parameter 'key' must be a positive natural number.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Mo::utils::Number>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo::utils::Number>

Mo number utilities.

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Number>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
