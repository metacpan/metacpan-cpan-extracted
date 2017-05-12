# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;
use lib 't/lib';
use lib '../Rose-HTMLx-Form-Field-DateTimeSelect/lib/';
use DBSchema;
use Data::Dumper;
use DvdForm;
use UserForm2;
use Rose::HTMLx::Form::DBIC qw( options_from_resultset dbic_from_form values_hash );
use String::Random qw(random_regex);

my $schema = DBSchema::get_test_schema();
my $dvd_rs = $schema->resultset( 'Dvd' );
my $user_rs = $schema->resultset( 'User' );

my $form = DvdForm->new;
my $processor = Rose::HTMLx::Form::DBIC->new( form => $form, rs => $dvd_rs );
$processor->options_from_resultset;

my $dvd = $schema->resultset( 'Dvd' )->new( {} );
my $owner = $schema->resultset( 'User' )->first;

$form->params( {
        tags => [ '2', '3' ], 
        name => 'Test name',
#        'creation_date.year' => 2002,
#        'creation_date.month' => 1,
#        'creation_date.day' => 3,
#        'creation_date.hour' => 4,
#        'creation_date.minute' => 33,
#        'creation_date.pm' => 1,
        'owner' => $owner->id,
        'current_borrower.name' => 'temp name',
        'current_borrower.username' => 'temp name',
        'current_borrower.password' => 'temp name',
    }
);
$form->init_fields();
$form->validate;
my $updates = {
        tags => [ '2', '3' ], 
        name => 'Test name',
#        'creation_date.year' => 2002,
#        'creation_date.month' => 1,
#        'creation_date.day' => 3,
#        'creation_date.hour' => 4,
#        'creation_date.minute' => 33,
#        'creation_date.pm' => 1,
        owner => $owner->id,
        current_borrower => {
            name => 'temp name',
            username => 'temp name',
            password => 'temp name',
        }
};

is_deeply ( Rose::HTMLx::Form::DBIC::values_hash( $form ), $updates, 'Updates hash constructed' );
# changing existing records

$form->clear;
$form->form( 'current_borrower' )->delete_field( 'username' );
$form->form( 'current_borrower' )->delete_field( 'password' );
$dvd = $schema->resultset( 'Dvd' )->find( 2 );
$form->params( {
        name => 'Test name',
        tags => [ ], 
        'owner' => $owner->id,
        'current_borrower.name' => 'temp name',
    }
);
$form->init_fields();
$updates = {
        name => 'Test name',
        tags => [ ], 
        'owner' => $owner->id,
        current_borrower => {
            name => 'temp name',
        }
};

is_deeply ( Rose::HTMLx::Form::DBIC::values_hash( $form ), $updates, 'Updates hash constructed' );

# repeatable

$form = UserForm2->new;
$processor = Rose::HTMLx::Form::DBIC->new( form => $form, rs => $user_rs );
$form->params( {
       name  => 'temp name',
       username => 'temp username',
       password => 'temp username',
       'owned_dvds.1.id' => undef,
       'owned_dvds.1.name' => 'temp name 1',
       'owned_dvds.1.tags' => [ 1, 2 ],
       'owned_dvds.2.id' => undef,
       'owned_dvds.2.name' => 'temp name 2',
       'owned_dvds.2.tags' => [ 2, 3 ],
   }
);
$form->prepare();
$processor->options_from_resultset();
$form->init_fields();

$updates = {
    name  => 'temp name',
    username => 'temp username',
    password => 'temp username',
    owned_dvds =>[
    {
        'id' => undef,
        'name' => 'temp name 1',
        'tags' => [ 1, 2 ],
    },
    {
        'id' => undef,
        'name' => 'temp name 2',
        'tags' => [ 2, 3 ],
    }
    ]
};

is_deeply ( Rose::HTMLx::Form::DBIC::values_hash( $form ), $updates, 'Updates hash constructed' );


$dvd = $dvd_rs->next;
my $random_string = 'random ' . random_regex('\w{20}');
ok( $dvd->name ne $random_string );

$form = DvdForm->new;
$form->delete_forms;
$processor = Rose::HTMLx::Form::DBIC->new( form => $form, rs => $dvd_rs );
$processor->options_from_resultset();
$form->params( {
        name => $random_string, 
        owner => 1,
    }
);
$form->init_fields();
$dvd = $processor->dbic_from_form( $dvd->id );

is ( $dvd->name, $random_string, 'Dvd name set' );

