package Mo::utils::TimeZone;

use base qw(Exporter);
use strict;
use warnings;

use DateTime::TimeZone;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_timezone_iana);

our $VERSION = 0.03;

sub check_timezone_iana {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if (! DateTime::TimeZone->is_valid_name($self->{$key})) {
		err "Parameter '".$key."' doesn't contain valid IANA timezone code.",
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

Mo::utils::TimeZone - Mo timezone utilities.

=head1 SYNOPSIS

 use Mo::utils::TimeZone qw(check_timezone_iana);

 check_timezone_iana($self, $key);

=head1 DESCRIPTION

Mo timezone utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_timezone_iana>

 check_timezone_iana($self, $key);

Check parameter defined by C<$key> if it's valid IANA timezone code.
Value could be undefined.

Returns undef.

=head1 ERRORS

 check_timezone_iana():
         Parameter '%s' doesn't contain valid IANA timezone code.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_timezone_iana_ok.pl

 use strict;
 use warnings;

 use Mo::utils::TimeZone qw(check_timezone_iana);

 my $self = {
         'key' => 'Europe/Prague',
 };
 check_timezone_iana($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_timezone_iana_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::TimeZone qw(check_timezone_iana);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'BAD',
 };
 check_timezone_iana($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...utils.pm:?] Parameter 'key' doesn't contain valid IANA timezone code.

=head1 DEPENDENCIES

L<DateTime::TimeZone>,
L<Error::Pure>,
L<Exporter>,
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

L<https://github.com/michal-josef-spacek/Mo-utils-TimeZone>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
