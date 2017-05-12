# -*- perl -*-

use Test::Most;
use Test::DBIx::Class::Factory;
use Test::DBIx::Class::Example::Schema;
use Test::DBIx::Class {
    schema_class => 'Test::DBIx::Class::Example::Schema',
};

my $schema = Test::DBIx::Class::Example::Schema->connect();
isa_ok($schema,"DBIx::Class::Schema","Created Schema object ok");
my $factory = Test::DBIx::Class::Factory->new( schema => $schema );
isa_ok($factory,"Test::DBIx::Class::Factory","Created Factory class ok");

my @relationships = $factory->get_belongs_to('Company::Employee');
my $tested = 0;
foreach my $relationship (@relationships) {
    if ($relationship->{relationship} eq 'job') {
        is($relationship->{source},'Job');
        $tested++;
    } elsif ($relationship->{relationship} eq 'employee') {
        is($relationship->{source},'Person::Employee');
        $tested++;
    } elsif ($relationship->{relationship} eq 'company') {
        is($relationship->{source},'Company');
        $tested++;
    }
}
is ($tested,3,"Did not match the three checked relationships");

done_testing;

