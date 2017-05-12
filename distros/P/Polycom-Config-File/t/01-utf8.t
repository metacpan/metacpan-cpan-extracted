# Before `make install' is performed this script should be runnable with
# `make test'.

#########################
use utf8;
use Test::More tests => 4;
BEGIN { use_ok('Polycom::Config::File') };

# Test that we can parse a simple config file with non-ASCII utf8 characters
my $xml = <<'CFG_XML';
<?xml version="1.0" standalone="yes"?>
<localcfg>
   <reg reg.1.label="àæøý" reg.2.label="ГДЕЅЗ" reg.3.label="マージャン"/>
</localcfg>
CFG_XML

my $cfg = Polycom::Config::File->new($xml);
is($cfg->params->{'reg.1.label'}, 'àæøý');
is($cfg->params->{'reg.2.label'}, 'ГДЕЅЗ');
is($cfg->params->{'reg.3.label'}, 'マージャン');


