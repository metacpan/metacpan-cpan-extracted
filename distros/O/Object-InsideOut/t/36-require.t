use strict;
use warnings;

use lib 't';

use Test::More 'tests' => 8;

{
    my $class = 'Req2';
    eval "require $class";
    ok(! $@, ($@)?$@:'eval ok');
    my $n = $class->new(field => 'ciao');
    my $m = Req2->new(field => 'a tutti');
    is($n->get_field(), 'ciao', 'field value for $n');
    is($m->get_field(), 'a tutti', 'field value for $m');
}

{
    my $class = 'Req3';
    eval "require $class";
    ok(! $@, ($@)?$@:'eval ok');
    my $n = $class->new(field => 'ciao', 'fld' => 'foo');
    my $m = Req3->new(field => 'a tutti', 'fld' => 'bar');
    is($n->get_field(), 'ciao', 'field value for $n');
    is($m->get_field(), 'a tutti', 'field value for $m');
    is($n->get_fld(), 'foo', 'field value for $n');
    is($m->get_fld(), 'bar', 'field value for $m');
}

exit(0);

# EOF
