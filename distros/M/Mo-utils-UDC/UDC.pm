package Mo::utils::UDC;

use base qw(Exporter);
use strict;
use warnings;

use Business::UDC;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_udc);

our $VERSION = 0.01;

sub check_udc {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	my $value = $self->{$key};
	my $udc = Business::UDC->new($value);
	if (! $udc->is_valid) {
		err "Parameter '".$key."' doesn't contain valid Universal Decimal Classification string.",
			'Value', $value,
			'Error', $udc->error,
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

Mo::utils::UDC - Mo utilities for Universal Decimal Classification.

=head1 SYNOPSIS

 use Mo::utils::UDC qw(check_udc);

 check_udc($self, $key);

=head1 DESCRIPTION

Mo Universal Decimal Classification utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_udc>

 check_udc($self, $key);

Check parameter defined by C<$key> if it's valid UDC (Universal Decimal Classification) string.
Value could be undefined or doesn't exist.

Returns undef.

=head1 ERRORS

 check_udc():
         Parameter '%s' doesn't contain valid Universal Decimal Classification string.
                 Error: %s
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_udc_ok.pl

 use strict;
 use warnings;

 use Mo::utils::UDC qw(check_udc);

 my $self = {
         'key' => '821.111(73)-31"19"',
 };
 check_udc($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_udc_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::UDC qw(check_udc);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => '821:.5',
 };
 check_udc($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...UDC.pm:?] Parameter 'key' doesn't contain valid Universal Decimal Classification string.

=head1 DEPENDENCIES

L<Business::UDC>,
L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-UDC>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
