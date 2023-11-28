package Mo::utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Readonly;
use Scalar::Util qw(blessed);

Readonly::Array our @EXPORT_OK => qw(check_angle check_array check_array_object
	check_array_required check_bool check_code check_isa check_length
	check_number check_number_of_items check_regexp check_required
	check_string_begin check_strings);

our $VERSION = 0.20;

sub check_angle {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	check_number($self, $key);

	if ($self->{$key} < 0 || $self->{$key} > 360) {
		err "Parameter '".$key."' must be a number between 0 and 360.",
			'Value', $self->{$key},
		;
	}

	return;
}

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

	if (! exists $self->{$key}) {
		return;
	}

	check_array($self, $key);

	foreach my $obj (@{$self->{$key}}) {
		if (! $obj->isa($class)) {
			err $class_name." isn't '".$class."' object.";
		}
	}

	return;
}

sub check_array_required {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		err "Parameter '$key' is required.";
	}

	check_array($self, $key);

	if (! @{$self->{$key}}) {
		err "Parameter '".$key."' with array must have at least one item.";
	}

	return;
}

sub check_bool {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^\d+$/ms || ($self->{$key} != 0 && $self->{$key} != 1)) {
		err "Parameter '$key' must be a bool (0/1).",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_code {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if (ref $self->{$key} ne 'CODE') {
		err "Parameter '$key' must be a code.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_isa {
	my ($self, $key, $class) = @_;

	_check_key($self, $key) && return;

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

	_check_key($self, $key) && return;

	if (length $self->{$key} > $max_length) {
		err "Parameter '$key' has length greater than '$max_length'.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_number {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

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

sub check_regexp {
	my ($self, $key, $regexp) = @_;

	_check_key($self, $key) && return;

	if (! defined $regexp) {
		err "Parameter '$key' must have defined regexp.";
	}
	if ($self->{$key} !~ m/^$regexp/ms) {
		err "Parameter '$key' does not match the specified regular expression.",
			'String', $self->{$key},
			'Regexp', $regexp,
		;
	}

	return;
}

sub check_required {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		err "Parameter '$key' is required.";
	}

	return;
}

sub check_string_begin {
	my ($self, $key, $string_base) = @_;

	_check_key($self, $key) && return;

	if (! defined $string_base) {
		err "Parameter '$key' must have defined string base.";
	}
	if ($self->{$key} !~ m/^$string_base/) {
		err "Parameter '$key' must begin with defined string base.",
			'String', $self->{$key},
			'String base', $string_base,
		;
	}

	return;
}

sub check_strings {
	my ($self, $key, $strings_ar) = @_;

	_check_key($self, $key) && return;

	if (! defined $strings_ar) {
		err "Parameter '$key' must have strings definition.";
	}
	if (ref $strings_ar ne 'ARRAY') {
		err "Parameter '$key' must have right string definition.";
	}
	if (none { $self->{$key} eq $_ } @{$strings_ar}) {
		err "Parameter '$key' must be one of defined strings.",
			'String', $self->{$key},
			'Possible strings', (join ', ', @{$strings_ar}),
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

Mo::utils - Mo utilities.

=head1 SYNOPSIS

 use Mo::utils qw(check_angle check_array check_array_object check_array_required
         check_bool check_code check_isa check_length check_number
         check_number_of_items check_regexp check_required check_string_begin
         check_strings);

 check_angle($self, $key);
 check_array($self, $key);
 check_array_object($self, $key, $class, $class_name);
 check_array_required($self, $key);
 check_bool($self, $key);
 check_code($self, $key);
 check_isa($self, $key, $class);
 check_length($self, $key, $max_length);
 check_number($self, $key);
 check_number_of_items($self, $list_method, $item_method, $object_name, $item_name);
 check_regexp($self, $key, $regexp);
 check_required($self, $key);
 check_string_begin($self, $key, $string_base);
 check_strings($self, $key, $strings_ar);

=head1 DESCRIPTION

Mo utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_angle>

 check_angle($self, $key);

Check parameter defined by C<$key> which is number between 0 and 360.

Put error if check isn't ok.

Returns undef.

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

=head2 C<check_array_required>

 check_array_required($self, $key);

Check parameter defined by C<$key> which is reference to array for at least one
value inside.

Put error if check isn't ok.

Returns undef.

=head2 C<check_bool>

 check_bool($self, $key);

Check parameter defined by C<$key> if value is bool or not.

Put error if check isn't ok.

Returns undef.

=head2 C<check_code>

 check_code($self, $key);

Check parameter defined by C<$key> which is code reference or no.

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

=head2 C<check_regexp>

 check_regexp($self, $key, $regexp);

Check parameter defined by C<$key> via regular expression defined by c<$regexp>.

Put error if check isn't ok.

Returns undef.

=head2 C<check_required>

 check_required($self, $key);

Check required parameter defined by C<$key>.

Put error if check isn't ok.

Returns undef.

=head2 C<check_string_begin>

 check_string_begin($self, $key, $string_base);

Check parameter if it is correct string which begins with base.

Put error if string base doesn't exist.
Put error string base isn't present in string on begin.

Returns undef.

=head2 C<check_strings>

 check_strings($self, $key, $strings_ar);

Check parameter if it is correct string from strings list.

Put error if strings definition is undef or not list of strings.
Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_angle():
         From check_number():
                 Parameter '%s' must be a number.
                         Value: %s
         Parameter '%s' must be a number between 0 and 360.
                 Value: %s

 check_array():
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s

 check_array_object():
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s
         %s isn't '%s' object.

 check_array_required():
         Parameter '%s' is required.
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s
         Parameter '%s' with array must have at least one item.

 check_bool():
         Parameter '%s' must be a bool (0/1).
                 Value: %s

 check_code():
         Parameter '%s' must be a code.
                 Value: %s

 check_isa():
         Parameter '%s' must be a '%s' object.
                 Value: %s
                 Reference: %s

 check_length():
         Parameter '%s' has length greater than '%s'.
                 Value: %s

 check_number():
         Parameter '%s' must be a number.
                 Value: %s

 check_number_of_items():
         %s for %s '%s' has multiple values.

 check_regexp():
         Parameter '%s' must have defined regexp.
         Parameter '%s' does not match the specified regular expression.
                 String: %s
                 Regexp: %s

 check_required():
         Parameter '%s' is required.

 check_string_begin():
         Parameter '%s' must have defined string base.
         Parameter '%s' must begin with defined string base.
                 String: %s
                 String base: %s

 check_strings():
         Parameter '%s' must have strings definition.
         Parameter '%s' must have right string definition.
         Parameter '%s' must be one of defined strings.
                 String: %s
                 Possible strings: %s

=head1 EXAMPLE1

=for comment filename=check_angle_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_angle);

 my $self = {
         'key' => 10.1,
 };
 check_angle($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_angle_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_angle);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 400,
 };
 check_angle($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' must be a number between 0 and 360.

=head1 EXAMPLE3

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

=head1 EXAMPLE4

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

=head1 EXAMPLE5

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

=head1 EXAMPLE6

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

=head1 EXAMPLE7

=for comment filename=check_array_required_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_array_required);

 my $self = {
         'key' => ['value'],
 };
 check_array_required($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE8

=for comment filename=check_array_required_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_array_required);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => [],
 };
 check_array_required($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' with array must have at least one item.

=head1 EXAMPLE9

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

=head1 EXAMPLE10

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

=head1 EXAMPLE11

=for comment filename=check_code_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_code);
 use Test::MockObject;

 my $self = {
         'key' => sub {},
 };
 check_code($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE12

=for comment filename=check_code_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_code);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad',
 };
 check_code($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' must be a code.

=head1 EXAMPLE13

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

=head1 EXAMPLE14

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

=head1 EXAMPLE15

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

=head1 EXAMPLE16

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

=head1 EXAMPLE17

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

=head1 EXAMPLE18

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

=head1 EXAMPLE19

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

=head1 EXAMPLE20

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

=head1 EXAMPLE21

=for comment filename=check_regexp_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_regexp);

 my $self = {
         'key' => 'https://example.com/1',
 };
 check_regexp($self, 'key', qr{^https://example\.com/\d+$});

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE22

=for comment filename=check_regexp_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_regexp);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'https://example.com/bad',
 };
 check_regexp($self, 'key', qr{^https://example\.com/\d+$});

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' does not match the specified regular expression.

=head1 EXAMPLE23

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

=head1 EXAMPLE24

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

=head1 EXAMPLE25

=for comment filename=check_string_begin_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_string_begin);

 my $self = {
         'key' => 'http://example.com/foo',
 };
 check_string_begin($self, 'key', 'http://example.com/');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE26

=for comment filename=check_string_begin_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_string_begin);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'http://example/foo',
 };
 check_string_begin($self, 'key', 'http://example.com/');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' must begin with defined string base.

=head1 EXAMPLE27

=for comment filename=check_strings_ok.pl

 use strict;
 use warnings;

 use Mo::utils qw(check_strings);

 my $self = {
         'key' => 'value',
 };
 check_strings($self, 'key', ['value', 'foo']);

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE28

=for comment filename=check_strings_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils qw(check_strings);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bar',
 };
 check_strings($self, 'key', ['foo', 'value']);

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' must be one of defined strings.

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<List::Utils>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils::Language>

Mo language utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.20

=cut
