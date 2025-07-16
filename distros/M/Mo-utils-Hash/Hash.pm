package Mo::utils::Hash;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_hash check_hash_keys);

our $VERSION = 0.02;

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

sub check_hash_keys {
	my ($self, $key, @hash_keys) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (! @hash_keys) {
		err "Expected keys doesn't exists.";
	}

	my $hash = $self->{$key};
	my $printable_keys = '';
	foreach my $hash_key (@hash_keys) {
		if ($printable_keys) {
			$printable_keys .= '.';
		}
		$printable_keys .= $hash_key;
		if (ref $hash ne 'HASH' || ! exists $hash->{$hash_key}) {
			err "Parameter '$key' doesn't contain expected keys.",
				'Keys', $printable_keys,
			;
		}
		$hash = $hash->{$hash_key};
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
 check_hash_keys($self, $key, @keys);

=head1 DESCRIPTION

Utilities for checking of hash values.

=head1 SUBROUTINES

=head2 C<check_hash>

 check_hash($self, $key);

I<Since version 0.01.>

Check parameter defined by C<$key> which is reference to hash.

Put error if check isn't ok.

Returns undef.

=head2 C<check_hash_keys>

 check_hash_keys($self, $key, @keys);

I<Since version 0.02.>

Check parameter defined by C<$key> which contain hash keys defined by C<@keys>.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_hash():
         Parameter '%s' isn't hash reference.
                 Reference: %s

 check_hash_keys():
         Expected keys doesn't exists.
         Parameter '%s' doesn't contain expected keys.
                 Keys: %s


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
 # #Error [..Hash.pm:?] Parameter 'key' isn't hash reference.

=head1 EXAMPLE3

=for comment filename=check_hash_keys_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Hash 0.02 qw(check_hash_keys);

 my $self = {
         'key' => {
                 'first' => {
                        'second' => 'value',
                 },
         },
 };
 check_hash_keys($self, 'key', 'first', 'second');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_hash_keys_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Hash 0.02 qw(check_hash_keys);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => {
                 'first' => {
                         'second_typo' => 'value',
                 }
         },
 };
 check_hash_keys($self, 'key', 'first', 'second');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Hash.pm:?] Parameter 'key' doesn't contain expected keys.

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

0.02

=cut
