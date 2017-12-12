package Store::Digest::Driver;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

use MooseX::Params::Validate ();

use MooseX::Types::Moose qw(HashRef ArrayRef Str);
use Store::Digest::Types qw(FiniteHandle DateTimeType RFC3066 DigestURI
                            ContentType Token StoreObject);

use DateTime;

requires qw(add get remove forget list stats);

# the primary digest algorithm (where the metadata is stored)
has _primary => (
    is       => 'rw',
    isa      => Token,
    required => 0,
    init_arg => 'primary',
);

# all algorithms in use
has _algorithms => (
    is       => 'rw',
    isa      => ArrayRef[Token],
    required => 0,
    init_arg => 'algorithms',
);

around add => sub {
    my $orig = shift;

    # jimmy this to accept either an object or a filehandle as a sole
    # argument
    if ($_[1] and ref $_[1]) {
    }

    my ($self, %p) = MooseX::Params::Validate::validated_hash(
        \@_,
        content  => {
            isa      => FiniteHandle,
            optional => 0,
        },
        mtime    => {
            isa      => DateTimeType,
            optional => 1,
            coerce   => 1,
            default  => DateTime->now,
        },
        type     => {
            isa      => ContentType,
            optional => 1,
        },
        language => {
            isa      => RFC3066,
            optional => 1,
        },
        charset  => {
            isa      => Token,
            optional => 1,
        },
        encoding => {
            isa      => Token,
            optional => 1,
        },
    );

    $self->$orig(%p);
};

# around get => sub {
#     my $orig = shift;
#     my ($self, $digest, $algo, $radix) =
#         MooseX::Params::Validate::pos_validated_list(
#             \@_,
#             { is => Str|DigestURI },        # digest or ni: URI
#             { is => Token, optional => 1 }, # optional algorithm
#             { is => Token, optional => 1 }, # optional radix
#         );

#     unless (Scalar::Util::blessed($digest)) {
#         $digest = URI::ni->from_digest($digest, $algo, undef, $radix);
#     }

#     #warn unpack("H*", $digest->digest);

#     $self->$orig($digest->digest, $digest->algorithm);
# };

around [qw(get remove forget)] => sub {
    my $orig = shift;
    my ($self, $digest, $algo, $radix) =
        MooseX::Params::Validate::pos_validated_list(
            \@_,
            { is => Str|DigestURI|StoreObject }, # digest, object or ni: URI
            { is => Token, optional => 1 },      # optional algorithm
            { is => Token, optional => 1 },      # optional radix
        );

    # XXX: this can be blessed as a URI::ni and still messed up
    unless (Scalar::Util::blessed($digest)) {
        if ($digest =~ /^ni:/i and (!$radix or $radix != 256)) {
            $digest = URI->new($digest);
        }
        else {
            $digest = URI::ni->from_digest($digest, $algo, undef, $radix);
        }
        #warn $digest;
    }

    $self->$orig($digest);
};

=head1 NAME

Store::Digest::Driver - Driver role for Store::Digest

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 METHODS

=head2 new

Create a new store, or bind to an existing one.

=head2 get

    my $obj = $driver->get('sha-256' => $digest);

    # or

    my $obj = $driver->get($uri); # a URI::ni object

Get an object from the store

=cut

=head2 about

Get metadata about the store itself

=cut

=head2 add

    my $obj = $driver->add(
        content  => $fh,
        language => 'en',
        mtime    => $datetime,
    );

Add an object to the store

returns a metadata object

=cut

=head2 remove

    my $obj = $driver->remove('sha-256' => $digest);

    # $obj->content will be undef and $obj->dtime will be set

Remove an object from the store, leaving its metadata

=cut

=head2 forget

    my $ok = $driver->forget('sha-256' => $digest);

Forget about an object in addition to removing it. Ordinarily,
removing an object will only delete the content and preserve the
metadata.

=cut

=head2 list

List the objects in the store

=over 4

=item algorithm

Which cryptographic algorithm to be used as a key

=item start

Starting offset, beginning with 1

=item end

Ending offset, which should be equal to or larger than the starting
offset.

=item sort

Which field to use to sort the list

=item invert

Whether or not to invert the list

=back

=cut

=head2 stats

Retrieve statistics on the store

=cut

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-store-digest at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Store-Digest>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Store::Digest::Driver

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Store-Digest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Store-Digest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Store-Digest>

=item * Search CPAN

L<http://search.cpan.org/dist/Store-Digest/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

#__PACKAGE__->meta->make_immutable;

1; # End of Store::Digest::Driver
