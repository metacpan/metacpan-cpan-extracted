# -*- perl -*-

use Test::Most;
use Test::DBIx::Class::Factory;
use Test::DBIx::Class::Example::Schema;
use Test::DBIx::Class {
    schema_class => 'Test::DBIx::Class::Example::Schema',
};

my $schema = Schema;
isa_ok($schema,"DBIx::Class::Schema","Created Schema object ok");
my $factory = Test::DBIx::Class::Factory->new( schema => $schema );
isa_ok($factory,"Test::DBIx::Class::Factory","Created Factory class ok");

my $person = $factory->create_record('Person', name => "Gareth Harper");

my $employee = $factory->create_record(
    'Company::Employee', 
    employee => {
        person => $person,
    }
);
isa_ok($employee,'Test::DBIx::Class::Example::Schema::Result::Company::Employee');
is($employee->employee->person->name,'Gareth Harper');

done_testing;

