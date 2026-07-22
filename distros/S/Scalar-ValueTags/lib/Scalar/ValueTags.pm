package Scalar::ValueTags 0.004;

use v5.44;

require XSLoader;
XSLoader::load( __PACKAGE__ );

use Exporter 'import';
our @EXPORT = qw(
    SVTAGS_UNIQUE_REF_ARRAY
    SVTAGS_APPEND_ARRAY
    SVTAGS_HASH_COUNT
    SVTAGS_UNIQUE_HASH
    value_tags_enabled
    value_tags_tracing_enabled
    register_value_tags_type
    add_value_tag
    clear_value_tags
    get_value_tags
    remove_value_tag
);

1;
__END__

=head1 NAME

C<Scalar::ValueTags> - Attach propagated metadata to data values

=head1 SYNOPSIS

    use Scalar::ValueTags;

    # register value tags type with unique-hash behavior
    my $vt_type = register_value_tags_type(SVTAGS_UNIQUE_HASH);

    # add value tag to $foo variable;
    my $tag = 'origin: somewhere';
    my $foo = 32;
    add_value_tag( $vt_type, \$foo, $tag );

    my $tags = get_value_tags( $vt_type, \$foo );
    # returns { 'origin: somewhere' => true }

    # value tags are propagated along with data value
    my $bar = 10;
    add_value_tag( $vt_type, \$bar, "origin: elsewhere" );

    my $baz = $foo + $bar;

    my $tags = get_value_tags( $vt_type, \$baz );
    # returns { 'origin: elsewhere' => true, 'origin: somewhere' => true }

    # delete all value tags
    clear_value_tags( $vt_type, \$baz ):

    my $tags = get_value_tags( $vt_type, \$baz );
    # returns {}

=head1 DESCRIPTION

The C<Scalar::ValueTags> module provides functions for managing "value
tags": metadata that is set on a data value and propagated from that
variable to any other variable whose value is set from that of the
tagged variable.

=head2 Overview

This module is similar to L<Variable::Magic>, but applies metadata onto
the data value contained within the variable rather than to the variable
itself.

Every time a value is assigned to another variable, all of the value
tags from all input variables are merged into the derived variable.

There are multiple L</Behaviors>, each of which defines what data types
can be used as a value tag, and how the value tags are merged into the
derived variables.

=head2 Typical Usage

Typically, a value tag contains either an indication of the source of
the data or an indication of what operations are allowed or denied on
the data.

If the value tags are set whenever data is received from an external
source, then the value tags represent the flow of the data within the
system. When the data is sent to an external destination, the value tags
on that data can be used to report the data flow or to apply access
control logic that depends on the source of the data.

=head2 Perl Requirements

C<Scalar::ValueTags> depends on the scalar value magic that is being
added to the Perl core as part of Magic v2.

=head2 Value Tags Types

Each client must register with C<Scalar::ValueTags>, specifying the
desired Behavior. Registering will return a unique opaque token that is
then used in all functions that access value tags. The access functions
will only see the value tags that were set using the same Value Tags
Type.

    my $vt_type = register_value_tags_type(SVTAGS_UNIQUE_REF_ARRAY);

=head2 Behaviors

A C<ValueTags> Behavior defines the data structure used to store the
value tags and the process used to merge the value tags from multiple
variables. The desired Behavior must be specified when registering a
Value Tags Type.

There are four Behaviors available from C<Scalar::ValueTags>:

=head3 SVTAGS_UNIQUE_HASH

This behavior uses a hash to track each unique string tag that has been
seen. All value tags must be strings. The value tags are stored in a
hash, with the tags as keys and C<true> as the value.

When merging value tags, all tags that were set in any of the source
variables will be set in the destination variable.

L</remove_value_tag> will remove the given tag from the hash.

=head3 SVTAGS_HASH_COUNT

This behavior uses a hash to track the number of times each string tag
has been seen. All value tags must be strings. The value tags are stored
in a hash, with the tags as keys and the number of times that tag has
been set as the value.

When merging value tags, the tag counts from the tags of all source
variables will be summed into the corresponding hash entries in the
destination variable.

L</remove_value_tag> will remove the given tag from the hash, along with
its count.

=head3 SVTAGS_APPEND_ARRAY

This behavior uses an array to track all tags that were seen. A value
tag may be any Perl variable, either scalar or reference. The value tags
are stored in an array, and new tags are appended onto the end of the
array.

When merging value tags, the tags of all source variables will be
appended into the tags in the destination variable. The ordering of the
appended array is not deterministic.

