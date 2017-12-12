#!/usr/bin/perl

# this is like bin/peri-htserve, where you specify some modules (via environment
# PERL_MODULES) and this webapp will let you access those modules via Riap::HTTP
# protocol. how to use:
#
#  % PERL_MODULES="Perinci::Examples Calendar::Indonesia::Holiday" plackup -Ilib examples/perl-some.psgi
#
# then access, e.g. using:
#
#  % curl http://localhost:5000/Perinci/Examples/gen_array?len=5
#  % perl -ML -E'$pa = Perinci::Access->new; $res = $pa->request(call => "/Calendar/Indonesia/Holiday/list_id_holidays", {args=>{year=>2014}});'
#
# Note that on the second example, you need the 'L' module.

use 5.010;
use strict;
use warnings;

use Module::Load;
use Perinci::Access::Base::Patch::PeriAHS;
use Perinci::Access::Schemeless;
use Plack::Builder;

my @modules = split /\s*[,;]\s*|\s+/, ($ENV{PERL_MODULES} // "");
@modules or die "Please specify modules to load (via PERL_MODULES)\n";
load $_ for @modules;

my $app = builder {
    enable(
        "PeriAHS::ParseRequest",
        riap_client => Perinci::Access::Schemeless->new(
            load        => 0,
            allow_paths => [map {my $str = $_; $str =~ s!::!/!g; "/$str"} @modules],
        ),
    );

    enable "PeriAHS::Respond";
};
