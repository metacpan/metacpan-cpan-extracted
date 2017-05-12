#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;

plan( 'tests' => 14 );

use lib 't/lib';
use t_ROS_U_SB_Util;
use t_ROS_U_SB_Model;
use Rosetta::Utility::SQLBuilder;

t_ROS_U_SB_Util->message( 'Generate SQL - an illustrative dialect not for any particular db product' );

eval {
    # Now build the ROS M model that we will generate SQL from.
    my $model = Rosetta::Model->new_container();
    $model->auto_assert_deferrable_constraints( 1 ); # also done here to help with debugging
    $model->auto_set_node_ids( 1 );
    $model->may_match_surrogate_node_ids( 1 );
    t_ROS_U_SB_Model->populate_model( $model );
    $model->assert_deferrable_constraints();
    pass( 'creation of source ROS M model' );

    # Now initialize the SQL-Builder object.
    my $builder = Rosetta::Utility::SQLBuilder->new();
    pass( 'creation of source ROS M SQL-Builder' );

    # Run battery, making the default delimited identifiers
    t_ROS_U_SB_Util->message( 'battery with the default delimited identifiers' );
    test_battery( $model, $builder, {
        'create_tb' =>
q{CREATE TABLE "Gene Schema"."person" (
"person_id" INTEGER NOT NULL DEFAULT '1' AUTO_INCREMENT, 
"alternate_id" VARCHAR(20) CHARACTER SET UTF8 NULL, 
"name" VARCHAR(100) CHARACTER SET UTF8 NOT NULL, 
"sex" VARCHAR(1) CHARACTER SET UTF8 CHECK VALUE IN ('M', 'F') NULL, 
"father_id" INTEGER NULL, 
"mother_id" INTEGER NULL, 
CONSTRAINT PRIMARY KEY ("person_id"), 
CONSTRAINT "ak_alternate_id" UNIQUE ("alternate_id"), 
CONSTRAINT "fk_father" FOREIGN KEY ("father_id") REFERENCES "Gene Schema"."person" ("person_id"), 
CONSTRAINT "fk_mother" FOREIGN KEY ("mother_id") REFERENCES "Gene Schema"."person" ("person_id")
);
},
        'delete_tb' =>
q{DROP TABLE "Gene Schema"."person";
},
        'create_vw' =>
q{CREATE VIEW "Gene Schema"."person_with_parents" AS 
SELECT ALL "self"."person_id" AS "self_id", 
"self"."name" AS "self_name", 
"father"."person_id" AS "father_id", 
"father"."name" AS "father_name", 
"mother"."person_id" AS "mother_id", 
"mother"."name" AS "mother_name"
FROM "Gene Schema"."person" AS "self" 
LEFT OUTER JOIN "Gene Schema"."person" AS "father" ON "father"."person_id" = "self"."father_id" 
LEFT OUTER JOIN "Gene Schema"."person" AS "mother" ON "mother"."person_id" = "self"."mother_id";
},
        'delete_vw' =>
q{DROP VIEW "Gene Schema"."person_with_parents";
},
    } );

    # Run battery, making non-delimited and uppercase identifiers
    t_ROS_U_SB_Util->message( 'battery with non-delimited, uppercase identifiers' );
    $builder->identifier_style( 'ND_CI_UP' );
    test_battery( $model, $builder, {
        'create_tb' =>
q{CREATE TABLE GENESCHEMA.PERSON (
PERSON_ID INTEGER NOT NULL DEFAULT '1' AUTO_INCREMENT, 
ALTERNATE_ID VARCHAR(20) CHARACTER SET UTF8 NULL, 
NAME VARCHAR(100) CHARACTER SET UTF8 NOT NULL, 
SEX VARCHAR(1) CHARACTER SET UTF8 CHECK VALUE IN ('M', 'F') NULL, 
FATHER_ID INTEGER NULL, 
MOTHER_ID INTEGER NULL, 
CONSTRAINT PRIMARY KEY (PERSON_ID), 
CONSTRAINT AK_ALTERNATE_ID UNIQUE (ALTERNATE_ID), 
CONSTRAINT FK_FATHER FOREIGN KEY (FATHER_ID) REFERENCES GENESCHEMA.PERSON (PERSON_ID), 
CONSTRAINT FK_MOTHER FOREIGN KEY (MOTHER_ID) REFERENCES GENESCHEMA.PERSON (PERSON_ID)
);
},
        'delete_tb' =>
q{DROP TABLE GENESCHEMA.PERSON;
},
        'create_vw' =>
q{CREATE VIEW GENESCHEMA.PERSON_WITH_PARENTS AS 
SELECT ALL SELF.PERSON_ID AS SELF_ID, 
SELF.NAME AS SELF_NAME, 
FATHER.PERSON_ID AS FATHER_ID, 
FATHER.NAME AS FATHER_NAME, 
MOTHER.PERSON_ID AS MOTHER_ID, 
MOTHER.NAME AS MOTHER_NAME
FROM GENESCHEMA.PERSON AS SELF 
LEFT OUTER JOIN GENESCHEMA.PERSON AS FATHER ON FATHER.PERSON_ID = SELF.FATHER_ID 
LEFT OUTER JOIN GENESCHEMA.PERSON AS MOTHER ON MOTHER.PERSON_ID = SELF.MOTHER_ID;
},
        'delete_vw' =>
q{DROP VIEW GENESCHEMA.PERSON_WITH_PARENTS;
},
    } );
    $builder->identifier_style( 'YD_CS' );

    # Run battery, making non-delimited, lowercase identifiers
    t_ROS_U_SB_Util->message( 'battery with non-delimited, lowercase identifiers' );
    $builder->identifier_style( 'ND_CI_DN' );
    test_battery( $model, $builder, {
        'create_tb' =>
q{CREATE TABLE geneschema.person (
person_id INTEGER NOT NULL DEFAULT '1' AUTO_INCREMENT, 
alternate_id VARCHAR(20) CHARACTER SET UTF8 NULL, 
name VARCHAR(100) CHARACTER SET UTF8 NOT NULL, 
sex VARCHAR(1) CHARACTER SET UTF8 CHECK VALUE IN ('M', 'F') NULL, 
father_id INTEGER NULL, 
mother_id INTEGER NULL, 
CONSTRAINT PRIMARY KEY (person_id), 
CONSTRAINT ak_alternate_id UNIQUE (alternate_id), 
CONSTRAINT fk_father FOREIGN KEY (father_id) REFERENCES geneschema.person (person_id), 
CONSTRAINT fk_mother FOREIGN KEY (mother_id) REFERENCES geneschema.person (person_id)
);
},
        'delete_tb' =>
q{DROP TABLE geneschema.person;
},
        'create_vw' =>
q{CREATE VIEW geneschema.person_with_parents AS 
SELECT ALL self.person_id AS self_id, 
self.name AS self_name, 
father.person_id AS father_id, 
father.name AS father_name, 
mother.person_id AS mother_id, 
mother.name AS mother_name
FROM geneschema.person AS self 
LEFT OUTER JOIN geneschema.person AS father ON father.person_id = self.father_id 
LEFT OUTER JOIN geneschema.person AS mother ON mother.person_id = self.mother_id;
},
        'delete_vw' =>
q{DROP VIEW geneschema.person_with_parents;
},
    } );
    $builder->identifier_style( 'YD_CS' );
};
$@ and fail( 'TESTS ABORTED: ' . t_ROS_U_SB_Util->error_to_string( $@ ) );

