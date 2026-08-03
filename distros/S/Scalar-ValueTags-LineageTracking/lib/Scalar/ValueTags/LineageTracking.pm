package Scalar::ValueTags::LineageTracking 0.004;

use v5.44;

use Scalar::ValueTags 0.004;

use feature 'class';

no warnings 'experimental::class';

use Carp 'croak';
use Ref::Util qw( is_plain_ref is_ref );

use Scalar::ValueTags qw(
  SVTAGS_UNIQUE_REF_ARRAY
  SVTAGS_UNIQUE_HASH
  add_value_tag
  clear_value_tags
  get_value_tags
  register_value_tags_type
);

class Scalar::ValueTags::LineageTracking {
    field $tag_type :param :reader //= 'string';

    field $vt_type :reader(_vt_type) :writer(_set_vt_type);

    ADJUST {
        croak "Invalid tag_type: must be 'ref' or 'string'"
          unless $self->&tag_type =~ m/\A(ref|string)\Z/n;
    }

    ADJUST {
        $self->_set_vt_type(
            register_value_tags_type(
                $self->&tag_type eq 'string'
                ? SVTAGS_UNIQUE_HASH
                : SVTAGS_UNIQUE_REF_ARRAY
            )
        );
    }

    method add_data_sources( $var_ref, $data_sources ) {
        my $tag_type = $self->&tag_type;

        for my $data_source ( $data_sources->@* ) {
            croak 'invalid data_source: must be string'
              if $tag_type eq 'string' && is_ref($data_source);
            croak 'invalid data_source: must be unblessed ref'
              if $tag_type eq 'ref' && !is_plain_ref($data_source);

            add_value_tag( $self->&_vt_type, $var_ref, $data_source );
        }

        return;
    }

    method get_data_sources($var_ref) {
        my $tags = get_value_tags( $self->&_vt_type, $var_ref );
        $tags = [ keys $tags->%* ]
          if $self->&tag_type eq 'string';
        return $tags;
    }

    method set_data_sources( $var_ref, $data_sources ) {
        my $tag_type = $self->&tag_type;

        my $prev_data_sources = $self->get_data_sources($var_ref);

        clear_value_tags( $vt_type, $var_ref );
        for my $data_source ( $data_sources->@* ) {
            croak 'invalid data_source: must be string'
              if $tag_type eq 'string' && is_ref($data_source);
            croak 'invalid data_source: must be unblessed ref'
              if $tag_type eq 'ref' && !is_plain_ref($data_source);

            add_value_tag( $vt_type, $var_ref, $data_source );
        }

        return $prev_data_sources;
    }

    method clear_data_sources($var_ref) {
        my $prev_data_sources = $self->get_data_sources($var_ref);
        clear_value_tags( $self->&_vt_type, $var_ref );
        return $prev_data_sources;
    }
}

1;
__END__

=head1 NAME

Scalar::ValueTags::LineageTracking - track data lineages using ValueTags

