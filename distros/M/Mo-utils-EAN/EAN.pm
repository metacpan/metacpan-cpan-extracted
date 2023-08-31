package Mo::utils::EAN;

use base qw(Exporter);
use strict;
use warnings;

use Business::Barcode::EAN13 qw(valid_barcode);
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_ean);

our $VERSION = 0.01;

sub check_ean {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if (! valid_barcode($self->{$key})) {
		err "EAN code doesn't valid.";
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

Mo::utils::EAN - Mo EAN utilities.

=head1 SYNOPSIS

 use Mo::utils::EAN qw(check_ean);

 check_ean($self, $key);

=head1 DESCRIPTION

Mo EAN utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_ean>

 check_ean($self, $key);

Check parameter defined by C<$key> if it's EAN code.
Value could be undefined.

Returns undef.

=head1 ERRORS

 check_ean():
         EAN code doesn't valid.

=head1 EXAMPLE1

=for comment filename=check_ean_ok.pl

 use strict;
 use warnings;

 use Mo::utils::EAN qw(check_ean);

 my $self = {
         'key' => '8590786020177',
 };
 check_ean($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_ean_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::EAN qw(check_ean);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xx',
 };
 check_ean($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] EAN code doesn't valid.

=head1 DEPENDENCIES

L<Business::Barcode::EAN13>,
L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Mo::utils::Language>

Mo language utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-EAN>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
