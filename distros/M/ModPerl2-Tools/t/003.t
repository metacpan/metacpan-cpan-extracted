# -*- mode: cperl; cperl-indent-level: 4; cperl-continued-statement-offset: 4; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test qw{-withtestmore};
use Apache::TestUtil;
use Apache::TestRequest qw{GET_BODY GET};

plan tests=>3;
#plan 'no_plan';

Apache::TestRequest::user_agent(reset => 1,
				requests_redirectable => 0);

my $resp;

####################################################################
# $f->save_die
####################################################################

$resp=GET '/filter_die';
ok $resp, '/filter_die: response object';
ok t_cmp $resp->code, 410, '/filter_die: code';
ok t_cmp $resp->content, qr!<title>410 Gone</title>!i,
         '/filter_die: content';
