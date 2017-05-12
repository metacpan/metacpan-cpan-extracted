# -*-perl-*-

# $Id: 00_base.t,v 3.8 2004/03/12 14:36:39 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 64;

do "t/config.pl";

my $SPOPS_CLASS = 'BaseTest';
my @FIELDS      = qw( id_name name );
my %FIELD_MAP   = map { $FIELDS[ $_ - 1 ] => $_ } ( 1 .. scalar @FIELDS  );
my %CREATION    = ( u => 'WRITE', w => 'READ' );
my $ID_FIELD    = 'id_name';
my $OBJECT_TYPE = 'Testing Loopback Object';
my $DISPLAY_URL  = { url => '/Foo/show/' };
my $OBJECT_TITLE_FIELD = 'name';

my $STORABLE_FILE = '_tmp_00_base';

END {
    unlink( $STORABLE_FILE ) if ( $STORABLE_FILE );
}

{
    require_ok( 'SPOPS::Initialize' );

    my %config = (
      test => {
         class       => $SPOPS_CLASS,
         isa         => [ 'SPOPS::Loopback' ],
         field       => \@FIELDS,
         id_field    => $ID_FIELD,
         creation_security => \%CREATION,
         name        => $OBJECT_TITLE_FIELD,
         object_name => $OBJECT_TYPE,
         display     => $DISPLAY_URL,
       },
     );

    # Create our test class using the loopback

    my $class_init_list = eval { SPOPS::Initialize->process({ config => \%config }) };
    ok( ! $@, "Initialize process run $@" );
    is( $class_init_list->[0], $SPOPS_CLASS, 'Loopback initialized' );

    ########################################
    # METADATA/CONFIG METADATA

    {
        is_deeply( $SPOPS_CLASS->field, \%FIELD_MAP,
                   'Metadata field hashref match' );
        is_deeply( $SPOPS_CLASS->field_list, \@FIELDS,
                   'Metadata field arrayref match' );
        is( $SPOPS_CLASS->id_field, $ID_FIELD, 'Metadata ID field match' );
        is_deeply( $SPOPS_CLASS->creation_security, \%CREATION,
                   'Metadata creation security match' );
        is( $SPOPS_CLASS->no_security, undef, 'Metadata no security match' );
        is( ref $SPOPS_CLASS->CONFIG, 'HASH', 'Config hashref returned' );
    }

    ########################################
    # CHANGE/SAVE STATE
    {
        my $item = $SPOPS_CLASS->new;
        ok( ! $@, 'New empty object instantiated' );
        is( ref $item, $SPOPS_CLASS, 'Object class correct' );

        ok( $item->is_changed, 'Change state of new item' );
        $item->{name}        = 'new';
        $item->{ $ID_FIELD } = 99;
        ok( $item->is_changed, 'Change state after property set' );
        $item->clear_change;
        ok( ! $item->is_changed, 'Change state after clear' );
        $item->has_change;
        ok( $item->is_changed, 'Change state after explicit set' );
        my $cloned_cs = $item->clone;
        ok( $cloned_cs->is_changed, 'Change state of cloned item' );

        ok( ! $item->is_saved, 'Save state of new item' );
        eval { $item->save };
        ok( $item->is_saved, 'Save state after save()' );
        $item->clear_save;
        ok( ! $item->is_saved, 'Save state after clear' );
        $item->has_save;
        ok( $item->is_saved, 'Save state after explicit set' );
        my $cloned_ss = $item->clone;
        ok( ! $cloned_ss->is_saved, 'Save state of cloned item' );
    }

    ########################################
    # CONSTRUCTOR PERMUTATIONS

    # Set the ID field implicitly and explicitly
    {
        my $item_eid = $SPOPS_CLASS->new({ $ID_FIELD => 42 });
        is( $item_eid->id, 42, 'Explicit ID set in constructor' );
        my $item_iid = $SPOPS_CLASS->new({ id => 42 });
        is( $item_iid->id, 42, 'Implicit ID set in constructor' );
    }

    # Do not set fields not part of class even when we're not using
    # strict field checking

    {
        my $item_nf = $SPOPS_CLASS->new({ foobar => 'hey!' });
        ok( ! $item_nf->{foobar}, 'Non-class field not set (good)' );
    }

    # Strict field checking
    {
        my $item_strict = $SPOPS_CLASS->new({ strict_field => 1 });
        ok( $item_strict, 'Object created with strict field checking on' );
        is( ref( tied( %{ $item_strict } ) ), 'SPOPS::Tie::StrictField',
            'Correct tied object created' );
        $item_strict->{foo} = 'bar';
        is( $item_strict->{foo}, undef,
            'Strict field assignment did nothing (good)' );
    }

    # Default values
    {
        my $DEFAULT_NAME = 'PerlRox';
        my $DEFAULT_VARS = { name => $DEFAULT_NAME };
        my $item_def = $SPOPS_CLASS->new({ default_values => $DEFAULT_VARS });
        is( $item_def->{name}, $DEFAULT_NAME, 'Default value set in constructor' );
        my $item_nodef = $SPOPS_CLASS->new({ name => 'foo',
                                             default_values => $DEFAULT_VARS });
        isnt( $item_nodef->{name}, $DEFAULT_NAME,
              'Default value set in constructor but passed value overrides' );
    }

    # Object description
    {
        my $item_d = $SPOPS_CLASS->new({ id => 5, name => 'New Object' });
        my $info = $item_d->object_description;
        is( $info->{class}, $SPOPS_CLASS, 'Object Description: class' );
        is( $info->{object_id}, 5, 'Object Description: object_id' );
        is( $info->{oid}, 5, 'Object Description: oid' );
        is( $info->{id_field}, $ID_FIELD, 'Object Description: id_field' );
        is( $info->{name}, $OBJECT_TYPE, 'Object Description: name' );
        is( $info->{title}, $item_d->{ $OBJECT_TITLE_FIELD }, 'Object Description: title' );
        ok( ! $info->{security}, 'Object Description: security' );
        my $url = $DISPLAY_URL->{url};
        is( $info->{url}, "$url?$ID_FIELD=5", 'Object Description: display URL' );
        is( $info->{url_edit}, "$url?edit=1;$ID_FIELD=5", 'Object Description: edit URL' );
    }

    # Data only
    {
        my $item_d = $SPOPS_CLASS->new({ id => 5, name => 'New Object' });
        my $data_hashref = $item_d->as_data_only;
        is( ref( $data_hashref ), 'HASH', 'Data only proper structure' );
        is( $data_hashref->{id_name}, $item_d->{id_name}, "Data only field 1" );
        is( $data_hashref->{name}, $item_d->{name}, "Data only field 2" );
    }

    # AUTOLOAD-ed accessors
    {
        my $item_d = $SPOPS_CLASS->new({ id => 5, name => 'New Object' });
        is( $item_d->id_name, 5, 'Accessor created for field 1' );
        is( $item_d->name, 'New Object', 'Accessor created for field 2' );
    }

    # AUTOLOAD-ed mutators
    {
        my $item = $SPOPS_CLASS->new();
        is( $item->id_name( 55 ), 55, 'Accessor/mutator created for field 1' );
        is( $item->name( 'foo' ), 'foo', 'Accessor/mutator created for field 2' );
        is( $item->id_name, 55, 'Value set by mutator for field 1' );
        is( $item->name, 'foo', 'Value set by mutator for field 2' );
    }

    # AUTOLOAD-ed clearers
    {
        my $item = $SPOPS_CLASS->new({ id => 42, name => 'Frobozz' });
        $item->{name} = undef;
        is( $item->name, undef, 'Cleared through hash' );
        $item->{name} = 'Frobozz';
        is( $item->name_clear, undef, 'Return of clear method' );
        is( $item->{name}, undef, 'Clear method actually cleared' );
    }

    ########################################
    # CLONE

    {
        my $item = $SPOPS_CLASS->new({ id => 5, name => 'Original object' });
        my $cloned = $item->clone;
        is( ref( $cloned ), ref( $item ),
            'Class of cloned item matches' );
        isnt( $cloned->id, $item->id,
              'id() of cloned item does not match as expected' );
        isnt( $cloned->id_name, $item->id_name,
              'Value of ID field does not match as expected' );
        is( $cloned->name, $item->name,
            'Normal property of cloned item matches' );
    }

    ########################################
    # STORABLE

    {
        my $item_d = $SPOPS_CLASS->new({ id => 5, name => 'New Object' });
        eval { $item_d->store( $STORABLE_FILE ) };
        ok( ! $@, 'Storable store() executed ok' );
        ok( -f $STORABLE_FILE, 'Storable file created ok' );
        my $item_e = eval { $SPOPS_CLASS->retrieve( $STORABLE_FILE ) };
        ok( ! $@, 'Storable retrieve() executed ok' );
        is( ref( $item_e ), $SPOPS_CLASS, 'Storable object retrieved proper object class' );
        is( $item_e->id, $item_d->id, 'Field 1 reserialized' );
        is( $item_e->{name}, $item_e->{name}, 'Field 2 reserialized' );
        open( FOO, "< $STORABLE_FILE" );
        my $item_f = eval { $SPOPS_CLASS->fd_retrieve( \*FOO ) };
        ok( ! $@, 'Storable fd_retrieve() executed ok' );
        is( ref( $item_f ), $SPOPS_CLASS, 'Storable object fd retrieved proper object class' );
        is( $item_f->id, $item_d->id, 'Field 1 fd reserialized' );
        is( $item_f->{name}, $item_d->{name}, 'Field 2 fd reserialized' );
    }

}
