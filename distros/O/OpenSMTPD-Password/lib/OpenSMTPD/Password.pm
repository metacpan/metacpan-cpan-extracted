package OpenSMTPD::Password;
use strict; use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw(
);

our @EXPORT_OK = qw(
	newhash
	checkhash
);

our $VERSION = '0.03';

my $openbsd_newhash;
eval {
	require OpenSMTPD::Password::XS;
	OpenSMTPD::Password::XS->VERSION(0.01);

	$openbsd_newhash = OpenSMTPD::Password::XS->can('newhash');
};

# thank you match::simple
eval($openbsd_newhash ? <<'XS' : <<'PP');

sub IMPLEMENTATION () { "XS" }

# if yo can do one surely you can do the other
*newhash = *OpenSMTPD::Password::XS::newhash;
*checkhash = *OpenSMTPD::Password::XS::checkhash;

XS

use Carp;
use BSD::arc4random;

sub IMPLEMENTATION () { "PP" }

tie my $rand, 'BSD::arc4random', '64';

my $SALT_LEN = 16;

my @itoa64 = qw{. / 0 1 2 3 4 5 6 7 8 9 A B C D
                E F G H I J K L M N O P Q R S T
		U V W X Y Z a b c d e f g h i j
		k l m n o p q r s t u v w x y z};

my @ids = qw{2a 6 5 3 2 1};

sub newhash {
	my ($password) = @_;

	unless (length($password)) {
		croak "newhash('password')";
	}

	if ($^O eq 'openbsd') {
		return openbsd_newhash($password);
	}

	my @salt;
	
	for (1 .. $SALT_LEN) {
		push @salt, $itoa64[$rand];
	}

	my $hash;
	my $fmt = '$%s$' . '%s' x $SALT_LEN . '$';
	foreach my $id (@ids) {
		no warnings 'redundant';
		no warnings 'uninitialized';
		my $buffer = sprintf($fmt, $id, @salt);
		$hash = crypt($password, $buffer);
		next unless (defined $hash);
		next unless (strncmp($hash, $buffer, length($buffer)));
		last;
	}

	return $hash;
}

sub checkhash {
	my ($password, $goodhash) = @_;

	unless (length($password) and length($goodhash)) {
		croak "checkhash(password, goodhash)"
	}

	if ($^O eq "openbsd") {
		return openbsd_checkhash($password, $goodhash);
	}

	my $c = crypt($password, $goodhash);

	unless (defined $c) {
		croak "crypt() failed";
	}

	return ($c eq $goodhash);
}

sub strncmp {
	my ($a, $b, $n) = @_;

	return (substr($a, 0, $n) eq substr($b, 0, $n));
}

PP

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

OpenSMTPD::Password - Perl extension for creating password hashes

=head1 SYNOPSIS

  use OpenSMTPD::Password qw/newhash checkhash/;

  my $hash = newhash($password);

  if (checkhash($password, $hash)) {
	do_cool_stuff();
  }

=head1 DESCRIPTION

Simple module for creating and verifying password hashes for OpenSMTPD.

=head2 Subroutines

=over 12

=item C<newhash>

Returns a hash of the password suitable for use with smtpd(8)

=item C<checkhash>

Returns a true value if the plaintext password matches the provided hash.

=back

=head1 ACKNOWLEDGEMENTS

Perl version of the encrypt program included with OpenSMTPD portable by Sunil Nimmagadda and Gilles Chehade.

=head2 EXPORT

None by default.

=head1 SEE ALSO

smtpd(8)

=head1 AUTHOR

Edgar Pettijohn, E<lt>edgar@pettijohn-web.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Edgar Pettijohn

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut
