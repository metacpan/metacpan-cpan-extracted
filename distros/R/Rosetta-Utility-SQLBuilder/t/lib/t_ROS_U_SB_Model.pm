#!perl
use 5.008001; use utf8; use strict; use warnings;

# This module is used when testing Rosetta::Utility::SQLBuilder.

package # hide this class name from PAUSE indexer
t_ROS_U_SB_Model;

######################################################################

sub populate_model {
    my (undef, $model) = @_;

    $model->build_child_node_trees( [
        [ 'scalar_data_type', { 'si_name' => 'entity_id'  , 'base_type' => 'NUM_INT' , 'num_precision' => 9, }, ],
        [ 'scalar_data_type', { 'si_name' => 'alt_id'     , 'base_type' => 'STR_CHAR', 'max_chars' => 20, 'char_enc' => 'UTF8', }, ],
        [ 'scalar_data_type', { 'si_name' => 'person_name', 'base_type' => 'STR_CHAR', 'max_chars' => 100, 'char_enc' => 'UTF8', }, ],
        [ 'scalar_data_type', { 'si_name' => 'person_sex' , 'base_type' => 'STR_CHAR', 'max_chars' => 1, 'char_enc' => 'UTF8', }, [
            [ 'scalar_data_type_opt', 'M', ],
            [ 'scalar_data_type_opt', 'F', ],
        ], ],
        [ 'row_data_type', 'person', [
            [ 'row_data_type_field', { 'si_name' => 'person_id'   , 'scalar_data_type' => 'entity_id'  , }, ],
            [ 'row_data_type_field', { 'si_name' => 'alternate_id', 'scalar_data_type' => 'alt_id'     , }, ],
            [ 'row_data_type_field', { 'si_name' => 'name'        , 'scalar_data_type' => 'person_name', }, ],
            [ 'row_data_type_field', { 'si_name' => 'sex'         , 'scalar_data_type' => 'person_sex' , }, ],
            [ 'row_data_type_field', { 'si_name' => 'father_id'   , 'scalar_data_type' => 'entity_id'  , }, ],
            [ 'row_data_type_field', { 'si_name' => 'mother_id'   , 'scalar_data_type' => 'entity_id'  , }, ],
        ], ],
        [ 'row_data_type', 'person_with_parents', [
            [ 'row_data_type_field', { 'si_name' => 'self_id'    , 'scalar_data_type' => 'entity_id'  , }, ],
            [ 'row_data_type_field', { 'si_name' => 'self_name'  , 'scalar_data_type' => 'person_name', }, ],
            [ 'row_data_type_field', { 'si_name' => 'father_id'  , 'scalar_data_type' => 'entity_id'  , }, ],
            [ 'row_data_type_field', { 'si_name' => 'father_name', 'scalar_data_type' => 'person_name', }, ],
            [ 'row_data_type_field', { 'si_name' => 'mother_id'  , 'scalar_data_type' => 'entity_id'  , }, ],
            [ 'row_data_type_field', { 'si_name' => 'mother_name', 'scalar_data_type' => 'person_name', }, ],
        ], ],
    ] );

    my $catalog_bp = $model->build_child_node_tree( 'catalog', 'Gene Database', [
        [ 'owner', 'Lord of the Root', ],
        [ 'schema', { 'si_name' => 'Gene Schema', 'owner' => 'Lord of the Root', }, ],
    ] );
    my $schema = $catalog_bp->find_child_node_by_surrogate_id( 'Gene Schema' );

    my $tb_person = $schema->build_child_node_tree( 'table', { 'si_name' => 'person', 'row_data_type' => 'person', }, [
        [ 'table_field', { 'si_row_field' => 'person_id', 'mandatory' => 1, 'default_val' => 1, 'auto_inc' => 1, }, ],
        [ 'table_field', { 'si_row_field' => 'name'     , 'mandatory' => 1, }, ],
        [ 'table_index', { 'si_name' => 'primary' , 'index_type' => 'UNIQUE', }, [
            [ 'table_index_field', 'person_id', ],
        ], ],
        [ 'table_index', { 'si_name' => 'ak_alternate_id', 'index_type' => 'UNIQUE', }, [
            [ 'table_index_field', 'alternate_id', ],
        ], ],
        [ 'table_index', { 'si_name' => 'fk_father', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, [
            [ 'table_index_field', { 'si_field' => 'father_id', 'f_field' => 'person_id' } ],
        ], ],
        [ 'table_index', { 'si_name' => 'fk_mother', 'index_type' => 'FOREIGN', 'f_table' => 'person', }, [
            [ 'table_index_field', { 'si_field' => 'mother_id', 'f_field' => 'person_id' } ],
        ], ],
    ] );

    my $vw_pwp = $schema->build_child_node_tree( 'view', { 'si_name' => 'person_with_parents',
            'view_type' => 'JOINED', 'row_data_type' => 'person_with_parents', }, [
        ( map { [ 'view_src', { 'si_name' => $_, 'match' => 'person', }, [
            map { [ 'view_src_field', $_, ], } ( 'person_id', 'name', 'father_id', 'mother_id', ),
        ], ], } ('self') ),
        ( map { [ 'view_src', { 'si_name' => $_, 'match' => 'person', }, [
            map { [ 'view_src_field', $_, ], } ( 'person_id', 'name', ),
        ], ], } ( 'father', 'mother', ) ),
        [ 'view_field', { 'si_row_field' => 'self_id'    , 'src_field' => ['person_id','self'  ], }, ],
        [ 'view_field', { 'si_row_field' => 'self_name'  , 'src_field' => ['name'     ,'self'  ], }, ],
        [ 'view_field', { 'si_row_field' => 'father_id'  , 'src_field' => ['person_id','father'], }, ],
        [ 'view_field', { 'si_row_field' => 'father_name', 'src_field' => ['name'     ,'father'], }, ],
        [ 'view_field', { 'si_row_field' => 'mother_id'  , 'src_field' => ['person_id','mother'], }, ],
        [ 'view_field', { 'si_row_field' => 'mother_name', 'src_field' => ['name'     ,'mother'], }, ],
        [ 'view_join', { 'lhs_src' => 'self', 'rhs_src' => 'father', 'join_op' => 'LEFT', }, [
            [ 'view_join_field', { 'lhs_src_field' => 'father_id', 'rhs_src_field' => 'person_id' } ],
        ], ],
        [ 'view_join', { 'lhs_src' => 'self', 'rhs_src' => 'mother', 'join_op' => 'LEFT', }, [
            [ 'view_join_field', { 'lhs_src_field' => 'mother_id', 'rhs_src_field' => 'person_id' } ],
        ], ],
    ] );

    my $application_bp = $model->build_child_node_tree( 'application', 'Gene App', [
        [ 'catalog_link', { 'si_name' => 'editor_link', 'target' => $catalog_bp, }, ],
    ] );

    $model->build_child_node( 'application_instance', { 'si_name' => 'test app', 'blueprint' => $application_bp, } );
}

######################################################################

1;
