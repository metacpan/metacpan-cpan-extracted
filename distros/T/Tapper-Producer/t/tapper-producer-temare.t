use Test::More tests => 3;


use strict;
use warnings;
use Try::Tiny;

BEGIN{
        use_ok('Tapper::Producer::Temare');
}

my $producer = Tapper::Producer::Temare->new();
isa_ok($producer, 'Tapper::Producer::Temare');

{package Host; sub name {'name'}; 1;}
{package Testrun; sub host { bless {}, 'Host' } 1;}

my $obj = bless ({ }, 'Testrun');
try{
        my $result = $producer->produce($obj, {subject => 'subject', bitness => 64});
        fail('Producer dies');
        use Data::Dumper;
        diag Dumper $result;
} catch {
        like ($_,qr/YAML_PARSE_ERR/, 'YAML error catched');
}