=head1 SYNOPIS

    # setup: choose type of data to store in tags
    my $lt = Scalar::ValueTags::LineageTracking->new( tag_type => 'string' );
    my $lt = Scalar::ValueTags::LineageTracking->new( tag_type => 'ref' );

    # default tag_type: string
    my $lt = Scalar::ValueTags::LineageTracking->new();

    ### append tracking data sources when data is received from external sources
    my $names = $dbh->selectcol_arrayref('select name from user where user_id = %s", undef, $id);
    my $name = $names->[0];

    # using 'ref' tag_type
    $lt->add_data_sources(\$name,
        [
            { table => 'user', column => 'name', id => $id, file => __FILE__, line => __LINE__ },
            ...,
        ]
    );

    # using 'string' tag_type
    my $json = JSON->new->utf8->canonical->pretty(0);
    $lt->add_data_sources( \$name,
        [
            $json->encode( { table => 'user', column => 'name', id => $id, file => __FILE__, line => __LINE__ } ),
            ...,
        ],
    );

    ### clear previous data sources and set data source
    # 'ref' tag_type
    $lt->set_data_sources( \$name,
        [
            { table => 'user', column => 'name' },
            ...,
        ]
    );
    # 'string' tag_type
    $lt->set_data_sources( \$name,
        [
            $json->encode( { table => 'user', column => 'name' } ),
            ...,
        ]
    );

    ### data sources are propagated any time data is used
    $lt->add_data_source(\$name, 'tag-one');
    $lt->add_data_source(\$honorif, 'tag-two');
    my $salutation = "Hello, $honorif $name";

    # returns data sources set on both $honorif and $name:
    my $sources = $lt->get_data_sources(\$salutation);

    ### retrieve and clear data sources, for reporting
    my $sources = $lt->get_and_clear_data_sources(\$salutation);
    send_lineage( { sources => $sources, var => 'salutation', file => __FILE__, line => __LINE__ } );

=head1 DESCRIPTION

This module uses C<Scalar::ValueTags> (propagated value magic) to implement
data flow tracking that can be used to populate data lineage systems such as
OpenLineage.

C<LineageTracking> allows arbitrary tracking data to be attached to data values when the
values are received from an external system, propagates the tracking data any time
that other data is derived from the original data, and captures the tracking data
from the value when it is sent to an external sink.

The tracking data may be either an unblessed Perl reference or a serialized data
string, depending on the C<tag_type> parameter.

When the tracking items are propagated, they are de-duplicated using either the
string or the refaddr of the data structure that was set in C<set_data_sources>.

The tracking data may be formatted in any way, such as OpenLineage.

=head2 Implementation

For the "hash" C<tag_type>, the C<SVTAGS_UNIQUE_HASH> behavior is used, allowing
string-serialized data to be used as tags. The tags are de-duplicated by the
string value, so the serialization must generate canonical strings.

For the "ref" C<tag_type>, the C<SVTAGS_UNIQUE_REF_ARRAY> behavior is used, allowing
any arbitray Perl reference to be used as tags. The tags are de-duplicated by the
C<refaddr> of the reference rather than the contents, so identical tags must use
the same Perl reference.

=head1 PARAMETERS

=head2 tag_type

The C<tag_type> determines the type of the tags passed to L<Scalar::ValueTags>.

=over

=item * "string"

Each value tag must be a string suitable for use as a hash key. De-duplication is
done automatically since the string is used as a hash key.

=item * "ref"

Each value tag must be a Perl reference. De-duplication is done by the C<refaddr>
of the reference.

=back

=head1 METHODS

=head2 add_data_sources

    # using 'string' tag type
    $lt->add_data_sources( \$var, [ $string1, $string2, ... ] );

    # using 'ref' tag type
    $lt->add_data_sources( \$var, [ { this => 1 }, { that => 2 } ] );

Append the given data sources to the value of the given C<$var>. Each
data source must match the L<tag_type> set upon instantiation.

Does not return anything.

=head2 clear_data_sources

    my $data_sources = $lt->clear_data_sources(\$var);
    for my $data_source (@$data_sources) { ... }

Clears all data sources on the value in given C<$var>.

Returns an arrayref of all of the data sources that previously existed
on the value in C<$var>.

=head2 get_data_sources

    my $data_sources = $lt->get_data_sources(\$var);
    for my $data_source (@$data_sources) { ... }

Returns an arrayref of all data sources set for the value in the given C<$var>.
Includes all propagated tags from all data values that were used to calculate
the value of C<$var>.

=head2 set_data_sources

    # using 'string' tag type
    my $prev_sources = $lt->set_data_sources( \$var, [ $string1, $string2, ... ] );

    # using 'ref' tag type
    my $prev_sources = $lt->set_data_sources( \$var, [ { this => 1 }, { that => 2 } ] );

Set the data sources for the value of the given C<$var> to be the given data
sources, clearing any pervious data sources. Each data source must match the
L<tag_type> set upon instantiation.

Returns an arrayref of the previous data sources that were set on the value in C<$var>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=head1 AUTHORS

=over

=item * Noel Maddy <zhtwnpanta@gmail.com>

=back

=cut

