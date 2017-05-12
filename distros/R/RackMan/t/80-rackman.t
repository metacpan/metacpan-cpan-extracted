#!perl -wT
use strict;
use warnings;
use Test::More;

plan skip_all => "needs to be adapted";

my @devices = (
    {
        name    => "apc-cc01.infra",
        roles   => [qw< PDU  PDU::APC_RackPDU >],
        methods => {
            object_type => "PDU",
        },
    },
    {
        name    => "apc-sg01.infra",
        roles   => [qw< PDU >],
        methods => {
            object_type => "PDU",
        },
    },
    {
        name    => "rikers.dev",
        roles   => [qw< Server >],
        methods => {
            object_type => "Server",
        },
    },
    {
        name    => "samus.infra",
        roles   => [qw< Switch  Switch::Cisco_Catalyst >],
        methods => {
            object_type => "Switch",
        },
    },
    {
        name    => "squeak.infra",
        roles   => [qw< Server  Server::HP_ProLiant >],
        methods => {
            object_type => "Server",
        },
    },
);

#plan tests => 27;
plan "no_plan";

# load the test config
use_ok "RackMan::Config";
my $config_path = "t/files/rack.conf";
my $config = eval { RackMan::Config->new(-file => $config_path) };
is $@, "", "RackMan::Config->new(-file => $config_path)";

# instanciate the main RackMan object
use_ok "RackMan";
my $rackman = eval {
    RackMan->new({ options => { scm => 0 }, config => $config })
};
is $@, "", "RackMan->new({ options => { scm => 0 }, config => \$config })";

# fetch the RackObject for some known devices
for my $dev (@devices) {
    note "- " x 20;
    my $rackobj = eval { $rackman->device($dev->{name}) };
    is $@, "", "\$rackman->device('$dev->{name}')";
    isa_ok $rackobj, "RackMan::Device", "{$dev->{name}}";

  # XXX This has to be fixed at some point to make the test useful
  TODO: { local $TODO = "fix the MySQL to SQLite conversion problem";
    for my $role (@{ $dev->{roles} }) {
        my $module = "RackMan::Device::$role";
        ok $rackobj->DOES($module), "{$dev->{name}} isa $module";
    }
  }

    for my $method (keys %{ $dev->{methods} }) {
        is $rackobj->$method, $dev->{methods}{$method},
            "{$dev->{name}}->$method = $dev->{methods}{$method}";
    }
}

