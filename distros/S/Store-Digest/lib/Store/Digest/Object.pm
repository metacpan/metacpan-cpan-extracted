package Store::Digest::Object;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Carp 'verbose';

use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw(Maybe Int CodeRef);

use Store::Digest::Types qw(FiniteHandle DigestHash NonNegativeInt
                            ContentType Token DateTimeType MaybeDateTime
                            MaybeToken);

# flags
use constant TYPE_CHECKED     => 1 << 0;
use constant TYPE_VALID       => 1 << 1;
use constant CHARSET_CHECKED  => 1 << 2;
use constant CHARSET_VALID    => 1 << 3;
use constant ENCODING_CHECKED => 1 << 4;
use constant ENCODING_VALID   => 1 << 5;
use constant SYNTAX_CHECKED   => 1 << 6;
use constant SYNTAX_VALID     => 1 << 7;

=head1 NAME

Store::Digest::Object - One distinct Store::Digest data object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    my $dataobj = $store->get('sha-256' => $key);

    my $fh = $dataobj->content;


=head1 METHODS

This class exists to encapsulate the metadata relevant to a
L<Store::Digest> data object. It is not instantiated directly. All
methods are read-only accessors.

=head2 content

Returns a filehandle or equivalent, pointing to the object's content,
open in read-only mode. Unless the object has been deleted, then this
will be C<undef>.

=cut

sub BUILD {
    my $self = shift;
    $self->mtime($self->ctime) unless $self->mtime;
    $self->ptime($self->ctime) unless $self->ptime;
}

# has content => (
#     is       => 'ro',
#     required => 0,
#     isa      => Maybe[FiniteHandle],
# );

has _content => (
    is       => 'rw',
    required => 0,
    isa      => Maybe[CodeRef|FiniteHandle],
    init_arg => 'content',
);

sub content {
    my $self = shift;
    my $content = $self->_content;
    if ($content and ref $content eq 'CODE') {
        $content = $content->();
        $self->_content($content);
    }
    $content;
}

=head2 digest

    my $uri = $dataobj->digest('sha-1');

    my @algos = $dataobj->digest;

Returns a L<URI::di> object for the relevant digest algorithm. Will
croak if an invalid digest algorithm is supplied. While valid digest
algorithms are specified at creation time, you can retrieve them by
calling this method with no arguments.

=cut

has _digests => (
    is       => 'ro',
    isa      => DigestHash,
    required => 1,
    init_arg => 'digests',
);

sub digest {
    my ($self, $algo) = @_;
    my $d = $self->_digests;
    unless (defined $algo) {
        my @k = sort keys %$d;
        return wantarray ? @k : \@k;
    }

    # lowercase it
    $algo = lc $algo;

    # hee hee self-reference
    Carp::croak("No algorithm named $algo, only " . join ' ' , $self->digest)
          unless defined $d->{$algo};

    # clone the URI so that it can't be messed with
    $d->{$algo}->clone;
}

=head2 size

Returns the byte size of the object. Note that for deleted objects,
this will be whatever the size of the object was before it was
deleted.

=cut

has size => (
    is       => 'ro',
    isa      => NonNegativeInt,
    required => 1,
);

=head2 type

Returns the MIME type

=cut

has type => (
    is       => 'ro',
    isa      => Maybe[ContentType],
    required => 0,
);

=head2 charset

Returns the character set (e.g. C<utf-8>) of the data object if known.

=cut

has charset => (
    is       => 'ro',
    isa      => Maybe[Token],
    required => 0,
);

=head2 language

Returns the natural language in
L<RFC 5646|http://tools.ietf.org/html/rfc5646> format, if it was
supplied.

=cut

has language => (
    is       => 'ro',
    isa      => Maybe[Token],
    required => 0,
);

=head2 encoding

Returns the I<transfer encoding>, of the data object if known,
(e.g. C<gzip> or C<deflate>, I<not> the L</charset>).

=cut

has encoding => (
    is       => 'ro',
    isa      => Maybe[Token],
    required => 0,
);

=head2 ctime

Returns the timestamp at which the object was I<added> to
the store, from the point of view of the system.

