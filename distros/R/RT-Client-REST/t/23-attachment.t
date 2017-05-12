use strict;
use warnings;

use Test::More tests => 26;
use Test::Exception;

use constant METHODS => (
    'new', 'to_form', 'from_form', 'rt_type',
    
    # attrubutes:
    'id', 'creator_id', 'subject', 'created', 'message_id', 'parent_id',
    'content_type', 'file_name', 'transaction_id', 'content', 'headers',
    'parent', 'content_encoding',
);

BEGIN {
    use_ok('RT::Client::REST::Attachment');
}

for my $method (METHODS) {
    can_ok('RT::Client::REST::Attachment', $method);
}

my $ticket;

lives_ok {
    $ticket = RT::Client::REST::Attachment->new;
} 'Ticket can get successfully created';

for my $method (qw(store search count)) {
    throws_ok {
        $ticket->$method;
    } 'RT::Client::REST::Exception'; # make sure exception inheritance works

    throws_ok {
        $ticket->$method;
    } 'RT::Client::REST::Object::IllegalMethodException',
        "method '$method' should throw an exception";
}

ok('attachment' eq $ticket->rt_type);

# vim:ft=perl:
