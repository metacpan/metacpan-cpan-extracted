#!perl

use warnings;
use strict;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Prometheus::Tiny::Shared;

my $p = Prometheus::Tiny::Shared->new;
$p->declare('some_metric', help => 'My great metric', type => 'counter');
$p->set('some_metric', 5);

my $t = Plack::Test->create($p->psgi);
my $res = $t->request(GET '/');
is $res->content, <<EOF, 'psgi app formats metrics correctly';
# HELP some_metric My great metric
# TYPE some_metric counter
some_metric 5
EOF

done_testing;
