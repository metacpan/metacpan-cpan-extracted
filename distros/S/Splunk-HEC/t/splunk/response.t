use Test::More;
use Splunk::HEC::Response;
use strict;

# Request
my $res = Splunk::HEC::Response->new;
is $res->success,    1,   'success is set';
is $res->status,     200, 'right code (200)';
is $res->reason,     '',  'reason is empty';
is $res->content,    '',  'content is empty';
is $res->is_success, 1,   'is_success is true';
is $res->is_error,   '',  'is_error is false';

done_testing();