L</remove_value_tag> will remove every instance of the given tag from the
array.

=head3 SVTAGS_UNIQUE_REF_ARRAY

This behavior uses an array to track the unique reference address of all
tags that were seen. A value tag must be a Perl reference, typically to
an array or a hash. The value tags are handled as a logical set,
de-duplicated by the reference address of each tag.

When merging value tags, the destination variable receives all unique
reference addresses from the tags of all source variables.

L</remove_value_tag> will remove the instance of the given tag from the
array.

=head2 Guidelines

=head3 Behavior Choice


=over

=item * SVTAGS_UNIQUE_HASH

This behavior has the best merging, and only strings can be used as
value tags.

Structured data can be serialized into the string value tags, if needed.
The serialization must be canonical, so that there is a unique string
representation for any given data structure.

    add_value_tag( $vt_type, \$var, encode_json( { ... } ) );

Since the tags are stored as hash keys, identical tags share the same memory.

Use this behavior if you have string or serializable tags, and you only
need to know which tags have been seen in the dataflow.

=item * SVTAGS_HASH_COUNT

This behavior has slightly lower merging performance than
C<SVTAGS_UNIQUE_HASH>, and only strings can be used as value tags.

Structured data can be serialized into the string value tags, if needed.
The serialization must be canonical, so that there is a unique string
representation for any given data structure.

    add_value_tag( $vt_type, \$var, encode_json( { ... } ) );

Since the tags are stored as hash keys, identical tags share the same memory.

Use this behavior if you have string or serializable tags, and you need
to know how many times each tag has been seen in the dataflow.

=item * SVTAGS_APPEND_ARRAY

This behavior has similar merging performance to C<SVTAGS_UNIQUE_HASH>,
but allows any Perl scalar, arrayref, or hashref to be used as value
tags.

Since the tags are simply appended to an array, the size of the value
tags structure increases every time a new value is derived from multiple
tagged values.

Use this behavior if you have arbitrary data structures as tags, but the
code using the tagged values rarely combines tagged values.

=item * SVTAGS_UNIQUE_REF_ARRAY

This behavior has lower performance than C<SVTAGS_HASH_COUNT> and
C<SVTAGS_APPEND_ARRAY>, because it does a linear scan of all existing
tags when merging tags from multiple value.

Since the value tags are de-duplicated by the reference address when
merging, the size of the value tags structure depends on the number of
unique value tags that have been merged.

Use this behavior if you have structured data for tags and adding new
tags with C<add_value_tag> is done often, since there is no additional
serialization cost (unlike SVTAGS_UNIQUE_HASH), but there is additional
merging cost.

=back

=head2 Implementation

Value tags are implemented using the Value Magic feature that is being
added to core Perl as part of Magic V2. By using Value Magic's C<infect>
callback, all of the value tags from all of the source variables are
merged into the destination variable, as defined by the chosen behavior.

See C<ScalarValueMagicFunctions> in L</perlapi> for more details on
scalar value magic in core Perl.

Basically,

=over 4

=item * Scalar value magic is added to a variable when a value tag is added

    add_value_tag( $vt_type, \$var, 'foo' );

=item * Value tags are duplicated upon assignment from a tagged value

    add_value_tag( $vt_type, \$foo, 'foo' );
    $bar = $foo;
    # $bar now has the same 'foo' tag as $foo

=item * Value tags are merged when multiple source values are combined

    $foo = 3;
    add_value_tag( $vt_type, \$foo, 'foo' );
    $bar = 5;
    add_value_tag( $vt_type, \$bar, 'bar' );
    $foo += $bar;
    # $foo now has both 'foo' and 'bar' tags

=item * Existing value tags are removed when value is overwritten

    $foo = 1;
    add_value_tag( $vt_type, \$foo, 'foo' );
    $bar = 5;
    add_value_tag( $vt_type, \$bar, 'bar' );
    $foo = $bar;
    # $foo now has only the 'bar' tag

=item * Value tags are removed when the value is set to C<undef>

    $foo = 1;
    add_value_tag( $vt_type, \$foo, 'foo' );
    undef $foo;
    # $foo now has no tags

=item * Value tags on source string are preserved through regexps

    $foo = 'this is';
    add_value_tag( $vt_type, \$foo, 'foo' );
    ($bar) = $foo =~ m/is/;
    # $bar now has the 'foo' tag

