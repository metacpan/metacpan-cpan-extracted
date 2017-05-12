#!perl -wT
use strict;
use warnings;
use Test::More;


my @type_roles      = qw< PDU Server Switch >;
my @type_methods    = qw< formats specialise >;

my @subtype_roles   = qw<
    PDU::APC_RackPDU  Server::HP_ProLiant  Switch::Cisco_Catalyst
>;
my @subtype_methods = qw< write_config diff_config push_config >;

my @format_plugins  = qw<
    Bacula  Cacti  DHCP  PXE  Kickstart  LDAP  Nagios
>;
my @format_methods  = qw< write >;


plan tests => 2 * (@type_roles + @subtype_roles + @format_plugins);

# check type roles
for my $type (@type_roles) {
    my $module = "RackMan::Device::$type";
    use_ok $module;
    can_ok $module => @type_methods;
}

# check subtype roles
for my $subtype (@subtype_roles) {
    my $module = "RackMan::Device::$subtype";
    use_ok $module;
    can_ok $module => @subtype_methods;
}

# check format roles
for my $format (@format_plugins) {
    my $module = "RackMan::Format::$format";
    use_ok $module;
    can_ok $module => @format_methods;
}

