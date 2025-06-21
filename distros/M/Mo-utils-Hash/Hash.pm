package Mo::utils::Hash;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_hash);

our $VERSION = 0.01;

sub check_hash {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (ref $self->{$key} ne 'HASH') {
		err "Parameter '$key' isn't hash reference.",
			'Reference', (ref $self->{$key}),
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Hash - Mo hash utilities.

=head1 SYNOPSIS

 use Mo::utils::Hash qw(check_hash);

 check_hash($self, $key);

=head1 DESCRIPTION

Utilities for checking of hash values.

=head1 SUBROUTINES

=head2 C<check_hash>

 check_hash($self, $key);

I<Since version 0.01.>

Check parameter defined by C<$key> which is reference to hash.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_hash():
         Parameter '%s' isn't hash reference.
                 Reference: %s


=head1 EXAMPLE1

=for comment filename=check_hash_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Hash qw(check_hash);

 my $self = {
         'key' => {},
 };
 check_hash($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_hash_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Hash qw(check_hash);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad',
 };
 check_hash($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Utils.pm:?] Parameter 'key' isn't hash reference.

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo::utils>

Mo utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Hash>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
