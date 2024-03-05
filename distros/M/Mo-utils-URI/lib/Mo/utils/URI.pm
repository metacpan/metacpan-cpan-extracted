package Mo::utils::URI;

use base qw(Exporter);
use strict;
use warnings;

use Data::Validate::URI qw(is_uri);
use Error::Pure qw(err);
use Readonly;
use URI;

Readonly::Array our @EXPORT_OK => qw(check_location check_uri check_url
	check_urn);

our $VERSION = 0.02;

sub check_location {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	my $value = $self->{$key};
	my $uri = URI->new($value);
	if (! $uri->can('scheme') || ! $uri->can('host') || ! $uri->scheme || ! $uri->host) {
		if (! $uri->can('path_segments') || ! $uri->path_segments) {
			if (! $uri->can('query') || ! $uri->query) {
				err "Parameter '".$key."' doesn't contain valid location.",
					'Value', $value,
				;
			}
		}
	}

	return;
}

sub check_uri {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	my $value = $self->{$key};
	if (! is_uri($value)) {
		err "Parameter '".$key."' doesn't contain valid URI.",
			'Value', $value,
		;
	}

	return;
}

sub check_url {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	my $value = $self->{$key};
	my $uri = URI->new($value);
	if (! $uri->can('scheme') || ! $uri->can('host') || ! $uri->scheme || ! $uri->host) {
		err "Parameter '".$key."' doesn't contain valid URL.",
			'Value', $value,
		;
	}

	return;
}

sub check_urn {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	my $value = $self->{$key};
	my $uri = URI->new($value);
	if (! $uri->can('nid') || ! $uri->can('nss') || ! $uri->nid || ! $uri->nss) {
		err "Parameter '".$key."' doesn't contain valid URN.",
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

Mo::utils::URI - Mo utilities for URI.

=head1 SYNOPSIS

 use Mo::utils::URI qw(check_location check_uri check_url);

 check_location($self, $key);
 check_uri($self, $key);
 check_url($self, $key);
 check_urn($self, $key);

=head1 DESCRIPTION

Mo utilities for URI checking of data objects.

=head1 SUBROUTINES

=head2 C<check_location>

 check_location($self, $key);

Check parameter defined by C<$key> which is valid location. Could be URL or
absolute or relative path.

Put error if check isn't ok.

Returns undef.

=head2 C<check_uri>

 check_uri($self, $key);

Check parameter defined by C<$key> which is valid URI.

Put error if check isn't ok.

Returns undef.

=head2 C<check_url>

 check_url($self, $key);

Check parameter defined by C<$key> which is valid URL.

Put error if check isn't ok.

Returns undef.

=head2 C<check_urn>

 check_urn($self, $key);

Check parameter defined by C<$key> which is valid URN.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_location():
         Parameter '%s' doesn't contain valid location.
                 Value: %s

 check_uri():
         Parameter '%s' doesn't contain valid URI.
                 Value: %s

 check_url():
         Parameter '%s' doesn't contain valid URL.
                 Value: %s

 check_urn():
         Parameter '%s' doesn't contain valid URN.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_location_ok.pl

 use strict;
 use warnings;

 use Mo::utils::URI qw(check_location);

 my $self = {
         'key' => 'https://skim.cz',
 };
 check_location($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_location_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::URI qw(check_location);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'urn:isbn:9788072044948',
 };
 check_location($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' doesn't contain valid location.

=head1 EXAMPLE3

=for comment filename=check_uri_ok.pl

 use strict;
 use warnings;

 use Mo::utils::URI qw(check_uri);

 my $self = {
         'key' => 'https://skim.cz',
 };
 check_uri($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_uri_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::URI qw(check_uri);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_uri',
 };
 check_uri($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' doesn't contain valid URI.

=head1 EXAMPLE5

=for comment filename=check_url_ok.pl

 use strict;
 use warnings;

 use Mo::utils::URI qw(check_url);

 my $self = {
         'key' => 'https://skim.cz',
 };
 check_url($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_url_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::URI qw(check_url);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_uri',
 };
 check_uri($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' doesn't contain valid URL.

=head1 EXAMPLE7

=for comment filename=check_urn_ok.pl

 use strict;
 use warnings;

 use Mo::utils::URI qw(check_urn);

 my $self = {
         'key' => 'urn:isbn:0451450523',
 };
 check_urn($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE8

=for comment filename=check_urn_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::URI qw(check_urn);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_urn',
 };
 check_urn($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' doesn't contain valid URN.

=head1 DEPENDENCIES

L<Data::Validate::URI>,
L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<URI>.

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

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-URI>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
