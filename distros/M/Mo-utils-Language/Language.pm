package Mo::utils::Language;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Locale::Language;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_language check_language_639_1 check_language_639_2);

our $VERSION = 0.07;

sub check_language {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if (none { $_ eq $self->{$key} } all_language_codes()) {
		err "Parameter '".$key."' doesn't contain valid ISO 639-1 code.",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_language_639_1 {
	my ($self, $key) = @_;

	my $error = "Parameter '%s' doesn't contain valid ISO 639-1 code.";

	_check_language($self, $key, 'alpha-2', $error);

	return;
}

sub check_language_639_2 {
	my ($self, $key) = @_;

	my $error = "Parameter '%s' doesn't contain valid ISO 639-2 code.";

	_check_language($self, $key, 'alpha-3', $error);

	return;
}

sub _check_key {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		return 1;
	}

	return 0;
}

sub _check_language {
	my ($self, $key, $codeset, $error) = @_;

	_check_key($self, $key) && return;

	if (none { $_ eq $self->{$key} } all_language_codes($codeset)) {
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

Mo::utils::Language - Mo language utilities.

=head1 SYNOPSIS

 use Mo::utils::Language qw(check_language_639_1 check_language_639_2);

 check_language_639_1($self, $key);
 check_language_639_2($self, $key);

=head1 DESCRIPTION

Mo language utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_language>

 check_language($self, $key);

B<It is deprecated, use other checks.>

I<Since version 0.01. Described functionality since version 0.04.>

Check parameter defined by C<$key> if it's ISO 639-1 language code and if language exists.
Value could be undefined.

Returns undef.

=head2 C<check_language_639_1>

 check_language_639_1($self, $key);

I<Since version 0.05.>

Check parameter defined by C<$key> if it's ISO 639-1 language code and if language code exists.
Value could be undefined.

Returns undef.

=head2 C<check_language_639_2>

 check_language_639_2($self, $key);

I<Since version 0.05.>

Check parameter defined by C<$key> if it's ISO 639-2 language code and if language code exists.
Value could be undefined.

Returns undef.

=head1 ERRORS

 check_language():
         Parameter '%s' doesn't contain valid ISO 639-1 code.
                 Value: %s

 check_language_639_1():
         Parameter '%s' doesn't contain valid ISO 639-1 code.
                 Codeset: %s
                 Value: %s

 check_language_639_2():
         Parameter '%s' doesn't contain valid ISO 639-2 code.
                 Codeset: %s
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_language_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Language qw(check_language);

 my $self = {
         'key' => 'en',
 };
 check_language($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_language_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Language qw(check_language);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xx',
 };
 check_language($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 639-1 code.

=head1 EXAMPLE3

=for comment filename=check_language_639_1_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Language qw(check_language_639_1);

 my $self = {
         'key' => 'en',
 };
 check_language_639_1($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_language_639_1_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Language qw(check_language_639_1);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xx',
 };
 check_language_639_1($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 639-1 code.

=head1 EXAMPLE5

=for comment filename=check_language_639_2_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Language qw(check_language_639_2);

 my $self = {
         'key' => 'eng',
 };
 check_language_639_2($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_language_639_2_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Language qw(check_language_639_2);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xxx',
 };
 check_language_639_2($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 639-2 code.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<List::Util>,
L<Locale::Language>,
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

L<https://github.com/michal-josef-spacek/Mo-utils-Language>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
