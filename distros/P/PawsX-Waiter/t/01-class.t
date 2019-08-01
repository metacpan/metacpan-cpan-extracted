use strict;
use warnings;

use Test::More tests => 5;
use Test::Moose;

BEGIN {
    use_ok('PawsX::Waiter');
}

{
    package WithPaws;
    use Moose;
    
    sub service { return 'elasticloadbalancing'; }
    sub version { return '2012-06-01'; }

}

my $c = WithPaws->new();
PawsX::Waiter->meta->apply($c);

does_ok($c, 'PawsX::Waiter');
ok($c->GetWaiter('InstanceInService'), 'Waiter method exists');
ok($c->GetWaiter('InstanceInService')->delay, 'can call delay');
ok($c->GetWaiter('InstanceInService')->maxAttempts, 'can call maxAttempts');
