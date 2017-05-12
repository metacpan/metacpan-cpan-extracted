# Before `make install' is performed this script should be runnable with
# `make test'.

#########################
use utf8;
use Test::More tests => 3;
BEGIN { use_ok('Polycom::Config::File') };

# Test that we can parse a simple config file with XML char entities
my $xml = <<'CFG_XML';
<?xml version="1.0" standalone="yes"?>
<localcfg>
   <reg reg.1.label="&amp;&lt;&quot;" reg.2.label="&gt;&apos;"/>
</localcfg>
CFG_XML

my $cfg = Polycom::Config::File->new($xml);
is($cfg->params->{'reg.1.label'}, '&<"');
is($cfg->params->{'reg.2.label'}, ">'");


