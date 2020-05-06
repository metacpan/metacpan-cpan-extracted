use Test::Most;
use Test::OpenTracing::Interface::SpanContext qw/can_all_ok/;

use strict;
use warnings;

use lib 't/lib';
use MockUtils qw/build_mock_object/;
use RoleUtils qw/get_required_methods/;

use OpenTracing::Interface::SpanContext;

my $class = ref build_mock_object(
   class_name    => 'SpanContext',
   class_methods => [
       get_required_methods('OpenTracing::Interface::SpanContext')
   ],
);
can_all_ok($class);

done_testing();
