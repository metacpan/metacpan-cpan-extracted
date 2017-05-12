use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

my $config = TestUtil::config();
plan skip_all => "no config" unless $config;

plan tests => 2;
my $sn = TestUtil::getSession();

SKIP : {
    my $ws = $config->{web_service};
    skip "web_service not defined", 2 unless $ws;
    my $name = $ws->{name};
    skip "web_service name not defined", 2 unless $name;
    note "execute Web Service \"$name\"";
    my %inputs = %{$ws->{inputs}};
    my @outnames = @{$ws->{outputs}};
    my $outputs = $sn->execute($name, %inputs);
    ok (ref $outputs eq 'HASH', "call returned hash");
    my $need = @outnames;
    my $good = 0;
    foreach my $name (@outnames) {
        my $value = $outputs->{$name} || 'UNDEFINED';
        note "$name=$value";
        $good++ if defined $outputs->{$name};
    }
    ok ($good == $need, "$good of $need outputs defined");
}

1;
