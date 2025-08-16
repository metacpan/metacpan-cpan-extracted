use strict;
use TVision('tnew');

$|=1;
my $tapp = tnew('TVApp');
my $desktop = $tapp->deskTop;
$desktop->[1] = '.';
$desktop->[2] = '.';

my $btn = tnew('TButton', [1,2,3,4], 'text on the button', 100,0);
$desktop->insert($btn);
print   $btn->[2],"\n";

print TVision::pack($btn, -side => 'left');
#print TVision::pack($btn, 'configure', '.btn', -side => 'left');
#print TVision::pack("rb", -side => 'left');

#$tapp->run;

