package Pandoc::Metadata;
use strict;
use warnings;
use 5.010001;

use Pandoc::Elements;
use Scalar::Util qw(blessed reftype);
use JSON::PP;

# packages and methods

{
    # key-value map of metadata fields
    package Pandoc::Document::Metadata;

    sub TO_JSON {
        return { map { $_ => $_[0]->{$_} } keys %{ $_[0] } };
    }

    sub value {
        my $map = { c => shift };
        Pandoc::Document::MetaMap::value( $map, @_ )
    }
}

{
    # metadata element parent class
    package Pandoc::Document::Meta;
    our @ISA = ('Pandoc::Document::Element');
    sub is_meta { 1 }
    sub value { shift->value(@_) }
}

# methods

sub _value_args {
    my $content = shift->{c};
    my ($pointer, %opts) = @_ % 2 ? @_ : (undef, @_);

    $opts{pointer} = $pointer // $opts{pointer} // '';

    return ($content, %opts);
}

sub Pandoc::Document::MetaString::value {
    my ($content, %opts) = _value_args(@_);
    $opts{pointer} eq '' ? $content : undef;
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

sub Pandoc::Document::MetaBool::value {
    my ($content, %opts) = _value_args(@_);
    return if $opts{pointer} ne '';

    if (($opts{boolean} // '') eq 'JSON::PP') {
        $content ? JSON::true() : JSON::false();
    } else {
        $content ? 1 : 0;
    }
}

sub Pandoc::Document::MetaMap::value {
    my ($map, %opts) = _value_args(@_);

    if ($opts{pointer} eq '') {
        return { map { $_ => $map->{$_}->value(%opts) } keys %$map };
    } else {
        my ($key, @fields) = split '/', $opts{pointer};
        $key =~ s!~1!/!g;
        $key =~ s/~0/~/g;
        $opts{pointer} = join '/', @fields;
        return $map->{$key} ? $map->{$key}->value(%opts) : undef;
    }
}

sub Pandoc::Document::MetaList::value {
    my ($content, %opts) = _value_args(@_);
    if ($opts{pointer} =~ /^[1-9]*[0-9]$/) {
        my $value = $content->[$opts{pointer}];
        defined $value ? $value->value(%opts, pointer => '') : undef;
    } elsif ($opts{pointer} eq '') {
        [ map { $_->value(%opts) } @$content ]
    } else {
        undef
    }
}

sub Pandoc::Document::MetaInlines::value {
    my ($content, %opts) = _value_args(@_);
    return if $opts{pointer} ne '';

    if ($opts{element} // '' eq 'keep') {
        $content;
    } else {
        join '', map { $_->string } @$content;
    }
}

sub Pandoc::Document::MetaBlocks::string {
    join "\n\n", map { $_->string } @{$_[0]->content};
}

sub Pandoc::Document::MetaBlocks::value {
    my ($content, %opts) = _value_args(@_);
    return if $opts{pointer} ne '';

    if ($opts{element} // '' eq 'keep') {
        $content;
    } else {
        $_[0]->string;
    }
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

=head1 COMMON METHODS

All Metadata Elements support L<common element methods|Pandoc::Elements/COMMON
METHODS> (C<name>, C<to_json>, C<string>, ...) and return true for method
C<is_meta>.

=head2 value( [ $pointer ] [ %options ] )

Called without an argument this method returns an unblessed deep copy of the
metadata element. JSON Pointer (L<RFC 6901|http://tools.ietf.org/html/rfc6901>)
expressions can be used to select subfields.  Note that JSON Pointer escapes
slash as C<~1> and character C<~> as C<~0>. Neither URI Fragment syntax nor
empty strings as field names are supported.

  $doc->value;                  # full metadata
  $doc->value('author');        # author field
  $doc->value('author/name');   # name subfield of author field
  $doc->value('author/0');      # first author field
  $doc->value('author/0/name'); # name subfield of first author field
  $doc->value('~1~0');          # metadata field '/~'

Returns C<undef> if the selected field does not exist.

Instances of MetaInlines and MetaBlocks are stringified by unless option
C<element> is set to C<keep>.

Setting option C<boolean> to C<JSON::PP> will return C<JSON::PP:true>
or C<JSON::PP::false> for L<MetaBool|/MetaBool> instances.

=head1 METADATA ELEMENTS

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

The C<string> method concatenates all stringified content blocks separated by
empty lines.

=cut
