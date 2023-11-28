use Test::More;

use_ok('Parse::SAMGov::Exclusion');

my $e = new_ok('Parse::SAMGov::Exclusion');
can_ok(
    $e, qw( classification name address DUNS UEI
      xprogram xagency CT_code xtype comments active_date
      termination_date record_status crossref
      SAM_number CAGE NPI creation_date dnb_open_data
      load load_v1 load_v2
      )
);
$e->name(Parse::SAMGov::Exclusion::Name->new(entity => 'ABC Corp Inc'));
isa_ok($e->name, 'Parse::SAMGov::Exclusion::Name');
can_ok($e->name, qw(first middle last suffix prefix entity));
is($e->name->entity, 'ABC Corp Inc', 'Entity name matches');
isnt($e->name->entity, undef, 'this is an entity');

$e->name(
         Parse::SAMGov::Exclusion::Name->new(first  => 'John',
                                             middle => 'James',
                                             last   => 'Johnson',
                                             prefix => 'Mr',
                                            )
        );
isa_ok($e->name, 'Parse::SAMGov::Exclusion::Name');
can_ok($e->name, qw(first middle last suffix prefix entity));
is($e->name->entity, undef,     'this is an individual');
is($e->name->first,  'John',    'individual first name matches');
is($e->name->last,   'Johnson', 'individual last name matches');
is($e->name->middle, 'James',   'individual middle name matches');

$e->address(
            Parse::SAMGov::Entity::Address->new(address => '123 Baker Street',
                                                city    => 'Boringville',
                                                state   => 'AB',
                                                country => 'USA',
                                                zip     => '20195'
                                               )
           );
isa_ok($e->address, 'Parse::SAMGov::Entity::Address');
can_ok($e->address, qw(address city state zip country));
isa_ok($e->active_date('01/01/1994'), 'DateTime');
isa_ok($e->active_date,               'DateTime');
is($e->active_date->mdy('/'), '01/01/1994', 'active date matches');
isa_ok($e->termination_date('12/01/1994'), 'DateTime');
isa_ok($e->termination_date,               'DateTime');
is($e->termination_date->mdy('/'), '12/01/1994', 'termination date matches');
isa_ok($e->termination_date('Indefinite'), 'DateTime');
isa_ok($e->termination_date,               'DateTime');
is($e->termination_date->year, '2200', 'termination date year matches 2200');
isa_ok($e->creation_date('12/01/1994'), 'DateTime');
isa_ok($e->creation_date,               'DateTime');
is($e->creation_date->mdy('/'), '12/01/1994', 'termination date matches');

done_testing();
__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
