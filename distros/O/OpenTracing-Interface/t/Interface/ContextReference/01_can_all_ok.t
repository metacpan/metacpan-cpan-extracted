use Test::Most;
use Test::OpenTracing::Interface::ContextReference qw/can_all_ok/;

use strict;
use warnings;

use lib 't/lib';
use MockUtils qw/build_mock_object/;
use RoleUtils qw/get_required_methods/;

use OpenTracing::Interface::ContextReference;

my $class = ref build_mock_object(
   class_name    => 'ContextReference',
   class_methods => [
       get_required_methods('OpenTracing::Interface::ContextReference')
   ],
);
can_all_ok($class);

done_testing();
