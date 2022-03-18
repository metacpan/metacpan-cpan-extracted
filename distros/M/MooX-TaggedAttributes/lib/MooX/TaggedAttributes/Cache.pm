package MooX::TaggedAttributes::Cache;

# ABSTRACT: Extract information from a Tagged Attribute Cache

use v5.10.1;

use strict;
use warnings;

use Hash::Util;

our $VERSION = '0.13';

use overload '%{}' => \&tag_hash, fallback => 1;






















sub new {
    my ( $class, $target ) = @_;

    return bless { list => $target->_tag_list }, $class;
}












sub tag_hash {

    my $self = shift;

    no overloading;

    return $self->{tag_hash} ||= do {
        my %tags;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            my $tag = ( $tags{ $tuple->[0] } ||= {} );
            $tag->{$_} = $tuple->[2] for @{ $tuple->[1] };
        }
        Hash::Util::lock_hash( %tags );
        \%tags;
    };
}












sub attr_hash {

    my $self = shift;

    no overloading;

    return $self->{attr_hash} ||= do {
        my %attrs;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            ( $attrs{$_} ||= {} )->{ $tuple->[0] } = $tuple->[2]
              for @{ $tuple->[1] };
        }
        Hash::Util::lock_hash( %attrs );
        \%attrs;
    };
}















sub tags {
    my ( $self, $attr ) = @_;

    no overloading;

    if ( !defined $attr ) {
        return $self->{tags} ||= [ keys %{ $self->tag_hash } ];
    }

    return ( $self->{attr} ||= {} )->{$attr} ||= do {
        my $attrs = $self->attr_hash;
        [ keys %{ $attrs->{$attr} || {} } ];
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

version 0.13

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

=head2 tag_hash

   $tags = $cache->tag_hash;

Returns a reference to a hash keyed off of the tags in the cache.  The
values are hashes which map attribute names to tag values.

B<Do Not Modify This Hash.>

=head2 attr_hash

   $tags = $cache->tag_hash;

Returns a reference to a hash keyed off of the attributes in the
cache.  The values are hashes which map tag names to tag values.

B<Do Not Modify This Hash.>

=head2 tags

   # return all of the tags as an array reference
   $tags = $cache->tags;

   # return the tags for the specified attribute as an array reference
   $tags = $cache->tags( $attr );

Returns a reference to an array containing tags.

B<Do Not Modify This Array.>

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
