package Mo::utils::IRI;

use base qw(Exporter);
use strict;
use warnings;

use English;
use Error::Pure qw(err);
use Readonly;
use IRI;

Readonly::Array our @EXPORT_OK => qw(check_iri);

our $VERSION = 0.02;

sub check_iri {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	my $value = $self->{$key};
	my $iri = eval {
		IRI->new($value);
	};
	if ($EVAL_ERROR) {
		err "Parameter '".$key."' doesn't contain valid IRI.",
			'Value', $value,
		;
	}
	if (! $iri->can('scheme') || ! $iri->can('host') || ! $iri->scheme || ! $iri->host) {
		err "Parameter '".$key."' doesn't contain valid IRI.",
			'Value', $value,
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::IRI - Mo utilities for IRI.

=head1 SYNOPSIS

 use Mo::utils::IRI qw(check_iri);

 check_iri($self, $key);

=head1 DESCRIPTION

Mo utilities for IRI checking of data objects.

=head1 SUBROUTINES

=head2 C<check_iri>

 check_iri($self, $key);

Check parameter defined by C<$key> which is valid IRI.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_iri():
         Parameter '%s' doesn't contain valid IRI.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_iri_ok.pl

 use strict;
 use warnings;

 use Mo::utils::IRI qw(check_iri);
 use Unicode::UTF8 qw(decode_utf8);

 my $self = {
         'key' => decode_utf8('https://michal.josef.špaček'),
 };
 check_iri($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_iri_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::IRI qw(check_iri);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_iri',
 };
 check_iri($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' doesn't contain valid IRI.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<IRI>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils::CSS>

Mo CSS utilities.

=item L<Mo::utils::Date>

Mo date utilities.

=item L<Mo::utils::Language>

Mo language utilities.

=item L<Mo::utils::Email>

Mo utilities for email.

=item L<Mo::utils::URI>

Mo utilities for URI.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-IRI>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
