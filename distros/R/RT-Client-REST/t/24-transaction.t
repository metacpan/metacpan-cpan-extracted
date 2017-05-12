use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;

use constant METHODS => (
    'new', 'to_form', 'from_form', 'rt_type',
    
    # attrubutes:
    'id', 'creator', 'type', 'old_value', 'new_value', 'parent_id',
    'attachments', 'time_taken', 'field', 'content', 'created',
    'description', 'data',
);

BEGIN {
    use_ok('RT::Client::REST::Transaction');
}

for my $method (METHODS) {
    can_ok('RT::Client::REST::Transaction', $method);
}

my $tr;

lives_ok {
    $tr = RT::Client::REST::Transaction->new;
} 'Transaction can get successfully instantiated';

for my $method (qw(store search count)) {
    throws_ok {
        $tr->$method;
    } 'RT::Client::REST::Object::IllegalMethodException',
        "method '$method' should throw an exception";
}

ok('transaction' eq $tr->rt_type);

# vim:ft=perl:
