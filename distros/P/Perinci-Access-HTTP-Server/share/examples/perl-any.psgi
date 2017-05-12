#!/usr/bin/perl

# this is like bin/peri-htserve, except that it allows dynamically loading all
# modules. not recommended for production, obviously. how to use:
#
#  % plackup -Ilib examples/perl-any.psgi
#
# then access, e.g. using:
#
#  % curl http://localhost:5000/Perinci/Examples/gen_array?len=5
#  % perl -ML -E'$pa = Perinci::Access->new; $res = $pa->request(call => "/Calendar/Indonesia/Holiday/list_id_holidays", {args=>{year=>2014}});'
#
# for the examples, you need the 'Perinci::Examples', 'L' and
# 'Calendar::Indonesia::Holiday' modules installed.

use 5.010;
use strict;
use warnings;

use Perinci::Access::Base::Patch::PeriAHS;
use Perinci::Access::Schemeless;
use Plack::Builder;

my $app = builder {
    enable(
        "PeriAHS::ParseRequest",
        riap_client => Perinci::Access::Schemeless->new, # load=>1 (default)
    );

    enable "PeriAHS::Respond";
};
