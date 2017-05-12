use Test::Most;



use Moo;
require MooX::Failover;

ok !__PACKAGE__->can('failover_to'), 'not yet imported';

MooX::Failover->import();

ok __PACKAGE__->can('failover_to'), 'imported';

MooX::Failover->unimport();

ok !__PACKAGE__->can('failover_to'), 'unimported';

MooX::Failover->import();

ok __PACKAGE__->can('failover_to'), 'imported';

Moo->unimport();

ok !__PACKAGE__->can('failover_to'), 'unimported by Moo';

done_testing;






