use Test::Most;
use Test::OpenTracing::Interface::Scope qw/can_all_ok/;

use strict;
use warnings;

use lib 't/lib';
use MockUtils qw/build_mock_object/;
use RoleUtils qw/get_required_methods/;

use OpenTracing::Interface::Scope;

my $class = ref build_mock_object(
   class_name    => 'Scope',
   class_methods => [
       get_required_methods('OpenTracing::Interface::Scope')
   ],
);
can_all_ok($class);

done_testing();
