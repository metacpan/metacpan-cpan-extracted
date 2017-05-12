package MooseX::Types::Buf;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

use Encode ();
use Moose::Util::TypeConstraints;
use namespace::clean;

subtype Buf => as 'Str' => where { not Encode::is_utf8($_) };

coerce Buf => from Str => via { Encode::encode_utf8($_) };
coerce Str => from Buf => via { $_ };

1;

__END__

=head1 NAME

MooseX::Types::Buf - Moose type definitions for Byte buffers

=head1 SYNOPSIS

  use Moose;
  use MooseX::Types::Buf;

  has 'raw_data' => ( is => 'rw', isa => 'Buf', coerce => 1 );

=head1 DESCRIPTION

This module lets you specify attributes as Byte buffers.

=head1 TYPES / COERCIONS

=head2 Buf

Coercions provided:

=over

=item from Str

Turns off the Unicode bit using C<Encode::encode_utf8($_)>.

If the Unicode bit is already off, the coercion is a no-op.

=item to Str

No-op; the Unicode bit is left off.

=back

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to MooseX-Types-Buf.

=cut
