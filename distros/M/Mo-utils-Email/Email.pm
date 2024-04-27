package Mo::utils::Email;

use base qw(Exporter);
use strict;
use warnings;

use Email::Valid;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_email);

our $VERSION = 0.02;

sub check_email {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	my $address = Email::Valid->address($self->{$key});
	if (! $address) {
		err "Parameter '".$key."' doesn't contain valid email.",
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

Mo::utils::Email - Mo utilities for email.

=head1 SYNOPSIS

 use Mo::utils::Email qw(check_email);

 check_email($self, $key);

=head1 DESCRIPTION

Mo utilities for email checking of data objects.

=head1 SUBROUTINES

=head2 C<check_email>

 check_email($self, $key);

Check parameter defined by C<$key> which is valid email.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_email(): 
         Parameter '%s' doesn't contain valid email.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_email_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Email qw(check_email);

 my $self = {
         'key' => 'michal.josef.spacek@gmail.com',
 };
 check_email($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_email_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Email qw(check_email);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'michal.josef.špaček@gmail.com',
 };
 check_email($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..utils.pm:?] Parameter 'key' doesn't contain valid email.

=head1 DEPENDENCIES

L<Email::Valid>,
L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils::Language>

Mo language utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Email>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
