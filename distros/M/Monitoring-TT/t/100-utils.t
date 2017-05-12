use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

use_ok('Monitoring::TT');

my $montt     = Monitoring::TT->new();
my $types     = $montt->_get_input_classes();
my $types_exp = ['CSV', 'Nagios'];
is_deeply($types, $types_exp, 'got types') or diag(Dumper($types));

my $tags     = 'net_http,net_https,net_https=443,net_https=8443';
my $got      = Monitoring::TT::Utils::parse_tags($tags);
my $tags_exp = {
           'net_https' => [
                            '',
                            '443',
                            '8443'
                          ],
           'net_http' => ''
         };
is_deeply($got, $tags_exp, 'tag parser') or diag(Dumper($got));
