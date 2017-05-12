# Before `make install' is performed this script should be runnable with
# `make test'.

#########################

use Test::More tests => 4;
BEGIN { use_ok('Polycom::Config::File') };

# Test that the appropriate methods exist
can_ok('Polycom::Config::File', qw(new equals params path save to_xml));

# Test that we can parse a very simple config file
my $xml = <<'CFG_XML';
<?xml version="1.0" standalone="yes"?>
<localcfg>
   <server voIpProt.server.1.address="test.example.com"/>
   <digitmap
dialplan.digitmap="[2-9]11|0T|011xxx.T|[0-1][2-9]xxxxxxxxx|604xxxxxxx|778xxxxxxx|[2-4]xxx"/>
</localcfg>
CFG_XML

# Test that we can parse the simplest of config files
my $cfg = Polycom::Config::File->new($xml);
is($cfg->params->{'voIpProt.server.1.address'}, 'test.example.com');
is($cfg->params->{'dialplan.digitmap'}, '[2-9]11|0T|011xxx.T|[0-1][2-9]xxxxxxxxx|604xxxxxxx|778xxxxxxx|[2-4]xxx');
