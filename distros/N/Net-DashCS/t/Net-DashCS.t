#unexciting testing

use Test;
BEGIN { plan tests => 1 }
eval "use Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort";
ok($@ eq '');

