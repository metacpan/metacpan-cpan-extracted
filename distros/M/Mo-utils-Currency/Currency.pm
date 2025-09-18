package Mo::utils::Currency;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Locale::Currency;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_currency_code);

our $VERSION = 0.01;

my %codes;

sub check_currency_code {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if (! keys %codes) {
		%codes = map { $_ => 1 } Locale::Currency::all_currency_codes();
	}

	if (! exists $codes{$self->{$key}}) {
		err "Parameter '$key' must be a valid currency code.",
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

Mo::utils::Currency - Mo currency utilities.

=head1 SYNOPSIS

 use Mo::utils::Currency qw(check_currency_code);

 check_currency_code($self, $key);

=head1 DESCRIPTION

Mo currency utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_currency_code>

 check_currency_code($self, $key);

Check parameter defined by C<$key> if it's currency code.
Value could be undefined.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_currency_code():
         Parameter '%s' must be a valid currency code.
               Value: %s

=head1 EXAMPLE1

=for comment filename=check_currency_code_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Currency qw(check_currency_code);

 my $self = {
         'key' => 'CZK',
 };
 check_currency_code($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_currency_code_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Currency qw(check_currency_code);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xx',
 };
 check_currency_code($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...Currency.pm:?] Parameter 'key' must be a valid currency code.

=head1 DEPENDENCIES

L<Locale::Currency>,
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

L<https://github.com/michal-josef-spacek/Mo-utils-Currency>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
