use strict;
use warnings;

use Test::More tests => 9;

{
    package Basic::Log::Test;

    use Moose;
    with 'Role::Log::Syslog::Fast';

    1;
}


my $obj = new Basic::Log::Test;

isa_ok($obj, 'Basic::Log::Test');


for my $item (qw/_logger _proto _hostname _port _facility _severity _sender _name/) {
    ok($obj->can($item), 'Role method $item exists');
}

1;