=cut

has ctime => (
    is       => 'ro',
    isa      => DateTimeType,
    required => 1,
    coerce   => 1,
);

=head2 mtime

Returns the timestamp that was supplied as the modification time of
the object from the point of view of the I<user>, if different from
L</ctime>.

=cut

has mtime => (
    is       => 'rw',
    isa      => MaybeDateTime,
    required => 0,
    coerce   => 1,
);

=head2 ptime

Returns the timestamp of the time the I<metadata properties> of the
object were last updated.

=cut

has ptime => (
    is       => 'rw',
    isa      => DateTimeType,
    required => 0,
    coerce   => 1,
);

=head2 dtime

Returns the system timestamp at which the object was I<deleted>, if
applicable.

=cut

has dtime => (
    is       => 'rw',
    isa      => MaybeDateTime,
    required => 0,
    coerce   => 1,
);

has _flags => (
    is       => 'ro',
    isa      => Int,
    required => 1,
    default  => 0,
    init_arg => 'flags',
);

=head2 type_checked

This flag represents that the claimed content-type has been checked.

=cut

sub type_checked {
    shift->_flags & TYPE_CHECKED;
}

=head2 type_valid

=cut

sub type_valid {
    shift->_flags & (TYPE_CHECKED|TYPE_VALID);
}

=head2 charset_checked

=cut

sub charset_checked {
    shift->_flags & CHARSET_CHECKED;
}

=head2 charset_valid

=cut

sub charset_valid {
    shift->_flags & (CHARSET_CHECKED|CHARSET_VALID);
}

=head2 encoding_checked

=cut

sub encoding_checked {
    shift->_flags & ENCODING_CHECKED;
}

=head2 encoding_valid

=cut

sub encoding_valid {
    shift->_flags & (ENCODING_CHECKED|ENCODING_VALID);
}

=head2 syntax_checked

This flag represents an additional layer of syntax checking, e.g. XML
validation.

=cut

sub syntax_checked {
    shift->_flags & SYNTAX_CHECKED;
}

=head2 syntax_valid

=cut

sub syntax_valid {
    shift->_flags & (SYNTAX_CHECKED|SYNTAX_VALID);
}

=head2 matches $DIGEST

Pass in a L<URI::ni> object or string representing a RFC6920 named
identifier, and this method will tell you you whether or not the
object possesses a matching digest.

=cut

sub matches {
    my ($self, $digest) = @_;
    $digest = URI->new($digest)->canonical;
    Carp::croak('Input must be an RFC6920 address')
          unless $digest->isa('URI::ni');
    my $d = $self->_digests->{$digest->algorithm} or return;
    return $digest->eq($d);
}

=head2 as_string

=cut

sub as_string {
    my $self = shift;

    my %labels = (
        size     => 'Size (Bytes)',
        ctime    => 'Added to Store',
        mtime    => 'Last Modified',
        ptime    => 'Properties Modified',
        dtime    => 'Deleted',
        type     => 'Content Type',
        language => '(Natural) Language',
        charset  => 'Character Set',
        encoding => 'Content Encoding',

    );
    my @mandatory = qw(size ctime mtime ptime);
    my @optional  = qw(dtime type language charset encoding);

    my $out = sprintf "%s\n  Digests:\n", ref $self;

    for my $d ($self->digest) {
        $out .= sprintf("    %s\n", $self->digest($d));
    }

    for my $m (@mandatory) {
        $out .= "  $labels{$m}: " . $self->$m . "\n";
    }
    for my $o (@optional) {
        my $val = $self->$o;
        $out .= "  $labels{$o}: $val\n" if $val;
    }

    my $f = $self->_flags;
    my @a = qw(content-type charset content-encoding syntax);
    my %x = (
        0 => 'unverified',
        1 => 'invalid',
        2 => 'recheck',
        3 => 'valid',
    );

    $out .= "  Validation:\n";
    for my $i (0..$#a) {
        my $x = ($f >> (3 - $i)) & 3;
        $out .= sprintf("    %-16s: %s\n", $a[$i], $x{$x});
    }

    $out;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Store::Digest::Object
