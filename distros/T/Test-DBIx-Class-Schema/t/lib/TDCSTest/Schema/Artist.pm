package # hide from PAUSE
    TDCSTest::Schema::Artist;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
    qw<
        artistid
        personid
        name
    >
);

__PACKAGE__->set_primary_key('artistid');

__PACKAGE__->belongs_to( person => 'TDCSTest::Schema::Person', 'personid' );

__PACKAGE__->has_many( 'cds' => 'TDCSTest::Schema::CD', 'artistid' );

# borrowed from https://metacpan.org/pod/DBIx::Class::Relationship::Base#Custom-join-conditions
# though we could probably also just have an empty return value, but if this TODO block
# gets removed it makes sense to have a working condition here
__PACKAGE__->has_many(
    cds_90s => 'TDCSTest::Schema::CD',
    sub {
        my $args = shift;
     
        return {
            "$args->{foreign_alias}.artist" => { -ident => "$args->{self_alias}.artistid" },
            "$args->{foreign_alias}.year"   => { '>', "1989", '<', "2000" },
        };
    }
);

1;
