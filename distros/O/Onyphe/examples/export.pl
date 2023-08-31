#!/usr/bin/env perl
#
# $Id: export.pl,v 4089618a5aa7 2023/03/07 13:36:19 gomor $
#
use strict;
use warnings;

use Data::Dumper;
use Onyphe::Api;

use OPP;
use OPP::State;
use OPP::Output;

my $opp = OPP->new;
$opp->nested([ 'app.http.component' ]);
$opp->state(OPP::State->new->init);
$opp->output(OPP::Output->new->init);

my $opp_cb = sub {
   my ($results) = @_;
   $opp->process_as_json($results, 'uniq domain | addcount');
};

my $oa = Onyphe::Api->new->init;

$oa->export('protocol:ssh', $opp_cb);
