# -*- perl -*-

use strict;
use Test::More tests => 8;
use lib 't/lib';
use DBSchema;
use Data::Dumper;
use DvdForm;
use UserForm2;

use Rose::HTMLx::Form::DBIC;

my $schema = DBSchema::get_test_schema();
my $dvd_rs = $schema->resultset( 'Dvd' );

my $form = DvdForm->new;
my $processor = Rose::HTMLx::Form::DBIC->new( form => $form, rs => $dvd_rs );
$processor->options_from_resultset();
my @values = $form->field( 'tags' )->options;
is ( scalar @values, 3, 'Tags loaded' );

$processor->init_from_dbic(1);
$form->validate;

my $value = $form->field( 'name' )->output_value;
is ( $value, 'Picnick under the Hanging Rock', 'Dvd name set' );
$value = $form->field( 'owner' )->internal_value;
is ( $value, 1, 'Owner set' );
is_deeply ( [ $form->field( 'tags' )->internal_value ], [ '2', '3' ], 'Tags set' );
#$value = $form->field( 'creation_date' )->output_value;
#is( "$value", '2003-01-16T23:12:01', 'Date set');

my $user_form = $form->form( 'current_borrower' );
$value = $user_form->field( 'name' )->output_value;
is ( $value, 'Zbyszek Lukasiak', 'Current borrower name set' );

$form = UserForm2->new;
my $user_rs = $schema->resultset( 'User' );
$processor = Rose::HTMLx::Form::DBIC->new( form => $form, rs => $user_rs );
$processor->options_from_resultset();
$processor->init_from_dbic(1);
my @dvd_forms = $form->form('owned_dvds')->forms();
ok( scalar @dvd_forms == 2, 'Dvd forms created' );
ok( $dvd_forms[0]->field('id')->output_value eq '1', 'Id loaded' );
#ok( $dvd_forms[0]->field('creation_date')->output_value->strftime("%Y-%m-%d %H:%M:%S") eq '2003-01-16 23:12:01', 'creation_date loaded' );
ok( $dvd_forms[1]->field('id')->output_value eq '2', 'Second row id loaded' );


