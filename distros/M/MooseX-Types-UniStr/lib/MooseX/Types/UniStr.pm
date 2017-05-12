package MooseX::Types::UniStr;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

use Encode ();
use Moose::Util::TypeConstraints;
use namespace::clean;

subtype UniStr => as 'Str' => where { Encode::is_utf8($_) };

coerce UniStr => from Str => via { Encode::decode_utf8($_) };
coerce Str => from UniStr => via { $_ };

1;

__END__

=head1 NAME

MooseX::Types::UniStr - Moose type definitions for Unicode strings

=head1 SYNOPSIS

  use Moose;
  use MooseX::Types::UniStr;

  has 'name' => ( is => 'rw', isa => 'UniStr', coerce => 1 );

=head1 DESCRIPTION

This module lets you specify attributes as Unicode strings.

=head1 TYPES / COERCIONS

=head2 UniStr

Coercions provided:

=over

=item from Str

Turns on the Unicode bit using C<Encode::decode_utf8($_)>.

If the Unicode bit is already on, the coercion is a no-op.

=item to Str

No-op; the Unicode bit is left on.

=back

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

Jeremy Stashewsky E<lt>jstash+cpan at gmail.comE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to MooseX-Types-UniStr.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jeremy Stashewsky
Copyright 2009 Socialtext Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
