package Scalar::ValueTags::LineageTracking 0.002;

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

    method add_data_source( $var_ref, $data_source ) {
        my $tag_type = $self->&tag_type;

        croak 'invalid data_source: must be string'
          if $tag_type eq 'string' && is_ref($data_source);
        croak 'invalid data_source: must be unblessed ref'
          if $tag_type eq 'ref' && !is_plain_ref($data_source);

        add_value_tag( $self->&_vt_type, $var_ref, $data_source );
    }

    method get_data_sources($var_ref) {
        my $tags = get_value_tags( $self->&_vt_type, $var_ref );
        $tags = [ keys $tags->%* ]
          if $self->&tag_type eq 'string';
        return $tags;
    }

    method set_data_source( $var_ref, $data_source ) {
        my $tag_type = $self->&tag_type;

        croak 'invalid data_source: must be string'
          if $tag_type eq 'string' && is_ref($data_source);
        croak 'invalid data_source: must be unblessed ref'
          if $tag_type eq 'ref' && !is_plain_ref($data_source);

        my $vt_type = $self->&_vt_type;
        clear_value_tags( $vt_type, $var_ref );
        add_value_tag( $vt_type, $var_ref, $data_source );
    }

    method clear_data_sources($var_ref) {
        clear_value_tags( $self->&_vt_type, $var_ref );
    }

    method get_and_clear_data_sources($var_ref) {
        my $tags = $self->get_data_sources($var_ref);
        $self->clear_data_sources($var_ref);
        return $tags;
    }
}

1;
__END__

=head1 NAME

Scalar::ValueTags::LineageTracking - track data lineages using ValueTags

=head1 SYNOPIS

    # setup: choose type of data to store in tags
    my $dt = Scalar::ValueTags::LineageTracking->new( tag_type => 'string' );
    my $dt = Scalar::ValueTags::LineageTracking->new( tag_type => 'ref' );

    # default tag_type: string
    my $dt = Scalar::ValueTags::LineageTracking->new();

    ### append tracking data sources when data is received from external sources
    my $names = $dbh->selectcol_arrayref('select name from user where user_id = %s", undef, $id);
    my $name = $names->[0];

    # using 'ref' tag_type
    $dt->add_data_source(\$name,
        { table => 'user', column => 'name', id => $id, file => __FILE__, line => __LINE__ }
    );

    # using 'string' tag_type
    my $json = JSON->new->utf8->canonical->pretty(0);
    $dt->add_data_source(\$name,
        $json->encode( { table => 'user', column => 'name', id => $id, file => __FILE__, line => __LINE__ } )
    );

    ### clear previous data sources and set data source
    $dt->set_data_source( \$var, { table => 'user', column => 'name' } ); # 'ref' tag_type
    $dt->set_data_source( \$var, $json->encode( { table => 'user', column => 'name' } ) ); # 'string' tag_type

    ### data sources are propagated any time data is used
    $dt->add_data_source(\$name, 'tag-one');
    $dt->add_data_source(\$honorif, 'tag-two');
    my $salutation = "Hello, $honorif $name";

    # returns data sources set on both $honorif and $name:
    my $data_sources = get_data_sources(\$salutation);

    ### retrieve and clear data sources, for reporting
    my $sources = $dt->get_and_clear_data_sources(\$salutation);
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
string or the refaddr of the data structure that was set in C<set_data_source>.

The tracking data may be formatted in any way, such as OpenLineage.

=head2 Implementation

C<LineageTracking> uses the C<SVTAGS_UNIQUE_REF_ARRAY> behavior, which allows arbitrary
references to data structures or serialized data strings to be added to the value magic,
and de-duplicates the structures when propagating them to subsequent data values. If
the data structure references are used, they are de-duplicated by C<refaddr> of the
structure.

=head1 FUNCTIONS

=head2 set_data_source

    # using string
    set_data_source( \$var, JSON->encode( { this => 1, that => 2 } );

    # using Perl reference
    set_data_source( \$var, { this => 1, that => 2 } );

Set the data source for the value of the given C<$var> to be the given data structure.

=head2 get_data_sources

    $data_sources = get_data_sources(\$var);
    for my $data_source (@$data_sources) { ... }

Returns arrayref of all data sources inherited by value in given C<$var>.

=head2 clear_data_sources

    clear_data_sources(\$var);

Clears all data sources on value in given C<$var>.

=head2 export_and_clear_data_sources

    export_and_clear_data_sources( \$var, { sink => 'database', table => 'user', id => $id } );

Captures and sends the tracking data from C<$var>, adding the given metadata to indicate
where the data is being exported from.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=head1 AUTHORS

=over

=item * Noel Maddy <zhtwnpanta@gmail.com>

=back

=cut

