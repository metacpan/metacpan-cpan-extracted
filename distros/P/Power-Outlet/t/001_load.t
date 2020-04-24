# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 69;

BEGIN { use_ok( 'Power::Outlet' ); }
BEGIN { use_ok( 'Power::Outlet::Common' ); }
BEGIN { use_ok( 'Power::Outlet::Common::IP' ); }
BEGIN { use_ok( 'Power::Outlet::Common::IP::SNMP' ); }
BEGIN { use_ok( 'Power::Outlet::Common::IP::HTTP' ); }
BEGIN { use_ok( 'Power::Outlet::Common::IP::HTTP::UPnP' ); }
BEGIN { use_ok( 'Power::Outlet::Common::IP::HTTP::JSON' ); }
BEGIN { use_ok( 'Power::Outlet::iBoot' ); }
BEGIN { use_ok( 'Power::Outlet::iBootBar' ); }
BEGIN { use_ok( 'Power::Outlet::WeMo' ); }
BEGIN { use_ok( 'Power::Outlet::Hue' ); }
BEGIN { use_ok( 'Power::Outlet::Tasmota' ); }
BEGIN { use_ok( 'Power::Outlet::SonoffDiy' ); }

{
my $object = Power::Outlet->new(type=>"Common");
isa_ok ($object, 'Power::Outlet::Common');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet->new(type=>"iBoot");
isa_ok ($object, 'Power::Outlet::iBoot');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet->new(type=>"iBootBar");
isa_ok ($object, 'Power::Outlet::iBootBar');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet->new(type=>"Hue");
isa_ok ($object, 'Power::Outlet::Hue');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet->new(type=>"Tasmota");
isa_ok ($object, 'Power::Outlet::Tasmota');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet->new(type=>"SonoffDiy");
isa_ok ($object, 'Power::Outlet::SonoffDiy');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet::Common->new;
isa_ok ($object, 'Power::Outlet::Common');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
}

{
my $object = Power::Outlet::Common::IP->new;
isa_ok ($object, 'Power::Outlet::Common::IP');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
}

{
my $object = Power::Outlet::Common::IP::SNMP->new;
isa_ok ($object, 'Power::Outlet::Common::IP::SNMP');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
can_ok($object, qw{snmp_get snmp_set snmp_session});
}

{
my $object = Power::Outlet::Common::IP::HTTP->new;
isa_ok ($object, 'Power::Outlet::Common::IP::HTTP');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
can_ok($object, qw{http_path});
}

{
my $object = Power::Outlet::Common::IP::HTTP::UPnP->new;
isa_ok ($object, 'Power::Outlet::Common::IP::HTTP::UPnP');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
can_ok($object, qw{http_path});
can_ok($object, qw{upnp_service_type});
}

{
my $object = Power::Outlet::iBoot->new;
isa_ok ($object, 'Power::Outlet::iBoot');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
}

{
my $object = Power::Outlet::iBootBar->new;
isa_ok ($object, 'Power::Outlet::iBootBar');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
can_ok($object, qw{snmp_get snmp_set snmp_session});
}

{
my $object = Power::Outlet::WeMo->new;
isa_ok ($object, 'Power::Outlet::WeMo');
can_ok($object, qw{new});
can_ok($object, qw{on off switch cycle query});
can_ok($object, qw{host port});
can_ok($object, qw{http_path});
can_ok($object, qw{upnp_service_type});
}
