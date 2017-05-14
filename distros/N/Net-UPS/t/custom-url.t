#!perl
use strict;
use warnings;
use Test::More;
use Net::UPS;
use File::Temp 'tempfile';

my ($fh,$filename) = tempfile();
print $fh <<'CONFIG';
UPSUserID user
UPSPassword pass
UPSAccessKey accesskey
UPSAVProxy http://my/av
UPSRateProxy http://my/rate
CONFIG
flush $fh;

for my $ups (
    Net::UPS->new('user','pass','accesskey',{
        av_proxy => 'http://my/av',
        rate_proxy => 'http://my/rate',
    }),
    Net::UPS->new($filename),
) {
    is($ups->userid,'user','user set');
    is($ups->password,'pass','password set');
    is($ups->av_proxy,'http://my/av',
       'AV url set');
    is($ups->rate_proxy,'http://my/rate',
       'Rate url set');
}

done_testing();
