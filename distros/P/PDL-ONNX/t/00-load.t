use strict;
use warnings;
use Test::More;

use_ok('PDL::ONNX', qw(onnx_version available_providers load_session));

my $ver = onnx_version();
like($ver, qr/^\d+\.\d+/, 'onnx_version returns version string (' . $ver . ')');

my @providers = available_providers();
ok(scalar(@providers) >= 1, 'at least one execution provider available (' . join(', ', @providers) . ')');
ok((grep { $_ eq 'CPUExecutionProvider' } @providers), 'CPUExecutionProvider is available');

done_testing();
