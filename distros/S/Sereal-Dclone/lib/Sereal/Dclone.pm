package Sereal::Dclone;

use strict;
use warnings;
use Exporter 'import';
use Sereal::Decoder 'sereal_decode_with_object';
use Sereal::Encoder 'sereal_encode_with_object';

our $VERSION = '0.003';

our @EXPORT_OK = 'dclone';

my $decoder = Sereal::Decoder->new;
my $encoder = Sereal::Encoder->new({freeze_callbacks => 1, no_shared_hashkeys => 1});

sub dclone {
	my ($input, $options) = @_;
	my $enc;
	if ($options and keys %$options) {
		$enc = Sereal::Encoder->new({freeze_callbacks => 1, no_shared_hashkeys => 1, %$options});
	} else {
		$enc = $encoder;
	}
	return sereal_decode_with_object $decoder, sereal_encode_with_object $enc, $input;
}

1;

=head1 NAME

Sereal::Dclone - Deep (recursive) cloning via Sereal

=head1 SYNOPSIS

 use Sereal::Dclone 'dclone';
 my $cloned = dclone $ref;

=head1 DESCRIPTION

L<Sereal::Dclone> provides a L</"dclone"> function modeled after the function
from L<Storable>, using L<Sereal> for fast serialization.

L<Sereal> is presently known to support serializing C<SCALAR>, C<ARRAY>,
C<HASH>, C<REF>, and C<Regexp> references. L<Sereal> will also serialize and
recreate blessed objects, provided the underlying reference type is supported,
or the object class provides C<FREEZE> and C<THAW> serialization methods
(L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM">). Be cautious with cloned
objects as only the internal data structure is cloned, and the destructor will
still be called when it is destroyed.

=head1 FUNCTIONS

L<Sereal::Dclone> provides one function, which is exported on demand.

=head2 dclone

 my $cloned = dclone $ref;
 my $cloned = dclone $ref, {undef_unknown => 1, warn_unknown => 1};

Recursively clones a referenced data structure by serializing and then
deserializing it with L<Sereal>. Unlike L<Storable>'s dclone, the argument can
be any serializable scalar, not just a reference. If an unsupported value is
encountered, an exception will be thrown as it cannot be cloned.

Options can be passed to the underlying L<Sereal::Encoder> object in an
optional hash reference. To prevent exceptions when serializing unsupported
values, the C<undef_unknown> or C<stringify_unknown> options may be useful. The
C<croak_on_bless> or C<no_bless_objects> options can be used to control cloning
of objects. C<freeze_callbacks> is enabled by default.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Storable>, L<Sereal>
