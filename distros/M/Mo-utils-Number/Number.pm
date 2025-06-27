package Mo::utils::Number;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Mo::utils::Number::Utils qw(sub_check_percent);
use Readonly;
use Scalar::Util qw(looks_like_number);

Readonly::Array our @EXPORT_OK => qw(check_int check_natural check_number
	check_percent check_positive_natural);

our $VERSION = 0.04;

# ... -2, -1, 0, 1, 2, ...
sub check_int {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^\-?\d+$/ms) {
		err "Parameter '$key' must be a integer.",
			'Value', $self->{$key},
		;
	}

	return;
}

# 0, 1, 2 ...
sub check_natural {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^\d+$/ms) {
		err "Parameter '$key' must be a natural number.",
			'Value', $self->{$key},
		;
	}

	return;
}

# Common number.
sub check_number {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if (! looks_like_number($self->{$key})) {
		err "Parameter '$key' must be a number.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_percent {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	sub_check_percent($self->{$key}, $key, 'percent value');

	return;
}

# 1, 2 ...
sub check_positive_natural {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^\d+$/ms || $self->{$key} == 0) {
		err "Parameter '$key' must be a positive natural number.",
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

Mo::utils::Number - Mo number utilities.

=head1 SYNOPSIS

 use Mo::utils::Number qw(check_int check_natural check_number check_percent check_positive_natural);

 check_int($self, $key);
 check_natural($self, $key);
 check_number($self, $key);
 check_percent($self, $key);
 check_positive_natural($self, $key);

=head1 DESCRIPTION

Mo number utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_int>

 check_int($self, $key);

Check parameter defined by C<$key> if it's number integer (... -2, -1, 0, 1, 2, ...).
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_natural>

 check_natural($self, $key);

Check parameter defined by C<$key> if it's number a natural number (0, 1, 2, ...).
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_number>

 check_number($self, $key);

I<Since version 0.02.>

Check parameter defined by C<$key> which is number (positive or negative) or not.
Number could be integer, float, exponencial and negative.
Implementation is via L<Scalar::Util/looks_like_number>.

Put error if check isn't ok.

Returns undef.

=head2 C<check_percent>

 check_percent($self, $key);

Check parameter defined by C<$key> if it's number a percent.
Value could be undefined or doesn't exist.

Returns undef.

=head2 C<check_positive_natural>

 check_positive_natural($self, $key);

Check parameter defined by C<$key> if it's number a positive natural number (1, 2, ...).
Value could be undefined or doesn't exist.

Returns undef.

=head1 ERRORS

 check_int():
         Parameter '%s' must be a integer.
                 Value: %s
 check_natural():
         Parameter '%s' must be a natural number.
                 Value: %s
 check_number():
         Parameter '%s' must be a number.
                 Value: %s
 check_percent():
         Parameter '%s' has bad percent value.
                 Value: %s
         Parameter '%s' has bad percent value (missing %).
                 Value: %s
 check_positive_natural():
         Parameter '%s' must be a positive natural number.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_int_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number qw(check_int);

 my $self = {
         'key' => -2,
 };
 check_int($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_int_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Number qw(check_int);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 1.2,
 };
 check_int($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Number.pm:?] Parameter 'key' must be a integer.

=head1 EXAMPLE3

=for comment filename=check_natural_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number qw(check_natural);

 my $self = {
         'key' => 0,
 };
 check_natural($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_natural_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Number qw(check_natural);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => -2,
 };
 check_natural($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Number.pm:?] Parameter 'key' must be a natural number.

=head1 EXAMPLE5

=for comment filename=check_number_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number qw(check_number);

 my $self = {
         'key' => '10',
 };
 check_number($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_number_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils::Number qw(check_number);

 my $self = {
         'key' => 'foo',
 };
 check_number($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Number.pm:?] Parameter 'key' must be a number.

=head1 EXAMPLE7

=for comment filename=check_percent_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number qw(check_percent);

 my $self = {
         'key' => '10%',
 };
 check_percent($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE8

=for comment filename=check_percent_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils::Number qw(check_percent);

 my $self = {
         'key' => 'foo',
 };
 check_percent($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Number.pm:?] Parameter 'key' has bad percent value.

=head1 EXAMPLE9

=for comment filename=check_positive_natural_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Number qw(check_positive_natural);

 my $self = {
         'key' => '3',
 };
 check_positive_natural($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE10

=for comment filename=check_positive_natural_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils::Number qw(check_positive_natural);

 my $self = {
         'key' => -1,
 };
 check_positive_natural($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Number.pm:?] Parameter 'key' must be a positive natural number.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Mo::utils::Number::Range>

Mo number utilities for ranges.

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

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
