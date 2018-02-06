# -*- perl -*-

use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 6;

BEGIN { use_ok( 'SMS::Send::Driver::WebService' ); }

my $service = SMS::Send::Driver::WebService->new;

isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
isa_ok ($service->cfg, 'Config::IniFiles');
isa_ok ($service->ua, 'LWP::UserAgent');
isa_ok ($service->uat, 'HTTP::Tiny');
