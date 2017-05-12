use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

open my $MEM, '>', \my $log;

local $ENV{MOJO_LOG_LEVEL} = 'debug';
use Mojolicious::Lite;
plugin Logf => {rfc3339 => 1};
app->log->handle($MEM);

app->logf(info => 'foo');
like $log, qr/\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\] \[info\] foo/,
  'logged with rfc3339 timestamp';

done_testing;