sub test_battery {
    my ($model, $builder, $exp_sql) = @_;

    # Declare some temp vars we will keep reusing.
    my ($should, $did);

    # Now test that we can make 'create table' and 'drop table' SQL properly.

    my $tb_person = $model->find_child_node_by_surrogate_id(
        [undef,'root','blueprints','Gene Database','Gene Schema','person'] );

    $did = $builder->build_schema_or_app_table_create( $tb_person );
    $should = $exp_sql->{'create_tb'};
    is( $did, $should, 'stmt: CREATE TABLE person' );

    $did = $builder->build_schema_or_app_table_delete( $tb_person );
    $should = $exp_sql->{'delete_tb'};
    is( $did, $should, 'stmt: DROP TABLE person' );

    # Now test that we can make 'create view' and 'drop view' SQL properly.

    my $vw_pwp = $model->find_child_node_by_surrogate_id(
        [undef,'root','blueprints','Gene Database','Gene Schema','person_with_parents'] );

    $did = $builder->build_schema_or_app_view_create( $vw_pwp );
    $should = $exp_sql->{'create_vw'};
    is( $did, $should, 'stmt: CREATE VIEW person_with_parents' );

    $did = $builder->build_schema_or_app_view_delete( $vw_pwp );
    $should = $exp_sql->{'delete_vw'};
    is( $did, $should, 'stmt: DROP VIEW person_with_parents' );
}

1;
