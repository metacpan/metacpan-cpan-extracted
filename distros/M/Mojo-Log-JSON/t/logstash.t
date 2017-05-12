use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture_stderr';
use Mojo::Log::JSON::LogStash;

my $time_re = qr/"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{6}Z"/;

ok my $logger = Mojo::Log::JSON::LogStash->new(), "new";

my $stderr;

$stderr = capture_stderr { $logger->debug("Simple string") };
like $stderr,
    qr/{"\@timestamp":$time_re,"\@version":1,"level":"debug","message":"Simple string"}/,
    "string message ok";

$stderr = capture_stderr { $logger->debug(qw/ Multi line string /) };
like $stderr,
    qr/{"\@timestamp":$time_re,"\@version":1,"level":"debug","message":"Multi\\nline\\nstring/,
    "multi line message ok";

$stderr = capture_stderr { $logger->debug( { message => "Data structure", foo => 'bar' } ) };
like $stderr,
    qr/{"\@timestamp":$time_re,"\@version":1,"foo":"bar","level":"debug","message":"Data structure"}/,
    "data structure message ok";

$logger->default_fields->{extra_field} = 'default extra field';

$stderr = capture_stderr { $logger->debug( { message => "Data structure", foo => 'bar' } ) };

like $stderr,
    qr/{"\@timestamp":$time_re,"\@version":1,"extra_field":"default extra field","foo":"bar","level":"debug","message":"Data structure"}/,
    "data structure message ok";

done_testing;
