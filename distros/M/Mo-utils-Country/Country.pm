package Mo::utils::Country;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Locale::Country;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_country_3166_1_alpha_2 check_country_3166_1_alpha_3);

our $VERSION = 0.02;

sub check_country_3166_1_alpha_2 {
	my ($self, $key) = @_;

	my $error = "Parameter '%s' doesn't contain valid ISO 3166-1 alpha-2 code.";

	_check_country($self, $key, LOCALE_CODE_ALPHA_2, $error);

	return;
}

sub check_country_3166_1_alpha_3 {
	my ($self, $key) = @_;

	my $error = "Parameter '%s' doesn't contain valid ISO 3166-1 alpha-3 code.";

	_check_country($self, $key, LOCALE_CODE_ALPHA_3, $error);

	return;
}

sub _check_key {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		return 1;
	}

	return 0;
}

sub _check_country {
	my ($self, $key, $codeset, $error) = @_;

	_check_key($self, $key) && return;

	if (none { $_ eq lc($self->{$key}) } all_country_codes($codeset)) {
		my $err = sprintf($error, $key);
		err $err,
			'Codeset', $codeset,
			'Value', $self->{$key},
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Country - Mo country utilities.

=head1 SYNOPSIS

 use Mo::utils::Country qw(check_country_3166_1_alpha_2 check_country_3166_1_alpha_3);

 check_country_3166_1_alpha_2($self, $key);
 check_country_3166_1_alpha_3($self, $key);

=head1 DESCRIPTION

Mo country utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_country_3166_1_alpha_2>

 check_country_3166_1_alpha_2($self, $key);

Check parameter defined by C<$key> if it's ISO 3166-1 alpha-2 country code and if country code exists.
Value could be undefined.

Returns undef.

=head2 C<check_country_3166_1_alpha_3>

 check_country_3166_1_alpha_3($self, $key);

Check parameter defined by C<$key> if it's ISO 3166-1 alpha-3 country code and if country code exists.
Value could be undefined.

Returns undef.

=head1 ERRORS

 check_country_3166_1_alpha_2():
         Parameter '%s' doesn't contain valid ISO 639-1 code.
                 Codeset: %s
                 Value: %s

 check_country_3166_1_alpha_3():
         Parameter '%s' doesn't contain valid ISO 639-2 code.
                 Codeset: %s
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_country_3166_1_alpha_2_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Country qw(check_country_3166_1_alpha_2);

 my $self = {
         'key' => 'cz',
 };
 check_country_3166_1_alpha_2($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_country_3166_1_alpha_2_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Country qw(check_country_3166_1_alpha_2);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xx',
 };
 check_country_3166_1_alpha_2($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 3166-1 alpha-2 code.

=head1 EXAMPLE3

=for comment filename=check_country_3166_1_alpha_3_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Country qw(check_country_3166_1_alpha_3);

 my $self = {
         'key' => 'cze',
 };
 check_country_3166_1_alpha_3($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_country_3166_1_alpha_3_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Country qw(check_country_3166_1_alpha_3);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xxx',
 };
 check_country_3166_1_alpha_3($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 3166-2 alpha-3 code.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<List::Util>,
L<Locale::Country>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Country>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
