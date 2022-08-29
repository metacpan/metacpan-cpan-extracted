package Mo::utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Scalar::Util qw(blessed);

Readonly::Array our @EXPORT_OK => qw(check_array check_array_object check_bool
	check_isa check_length check_number check_number_of_items check_required);

our $VERSION = 0.11;

sub check_array {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (ref $self->{$key} ne 'ARRAY') {
		err "Parameter '".$key."' must be a array.",
			'Value', $self->{$key},
			'Reference', (ref $self->{$key}),
		;
	}

	return;
}

sub check_array_object {
	my ($self, $key, $class, $class_name) = @_;

	check_array($self, $key);

	foreach my $obj (@{$self->{$key}}) {
		if (! $obj->isa($class)) {
			err $class_name." isn't '".$class."' object.";
		}
	}

	return;
}

sub check_bool {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^\d+$/ms || ($self->{$key} != 0 && $self->{$key} != 1)) {
		err "Parameter '$key' must be a bool (0/1).",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_isa {
	my ($self, $key, $class) = @_;

	if (! defined $self->{$key}) {
		return;
	}

	if (! blessed($self->{$key})) {
		err "Parameter '$key' must be a '$class' object.",

			# Only, if value is scalar.
			(ref $self->{$key} eq '') ? (
				'Value', $self->{$key},
			) : (),

			# Only if value is reference.
			(ref $self->{$key} ne '') ? (
				'Reference', (ref $self->{$key}),
			) : (),
	}

	if (! $self->{$key}->isa($class)) {
		err "Parameter '$key' must be a '$class' object.",
			'Reference', (ref $self->{$key}),
		;
	}

	return;
}

sub check_length {
	my ($self, $key, $max_length) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (! defined $self->{$key}) {
		return;
	}

	if (length $self->{$key} > $max_length) {
		err "Parameter '$key' has length greater than '$max_length'.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_number {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^[-+]?\d+(\.\d+)?$/ms) {
		err "Parameter '$key' must be a number.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_number_of_items {
	my ($self, $list_method, $item_method, $object_name, $item_name) = @_;

	my $item_hr = {};
	foreach my $item (@{$self->$list_method}) {
		$item_hr->{$item->$item_method} += 1;
	}

	foreach my $item (keys %{$item_hr}) {
		if ($item_hr->{$item} > 1) {
			err "$object_name for $item_name '$item' has multiple values."
		}
	}

	return;
}

sub check_required {
	my ($self, $key) = @_;

	if (! defined $self->{$key}) {
		err "Parameter '$key' is required.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils - Mo utilities.

=head1 SYNOPSIS

 use Mo::utils qw(check_array check_array_object check_bool check_isa check_length check_number check_number_of_items check_required);

 check_array($self, $key);
 check_array_object($self, $key, $class, $class_name);
 check_bool($self, $key);
 check_isa($self, $key, $class);
 check_length($self, $key, $max_length);
 check_number($self, $key);
 check_number_of_items($self, $list_method, $item_method, $object_name, $item_name);
 check_required($self, $key);

=head1 DESCRIPTION

Mo utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_array>

 check_array($self, $key);

Check parameter defined by C<$key> which is reference to array.

Put error if check isn't ok.

Returns undef.

=head2 C<check_array_object>

 check_array_object($self, $key, $class, $class_name);

Check parameter defined by C<$key> which is reference to array with instances
of some object type (C<$class>). C<$class_name> is used to error message.

Put error if check isn't ok.

Returns undef.

=head2 C<check_bool>

 check_bool($self, $key);

Check parameter defined by C<$key> if value is bool or not.

Put error if check isn't ok.

Returns undef.

=head2 C<check_isa>

 check_isa($self, $key, $class);

Check parameter defined by C<$key> which is instance of C<$class> or no.

Put error if check isn't ok.

Returns undef.

=head2 C<check_length>

 check_length($self, $key, $max_length);

Check length of value for parameter defined by C<$key>. Maximum length is
defined by C<$max_length>.

Put error if check isn't ok.

Returns undef.

=head2 C<check_number>

 check_number($self, $key);

Check parameter defined by C<$key> which is number (positive or negative) or no.

Put error if check isn't ok.

Returns undef.

=head2 C<check_number_of_items>

 check_number_of_items($self, $list_method, $item_method, $object_name, $item_name);

Check amount of unique items defined by C<$item_method> method value.
List items via C<$list_method> and get value via C<$item_method> method.
C<$object_name> and C<$item_name> are variables for error output.

Put error if check isn't ok.

Returns undef.

=head2 C<check_required>

 check_required($self, $key);

Check required parameter defined by C<$key>.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_array():
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s

 check_array_object():
         Parameter '%s' must be a array.
         %s isn't '%s' object.

 check_bool():
         Parameter '%s' must be a bool (0/1).
                 Value: %s

 check_isa():
         Parameter '%s' must be a '%s' object.
                 Value: %s
                 Reference: %s

 check_length():
         Parameter '%s' has length greater than '%s'.
			Value: %s

 check_number():
         Parameter '%s' must a number.
                 Value: %s

 check_number_of_items():
         %s for %s '%s' has multiple values.

 check_required():
         Parameter '%s' is required.

=head1 EXAMPLE1

=for comment filename=check_array_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_array);

 my $self = {
         'key' => ['foo'],
 };
 check_array($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_array_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_array);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'foo',
 };
 check_array($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' must be a array.

=head1 EXAMPLE3

=for comment filename=check_array_object_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_array_object);
 use Test::MockObject;

 my $self = {
         'key' => [
                 Test::MockObject->new,
         ],
 };
 check_array_object($self, 'key', 'Test::MockObject', 'Value');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_array_object_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_array_object);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => [
                 'foo',
         ],
 };
 check_array_object($self, 'key', 'Test::MockObject', 'Value');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Value isn't 'Test::MockObject' object.

