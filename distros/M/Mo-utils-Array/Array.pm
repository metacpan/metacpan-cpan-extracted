package Mo::utils::Array;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Scalar::Util qw(blessed);

Readonly::Array our @EXPORT_OK => qw(check_array check_array_object
	check_array_required);

our $VERSION = 0.01;

sub check_array {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (ref $self->{$key} ne 'ARRAY') {
		my $ref = ref $self->{$key};
		err "Parameter '".$key."' must be a array.",
			'Value', $self->{$key},
			'Reference', ($ref eq '' ? 'SCALAR' : $ref),
		;
	}

	return;
}

sub check_array_object {
	my ($self, $key, $class) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	check_array($self, $key);

	foreach my $obj (@{$self->{$key}}) {
		_check_object($obj, $class,
			"Parameter '%s' with array must contain '%s' objects.",
			[$key, $class],
		);
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

# XXX Move to common utils.
sub _check_object {
	my ($value, $class, $message, $message_params_ar) = @_;

	if (! blessed($value)) {
		my $err_message = sprintf $message, @{$message_params_ar};
		err $err_message,

			# Only, if value is scalar.
			(ref $value eq '') ? (
				'Value', $value,
			) : (),

			# Only if value is reference.
			(ref $value ne '') ? (
				'Reference', (ref $value),
			) : (),
	}

	if (! $value->isa($class)) {
		my $err_message = sprintf $message, @{$message_params_ar};
		err $err_message,
			'Reference', (ref $value),
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Array - Mo array utilities.

=head1 SYNOPSIS

 use Mo::utils::Array qw(check_array check_array_object check_array_required);

 check_array($self, $key);
 check_array_object($self, $key, $class);
 check_array_required($self, $key);

=head1 DESCRIPTION

Mo array utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_array>

 check_array($self, $key);

I<Since version 0.01.>

Check parameter defined by C<$key> which is reference to array.

Put error if check isn't ok.

Returns undef.

=head2 C<check_array_object>

 check_array_object($self, $key, $class);

I<Since version 0.01.>

Check parameter defined by C<$key> which is reference to array with instances
of some object type (C<$class>).

Put error if check isn't ok.

Returns undef.

=head2 C<check_array_required>

 check_array_required($self, $key);

I<Since version 0.01.>

Check parameter defined by C<$key> which is reference to array for at least one
value inside.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_array():
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s

 check_array_object():
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s
         Parameter '%s' with array must contain '%s' objects.
                 Value: %s
                 Reference: %s

 check_array_required():
         Parameter '%s' is required.
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s
         Parameter '%s' with array must have at least one item.

=head1 EXAMPLE1

=for comment filename=check_array_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Array qw(check_array);

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
 use Mo::utils::Array qw(check_array);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'foo',
 };
 check_array($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Array.pm:?] Parameter 'key' must be a array.

=head1 EXAMPLE3

=for comment filename=check_array_object_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Array qw(check_array_object);
 use Test::MockObject;

 my $self = {
         'key' => [
                 Test::MockObject->new,
         ],
 };
 check_array_object($self, 'key', 'Test::MockObject');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_array_object_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Array qw(check_array_object);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => [
                 'foo',
         ],
 };
 check_array_object($self, 'key', 'Test::MockObject');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Array.pm:?] Parameter 'key' with array must contain 'Test::MockObject' objects.

=head1 EXAMPLE5

=for comment filename=check_array_required_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Array qw(check_array_required);

 my $self = {
         'key' => ['value'],
 };
 check_array_required($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_array_required_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Array qw(check_array_required);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => [],
 };
 check_array_required($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Array.pm:?] Parameter 'key' with array must have at least one item.

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Mo::utils::Hash>

Mo hash utilities.

=item L<Mo::utils::Language>

Mo language utilities.

=item L<Mo::utils::CSS>

Mo CSS utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Array>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
