=pod

Test using alias names for Result::Simple functions.

=cut

use Test2::V0;

use Result::Simple
    ok => { -as => 'left' },
    err => { -as => 'right' },
    ;

is [ left('foo') ], ['foo', undef ], 'ok() is aliased to success()';
is [ right('bar') ], [undef, 'bar'], 'err() is aliased to failure()';

done_testing;