=head1 EXAMPLE5

=for comment filename=check_bool_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_bool);
 use Test::MockObject;

 my $self = {
         'key' => 1,
 };
 check_bool($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_bool_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_bool);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad',
 };
 check_bool($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' must be a bool (0/1).

=head1 EXAMPLE7

=for comment filename=check_isa_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_isa);
 use Test::MockObject;

 my $self = {
         'key' => Test::MockObject->new,
 };
 check_isa($self, 'key', 'Test::MockObject');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE8

=for comment filename=check_isa_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils qw(check_isa);

 my $self = {
         'key' => 'foo',
 };
 check_isa($self, 'key', 'Test::MockObject');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' must be a 'Test::MockObject' object.

=head1 EXAMPLE9

=for comment filename=check_length_ok.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils qw(check_length);

 my $self = {
         'key' => 'foo',
 };
 check_length($self, 'key', 3);

 # Print out.
 print "ok\n";

 # Output like:
 # ok

=head1 EXAMPLE10

=for comment filename=check_length_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils qw(check_length);

 my $self = {
         'key' => 'foo',
 };
 check_length($self, 'key', 2);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' has length greater than '2'.

=head1 EXAMPLE11

=for comment filename=check_number_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_number);

 my $self = {
         'key' => '10',
 };
 check_number($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE12

=for comment filename=check_number_fail.pl

 use strict;
 use warnings;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils qw(check_number);

 my $self = {
         'key' => 'foo',
 };
 check_number($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' must be a number.

=head1 EXAMPLE13

=for comment filename=check_number_of_items_ok.pl

 use strict;
 use warnings;

 use Test::MockObject;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils qw(check_number_of_items);

 # Item object #1.
 my $item1 = Test::MockObject->new;
 $item1->mock('value', sub {
 	return 'value1',
 });

 # Item object #1.
 my $item2 = Test::MockObject->new;
 $item2->mock('value', sub {
 	return 'value2',
 });

 # Tested object.
 my $self = Test::MockObject->new({
 	'key' => [],
 });
 $self->mock('list', sub {
 	return [
 		$item1,
 		$item2,
 	];
 });

 # Check number of items.
 check_number_of_items($self, 'list', 'value', 'Test', 'Item');

 # Print out.
 print "ok\n";

 # Output like:
 # ok

=head1 EXAMPLE14

=for comment filename=check_number_of_items_fail.pl

 use strict;
 use warnings;

 use Test::MockObject;

 $Error::Pure::TYPE = 'Error';

 use Mo::utils qw(check_number_of_items);

 # Item object #1.
 my $item1 = Test::MockObject->new;
 $item1->mock('value', sub {
 	return 'value1',
 });

 # Item object #2.
 my $item2 = Test::MockObject->new;
 $item2->mock('value', sub {
 	return 'value1',
 });

 # Tested object.
 my $self = Test::MockObject->new({
 	'key' => [],
 });
 $self->mock('list', sub {
 	return [
 		$item1,
 		$item2,
 	];
 });

 # Check number of items.
 check_number_of_items($self, 'list', 'value', 'Test', 'Item');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Test for Item 'value1' has multiple values.

=head1 EXAMPLE15

=for comment filename=check_required_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_required);

 my $self = {
         'key' => 'value',
 };
 check_required($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE16

=for comment filename=check_required_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_required);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => undef,
 };
 check_required($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' is required.

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2022

BSD 2-Clause License

=head1 VERSION

0.11

=cut
