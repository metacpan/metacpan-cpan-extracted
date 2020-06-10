use Test::Most;
use Test::OpenTracing::Interface::SpanContext qw/can_all_ok/;

use strict;
use warnings;

use lib 't/lib';
use MockUtils qw/build_mock_object/;
use Role::Inspector qw/get_role_info/;

use OpenTracing::Interface::SpanContext;

my $class = ref build_mock_object(
   class_name    => 'SpanContext',
   class_methods => get_role_info('OpenTracing::Interface::SpanContext')->{requires},
);
can_all_ok($class);

done_testing();
