use Test::More;

use Data::Dumper;
{
  package LD::Employee;
  use Moo;
  use Types::Standard qw/Str ArrayRef InstanceOf/;
  use MooX::JSON_LD 'Person';

  has name => (
    is => 'ro',
    json_ld => 'name',
  );
  no Moo;
  no MooX::JSON_LD;
}

{
  package LD::Org;
  use Moo;
  use MooX::JSON_LD 'Organization';
  use Types::Standard qw/ArrayRef InstanceOf/;

  has 'org_name' => (
    is => 'ro',
    json_ld => 'name',
  );
  has employees => (
    is => 'rw',
    isa => ArrayRef->of(InstanceOf->of("LD::Employee")),
    json_ld => 'employee',
  );

  no Moo;
  no MooX::JSON_LD;
}

my $employees = [
  LD::Employee->new( name => 'Joe Soap' ),
  LD::Employee->new( name => 'John Brown' )
];

my $o = LD::Org->new(
  org_name => 'Foo Inc',
  employees => $employees,
);

my $emps = $o->json_ld_data->{employee};
ok($emps, 'Got an employee attribute value');
isa_ok($emps, 'ARRAY');
is(@$emps, 2, 'Got two employees');
isa_ok($emps->[0], 'HASH');
is($emps->[0]->{name}, 'Joe Soap', 'First employee has the right name');
like($o->json_ld, qr/Joe Soap/, 'JSON-LD contains employee names');

diag $o->json_ld;

done_testing;
