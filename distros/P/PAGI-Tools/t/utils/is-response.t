use strict;
use warnings;
use Test2::V0;
use PAGI::Utils qw(is_response);
use PAGI::Response;

# is_response is the single source of truth for "did the handler return a
# response value?" — a blessed object with a respond() method.

package HasRespond { sub new { bless {}, shift } sub respond { } }
package NoRespond  { sub new { bless {}, shift } }

ok is_response(PAGI::Response->new), 'a PAGI::Response is a response';
ok is_response(HasRespond->new),     'any blessed object with respond() is a response';

ok !is_response(undef),              'undef is not a response';
ok !is_response('text'),             'a plain string is not a response';
ok !is_response({}),                 'an unblessed hashref is not a response';
ok !is_response([]),                 'an unblessed arrayref is not a response';
ok !is_response(NoRespond->new),     'a blessed object without respond() is not a response';

is is_response(undef), 0,                  'returns a clean 0 for non-responses';
is is_response(HasRespond->new), 1,        'returns a clean 1 for responses';

done_testing;
