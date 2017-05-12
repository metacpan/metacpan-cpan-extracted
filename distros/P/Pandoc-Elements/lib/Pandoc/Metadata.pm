package Pandoc::Metadata;
use strict;
use warnings;
use 5.010001;

use Pandoc::Elements;
use Scalar::Util qw(blessed reftype);

# packages and methods

{
    # key-value map of metadata fields
    package Pandoc::Document::Metadata;

    sub TO_JSON {
        return { map { $_ => $_[0]->{$_} } keys %{ $_[0] } };
    }

    sub value {
        my $meta = shift;
        if (@_) {
            return $meta->{ $_[0] } ? $meta->{ $_[0] }->metavalue : undef;
        }
        else {
            return { map { $_ => $meta->{$_}->metavalue } keys %$meta };
        }
    }
}

{
    # metadata element parent class
    package Pandoc::Document::Meta;
    our @ISA = ('Pandoc::Document::Element');
    sub is_meta { 1 }
    sub value   { shift->metavalue(@_) }
}

# functions

sub Pandoc::Document::MetaString::metavalue {
    $_[0]->{c};
}

sub Pandoc::Document::MetaBool::set_content {
    $_[0]->{c} = $_[1] && $_[1] ne 'false' && $_[1] ne 'FALSE' ? 1 : 0;
}

sub Pandoc::Document::MetaBool::TO_JSON {
    return {
        t => 'MetaBool',
        c => $_[0]->{c} ? JSON::true() : JSON::false(),
    };
}

sub Pandoc::Document::MetaBool::metavalue {
    $_[0]->{c} ? 1 : 0;
}

sub Pandoc::Document::MetaList::metavalue {
    [ map { $_->metavalue } @{ $_[0]->{c} } ];
}

sub Pandoc::Document::MetaMap::metavalue {
    my $map = $_[0]->{c};
    return { map { $_ => $map->{$_}->metavalue } keys %$map };
}

sub Pandoc::Document::MetaInlines::metavalue {
    join '', map { $_->string } @{ $_[0]->{c} };
}

sub Pandoc::Document::MetaBlocks::metavalue {
    [ map { $_->string } @{ $_[0]->{c} } ];
}

1;
__END__

=head1 NAME

Pandoc::Metadata - pandoc document metadata

=head1 DESCRIPTION

Document metadata such as author, title, and date can be embedded in different
documents formats. Metadata can be provided in Pandoc markdown format with
L<metadata blocks|http://pandoc.org/MANUAL.html#metadata-blocks> at the top of
a markdown file or in YAML format like this:

  ---
  title: a title
  author:
    - first author
    - second author
  published: true
  ...

Pandoc supports document metadata build of strings (L</MetaString>), boolean
values (L</MetaBool>), lists (L</MetaList>), key-value maps (L</MetaMap>),
lists of inline elements (L</MetaInlines>) and lists of block elements
(L</MetaBlocks>). Simple strings and boolean values can also be specified via
pandoc command line option C<-M> or C<--metadata>:

  pandoc -M key=string
  pandoc -M key=false
  pandoc -M key=true
  pandoc -M key

Perl module L<Pandoc::Elements> exports functions to construct metadata
elements in the internal document model and the general helper function
C<metadata>.

=head1 METADATA ELEMENTS

All C<Meta...> elements support common element methods (C<to_json>, C<name>,
...) and return true for method C<is_meta>. Method C<content> returns the
blessed data structure and C<value> returns an unblessed copy:

  $doc->meta->{author}->content->[0];   # MetaInlines
  $doc->meta->value('author')->[0];     # plain string

=head2 value( [ $field ] )

Called without an argument this method returns an unblessed deep copy of the
metadata elements or C<undef> if the given (sub)field does not exist.

Can also be called with the alias C<metavalue>.

=head2 MetaString

A plain text string metadata value.

    MetaString $string
    metadata "$string"

=head2 MetaBool

A Boolean metadata value. The special values C<"false"> and
C<"FALSE"> are recognized as false in addition to normal false values (C<0>,
C<undef>, C<"">, ...).

    MetaBool $value
    metadata JSON::true()
    metadata JSON::false()

=head2 MetaList

A list of other metadata elements.

    MetaList [ @values ]
    metadata [ @values ]

=head2 MetaMap

A map of keys to other metadata elements.

    MetaMap { %map }
    metadata { %map }

=head2 MetaInlines

Container for a list of L<inlines|Pandoc::Elements/INLINE ELEMENTS> in
metadata.

    MetaInlines [ @inlines ]

=head2 MetaBlocks

Container for a list of L<blocks|Pandoc::Elements/BLOCK ELEMENTS> in metadata.

    MetaBlocks [ @blocks ]

=cut