=item * Hash keys cannot contain value tags

    $foo = 'foo';
    add_value_tag( $vt_type, \$foo, 'foo' );
    %bar = ( $foo => 8 );
    for my $key ( keys %bar ) {
        # $key has no value tags
    }

=back

=head1 FUNCTIONS

=head2 value_tags_enabled

    if ( value_tags_enabled() ) {
        say "Value tags are enabled!";
    }

This constant is automatically exported into your namespace. It is true if the
module is able to manage value tags, and false if not.

FIXME: Module needs to throw exception if value tags are not available and loaded,
rather than requiring client to check whether they are enabled.

=head2 add_value_tag

    add_value_tag( $vt_type, \$var, $tag );

C<add_value_tag> adds the given tag to the value tags for the specified
value-tags type.

C<$vt_type> must be the value returned from a L</register_value_tags_type> call.

The variable must always be passed as a reference, since C<add_value_tag> needs
to modify the SV* directly.

The C<$tag> must be compatible with the registered behavior.

    # using SVTAGS_UNIQUE_HASH or SVTAGS_HASH_COUNT
    my $var;
    add_value_tag( $vt_type, \$var, 'my tag' ); # tag must be string
    my $tags = get_value_tags( $vt_type, \$var );
    #  returns { 'my tag' => true }

    # using SVTAGS_UNIQUE_REF_ARRAY
    my $var;
    add_value_tag( $vt_type, \$var, [ 123 ] );  # tag must be ref
    my $tags = get_value_tags( $vt_type, \$var );
    #  returns [ [ 123 ] ]

    # using SVTAGS_APPEND_ARRAY
    my $var;
    add_value_tag( $vt_type, \$var, 'my tag' );  # tag may be ref or string
    my $tags = get_value_tags( $vt_type, \$var );
    # returns  [ 'my tag' ]

=head2 remove_value_tag

    remove_value_tag( $vt_type, \$var, $tag );

C<remove_value_tag> removes the given tag to the value tags for the specified
value-tags type.

C<$vt_type> must be the value returned from a L</register_value_tags_type> call.

The variable must always be passed as a reference, since C<add_value_tag> needs
to modify the SV* directly.

For tag types such as C<SVTAGS_APPEND_ARRAY>, C<remove_value_tag> removes all
instances of the given tag from the array.

The C<$tag> must be compatible with the registered behavior.

    # using SVTAGS_UNIQUE_HASH or SVTAGS_HASH_COUNT
    my $var;
    remove_value_tag( $vt_type, \$var, 'my tag' ); # tag must be string
    my $tags = get_value_tags( $vt_type, \$var );
    #  returns { 'my tag' => true }

    # using SVTAGS_UNIQUE_REF_ARRAY
    my $var;
    remove_value_tag( $vt_type, \$var, [ 123 ] );  # tag must be ref
    my $tags = get_value_tags( $vt_type, \$var );
    #  returns [ [ 123 ] ]

    # using SVTAGS_APPEND_ARRAY
    my $var;
    remove_value_tag( $vt_type, \$var, 'my tag' );  # tag may be ref or string
    my $tags = get_value_tags( $vt_type, \$var );
    # returns  [ 'my tag' ]

=head2 get_value_tags

    $tags = get_value_tags( $vt_type, \$var );

The C<get_value_tags> function returns the value tags of the given C<$vt_type>
that are currently attached to the variable's data.

The variable must always be passed as a reference, since C<add_value_tag> needs
to inspect the SV* directly.

The returned value tags structure depends on the registered behavior. Array
behaviors return an array reference, while hash behaviors return a hash reference.

=head2 clear_value_tags

    clear_value_tags( $vt_type, \$var );

The C<clear_value_tags> function removes all value tags of the given C<$vt_type>
from the variable's data.

The variable must always be passed as a reference, since C<add_value_tag> needs
to modify the SV* directly.

=head1 DEBUGGING

FIXME - Debugging is not yet implemented in C<Scalar::ValueTags>.

=head2 Devel::MAT::Dumper

If C<Devel::MAT::Dumper> is installed, then C<Scalar::ValueTags> will add any
value tags to the dumped data.

See C<HAVE_DMD_HELPER> in the XS code.

=head2 DEBUG_TRACE_ANNOTATIONS

If C<Scalar::ValueTags> is configured with the C<--with-trace> option, then
additional Perl magic is added to each of the value tags indicating
the source code origin of that annotation.

To enable this, use C<perl Build.PL --with-trace>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=head1 AUTHORS

=over

=item * Noel Maddy <zhtwnpanta@gmail.com>

=back

=cut

