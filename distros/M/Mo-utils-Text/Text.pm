package Mo::utils::Text;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_no_null check_string_hex);

our $VERSION = 0.03;

sub check_no_null {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} =~ /\0\z/) {
		err "Parameter '".$key."' must not contain NULL on the end of string.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_string_hex {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^[a-fA-F0-9]*$/ms) {
		err "Parameter '".$key."' must contain hexadecimal string.",
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

Mo::utils::Text - Mo text utilities.

=head1 SYNOPSIS

 use Mo::utils::Text qw(check_no_null check_string_hex);

 check_no_null($self, $key);
 check_string_hex($self, $key);

=head1 DESCRIPTION

Mo utilities for checking of text values.

=head1 SUBROUTINES

=head2 C<check_no_null>

 check_no_null($self, $key);

I<Since version 0.01.>

Check parameter defined by C<$key> for a NULL character at the end of the
string.

The check is skipped if the parameter does not exist or its value is C<undef>.

Put error if check isn't ok.

Returns undef.

=head2 C<check_string_hex>

 check_string_hex($self, $key);

I<Since version 0.02.>

Check parameter defined by C<$key> for a hexadecimal string. The string may
contain characters from C<a-f>, C<A-F> and C<0-9>.

The check is skipped if the parameter does not exist or its value is C<undef>.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_no_null():
         Parameter '%s' must not contain NULL on the end of string.
                 Value: %s

 check_string_hex():
         Parameter '%s' must contain hexadecimal string.
                 Value: %s

=head1 EXAMPLES

=head2 EXAMPLE1

=for comment filename=check_no_null_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Text qw(check_no_null);

 my $self = {
         'key' => 'foo',
 };
 check_no_null($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head2 EXAMPLE2

=for comment filename=check_no_null_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Text qw(check_no_null);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => "foo\0",
 };
 check_no_null($self, 'key');

 # Output:
 # #Error [../Text.pm:19] Parameter 'key' must not contain NULL on the end of string.

=head2 EXAMPLE3

=for comment filename=check_string_hex_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Text qw(check_string_hex);

 my $self = {
         'key' => 'ABCDEF0123456789',
 };
 check_string_hex($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head2 EXAMPLE4

=for comment filename=check_string_hex_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Text qw(check_string_hex);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'foo',
 };
 check_string_hex($self, 'key');

 # Output:
 # #Error [../Text.pm:33] Parameter 'key' must contain hexadecimal string.

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Mo::utils::Array>

Mo array utilities.

=item L<Mo::utils::Hash>

Mo hash utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Text>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
