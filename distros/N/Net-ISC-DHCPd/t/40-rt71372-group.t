use warnings;
use strict;
use lib qw(lib);
use Test::More;
BEGIN { $ENV{'ISC_DHCPD_TRACE'} = 1 }
use Net::ISC::DHCPd::Config;

plan skip_all => 'no t/data/rt71372.conf' unless(-r 't/data/rt71372.conf');
plan tests => 14;

{
    my $config = Net::ISC::DHCPd::Config->new(file => 't/data/rt71372.conf');
    my $config_text = do { open my $FH, 't/data/rt71372.conf'; local $/; <$FH> };
    my @subnets;

    $config->parse;

    is(scalar(@_=$config->includes), 1, "includes");
    is(scalar(@_=$config->keys), 1, "keys");
    is(scalar(@_=$config->keyvalues), 9, "key values");
    is(scalar(@_=$config->optioncodes), 2, "optioncodes");
    is(scalar(@_=$config->subnets), 1, "subnets");
    is(scalar(@_=$config->groups), 1, "groups");
    is(scalar(@_=$config->blocks), 0, "blocks");
    is(scalar(@subnets=$config->subnets), 1, "subnets");
    is(scalar(@_=$subnets[0]->options), 9, "subnet -> options");
    is(scalar(@_=$subnets[0]->keyvalues), 2, "subnet -> keyvalues");
    is(scalar(@_=$subnets[0]->pools), 2, "subnet -> pools");
    is($subnets[0]->pools->[0]->_comments->[0], q(pool "Studenten_DHCP"), "subnet -> pool -> comment");
    is(scalar(@_=$subnets[0]->classes), 2, "subnet -> classes");
    is($config->generate, $config_text, 'config output == config input');
}
