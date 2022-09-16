package MooX::TaggedAttributes::Cache;

# ABSTRACT: Extract information from a Tagged Attribute Cache

use v5.10.1;

use strict;
use warnings;

our $VERSION = '0.18';

use Const::Fast ();
use overload '%{}' => \&tag_hash, fallback => 1;






















sub new {
    my ( $class, $target ) = @_;

    return bless { list => $target->_tag_list }, $class;
}






























sub tag_attr_hash {

    my $self = shift;

    no overloading;

    return $self->{tag_attr_hash} //= do {
        my %tags;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            my $tag = ( $tags{ $tuple->[0] } //= {} );
            $tag->{$_} = $tuple->[2] for @{ $tuple->[1] };
        }
        Const::Fast::const my %rtags => %tags;
        \%rtags;
    };
}
*tag_hash = \&tag_attr_hash;
























sub tag_value_hash {

    my $self = shift;

    no overloading;

    return $self->{tag_value_hash} //= do {
        my %tags;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            my $tag = ( $tags{ $tuple->[0] } //= {} );
            # copy so don't corrupt internal list.
            push @{ $tag->{ $tuple->[2] } //= [] }, @{ $tuple->[1] };
        }
        Const::Fast::const my %rtags => %tags;
        \%rtags;
    };
}











sub attr_hash {

    my $self = shift;

    no overloading;

    return $self->{attr_hash} //= do {
        my %attrs;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            ( $attrs{$_} //= {} )->{ $tuple->[0] } = $tuple->[2]
              for @{ $tuple->[1] };
        }
        Const::Fast::const my %rattrs => %attrs;
        \%rattrs;
    };
}













sub tags {
    my ( $self, $attr ) = @_;

    no overloading;

    if ( !defined $attr ) {
        return $self->{tags} //= do {
            Const::Fast::const my @tags => keys %{ $self->tag_hash };
            \@tags;
        }
    }

    return ( $self->{attr} //= {} )->{$attr} //= do {
        my $attrs = $self->attr_hash;
        [ keys %{ $attrs->{$attr} // {} } ];
    };
}









sub value {
    my ( $self, $attr, $tag ) = @_;

    no autovivification;
    return $self->attr_hash->{$attr}{$tag};
}

#
# This file is part of MooX-TaggedAttributes
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

MooX::TaggedAttributes::Cache - Extract information from a Tagged Attribute Cache

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  $cache = MooX::TaggedAttributes::Cache->new( $class );

  $tags = $cache->tags;

=head1 DESCRIPTION

L<MooX::TaggedAttributes> caches attribute tags as objects of this class.
The user typically never instantiates objects of L<MooX::TaggedAttributes::Cache>.
Instead, they are returned by the L<_tags|MooX::TaggedAttributes/_tags> method added
to tagged classes, e.g.

  $cache = $class->_tags;

=head1 CLASS METHODS

=head2 new

  $cache = MooX::TaggedAttributes::Cache( $class );

Create a cache object for the C<$class>, which must have a C<_tag_list> method.

=head1 METHODS

=head2 tag_attr_hash

   $tags = $cache->tag_attr_hash;

Returns a reference to a read-only hash keyed off of the tags in the
cache.  The values are hashes which map attribute names to tag values.

For example, given:

   has attr1 => ( ..., tag1 => 'foo' );
   has attr2 => ( ..., tag1 => 'foo' );
   has attr3 => ( ..., tag2 => 'bar' );
   has attr4 => ( ..., tag2 => 'bar' );

this will be returned:

  {
     tag1 => { attr1 => 'foo', attr2 => 'foo' },
     tag2 => { attr3 => 'bar', attr4 => 'bar' },
  }

=head2 tag_hash

This is a deprecated alias for L</tag_attr_hash>

=head2 tag_value_hash

   $tags = $cache->tag_value_hash;

Returns a reference to a hash keyed off of the tags in the cache.  The
values are hashes which map tag values to attribute names (as an
arrayref of names ).

For example, given:

   has attr1 => ( ..., tag1 => 'foo' );
   has attr2 => ( ..., tag1 => 'foo' );
   has attr3 => ( ..., tag1 => 'bar' );
   has attr4 => ( ..., tag1 => 'bar' );

this may be returned (the order of the attribute names is arbitrary):

  { tag1 => { foo => [ 'attr1', 'attr2' ],
              bar => [ 'attr3', 'attr4' ],
  },

=head2 attr_hash

   $tags = $cache->tag_hash;

Returns a reference to a hash keyed off of the attributes in the
cache.  The values are hashes which map tag names to tag values.

=head2 tags

   # return all of the tags as an array reference
   $tags = $cache->tags;

   # return the tags for the specified attribute as an array reference
   $tags = $cache->tags( $attr );

Returns a reference to an array containing tags.

=head2 value

   $value = $cache->value( $attr, $tag );

Return the value of a tag for the given attribute.

=head1 OVERLOAD

=head2 %{}

The object may be treated as a hash reference. It will operate on the
reference returned by L</tag_hash>.  For example,

  keys %{ $cache };

is equivalent to

  keys %{ $cache->tag_hash };

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-moox-taggedattributes@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes

=head2 Source

Source is available at

  https://gitlab.com/djerius/moox-taggedattributes

and may be cloned from

  https://gitlab.com/djerius/moox-taggedattributes.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooX::TaggedAttributes|MooX::TaggedAttributes>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
