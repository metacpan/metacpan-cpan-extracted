package Store::Digest::Types;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw(Maybe Str Int FileHandle HashRef);

use MooseX::Types -declare => [qw(DateTimeType DigestURI Seekable
                                  FiniteHandle DigestHash
                                  NonNegativeInt ContentType RFC3066
                                  MaybeDateTime MaybeToken
                                  Token File Directory StoreObject)];

use DateTime    ();
use URI::ni     ();
use Path::Class ();

=head1 NAME

Store::Digest::Types - Custom types for Store::Digest;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package Store::Digest::XYZ;

    use Moose;
    use namespace::autoclean;

    use Store::Digest::Types;

    # ... do your thing

=head1 TYPES

=head2 DateTimeType

=cut

subtype DateTimeType, as class_type('DateTime');
coerce DateTimeType,  from Int, via { DateTime->from_epoch(epoch => shift) };

subtype MaybeDateTime, as Maybe[DateTimeType];

coerce MaybeDateTime, from Maybe[Int],
    via { $_[0] ? DateTime->from_epoch(epoch => $_[0]) : undef };

=head2 DigestHash

=cut

subtype DigestURI, as class_type('URI::ni');

subtype DigestHash, as HashRef[DigestURI];

=head2 FiniteHandle

=cut

subtype Seekable,  as class_type('IO::Seekable');

subtype FiniteHandle, as FileHandle|Seekable;

=head2 File and Directory

These are just labels for L<Path::Class> objects.

=cut

subtype File,      as class_type('Path::Class::File');
subtype Directory, as class_type('Path::Class::Dir');

coerce File,      from Str, via { Path::Class::File->new(shift) };
coerce Directory, from Str, via { Path::Class::Dir->new(shift)  };

=head2 Token

A token, as described by L<RFC
2616|http://tools.ietf.org/html/rfc2616>, section 2.2.

=cut

# XXX this screws up
#my $bads = quotemeta('()<>@,;:\"/[]?={}');
#my $token = qr![^\x00-x20\x7f-\xff$bads]+!o;

# XXX this is the above, rewritten, and works.
my $token = qr/[!#\$&'*+.^_`|~0-9A-Za-z-]+/;


# that's what RFC2616 says, which would frankly make for some wackass
# "tokens".

subtype Token, as Str, where { /^$token$/o };

subtype MaybeToken, as Maybe[Token];

=head2 ContentType

A registered (or not) MIME type, in C<major/minor> notation.

=cut

subtype ContentType, as Str, where { m!^$token/$token$!o };

subtype RFC3066, as Str, where { m!^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$! };

=head2 NonNegativeInt

An integer which is zero or greater. Kinda like an unsigned int, I
suppose, except I don't care about how the underlying integer is
implemented, I just care that it's at least zero.

=cut

subtype NonNegativeInt, as Int, where { $_ >= 0 };

=head2 StoreObject

=cut

subtype StoreObject, as class_type('Store::Digest::Object');

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Store::Digest::Types
