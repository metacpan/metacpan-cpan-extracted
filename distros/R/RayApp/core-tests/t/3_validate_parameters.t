
#!/usr/bin/perl -Tw

use Test::More tests => 20;

use warnings;
$^W = 1;
use strict;

BEGIN { use_ok( 'RayApp' ); }

my $rayapp = new RayApp;
isa_ok($rayapp, 'RayApp');

my $dsd;

ok($dsd = $rayapp->load_dsd_string('<?xml version="1.0"?>
<application>
	<id type="int"/>
	<_param name="jezek" />
	<_param prefix="xx" />
	<_param name="id" multiple="yes"/>
	<_param name="int" type="int"/>
	<_param name="num" type="num"/>
</application>
'), 'Load DSD with parameters');
is($rayapp->errstr, undef, 'Errstr should not be set');

is($dsd->validate_parameters(
	[
	'jezek' => 'krtek',
	'xx-1' => '14',
	'xx-2' => 34,
	'int' => -56,
	'num' => '+13.6',
	'id' => 14,
	'id' => 'fourteen',
	]
	), 1,
	'Check valid parameters, should not fail.');
is($dsd->errstr, undef, 'Errstr should not be set');

is($dsd->validate_parameters(
	[
	'jezek1' => 'krtek',
	'xx-1' => '14',
	'xx-1' => 34,
	'int' => 'x-56',
	'num' => 'four',
	]
	), undef,
	'Check valid parameters, should not fail.');
is($dsd->errstr,
	qq!Parameter 'int' has non-integer value ['x-56']\nUnknown parameter 'jezek1'='krtek'\nParameter 'num' has non-numeric value ['four']\nParameter 'xx-1' has multiple values ['14', '34']\n!,
	'Errstr should not be set');

ok($dsd = $rayapp->load_dsd("t/complex_param1.xml"),
        'Loading correct DSD t/complex_param1.xml');
	is($rayapp->errstr, undef, 'Checking that there was no error');
my @parameters = (
	'id' => 123,
	'action' => 'save',
	'ns[1]/id' => 89,
	'ns[1]/name' => 'First',
	'ns[1]/ip[1]/type' => 'ipv4',
	'ns[1]/ip[1]/value' => '127.0.0.1',
	'ns[1]/ip[3]/type' => 'ipv1',
	'ns[1]/ip[3]/value' => 1,
	'ns[3]/name' => 'Third',
	);
is($dsd->validate_parameters( \@parameters), 1, 'Check valid parameters, should not fail.');
is($dsd->errstr, undef, 'Errstr should not be set');
is_deeply(\@parameters,
	[
          'id',
          123,
          'action',
          'save',
          'ns[1]/id',
          89,
          'ns[1]/name',
          'First',
          'ns[1]/ip[1]/type',
          'ipv4',
          'ns[1]/ip[1]/value',
          '127.0.0.1',
          'ns[1]/ip[3]/type',
          'ipv1',
          'ns[1]/ip[3]/value',
          1,
          'ns[3]/name',
          'Third',
          'ns',
          [
            {
              'ip' => [
                        {
                          'value' => [ '127.0.0.1' ],
                          'type' => [ 'ipv4' ]
                        },
                        {
                          'value' => [ 1 ],
                          'type' => [ 'ipv1' ]
                        }
                      ],
              'name' => [ 'First' ],
              'id' => [ 89 ]
            },
            {
              'name' => [ 'Third' ]
            }
          ]
	], 'After sucessfull validation, parameters should be altered');

my %parameters = (
	'id' => 123,
	'action' => 'save',
	'ns[1]/id' => 89,
	'ns[1]/name' => 'First',
	'ns[1]/ip[1]/type' => 'ipv4',
	'ns[1]/ip[1]/value' => '127.0.0.1',
	'ns[1]/ip[3]/type' => 'ipv1',
	'ns[1]/ip[3]/value' => 1,
	'ns[3]/name' => 'Third',
	);
is($dsd->validate_parameters( \%parameters), 1, 'Check valid parameters, should not fail.');
is($dsd->errstr, undef, 'Errstr should not be set');
is_deeply(\%parameters,
	{
          'ns[1]/ip[3]/type' => 'ipv1',
          'ns[3]/name' => 'Third',
          'ns[1]/id' => 89,
          'ns' => [
                    {
                      'ip' => [
                                {
                                  'value' => [ '127.0.0.1' ],
                                  'type' => [ 'ipv4' ]
                                },
                                {
                                  'value' => [ 1 ],
                                  'type' => [ 'ipv1' ]
                                }
                              ],
                      'name' => [ 'First' ],
                      'id' => [ 89 ]
                    },
                    {
                      'name' => [ 'Third' ]
                    }
                  ],
          'ns[1]/ip[3]/value' => 1,
          'action' => 'save',
          'id' => 123,
          'ns[1]/name' => 'First',
          'ns[1]/ip[1]/type' => 'ipv4',
          'ns[1]/ip[1]/value' => '127.0.0.1'
	}, 'After sucessfull validation, parameters should be altered');

ok($dsd = $rayapp->load_dsd("t/complex_param1.xml"),
        'Loading correct DSD t/complex_param1.xml');
	is($rayapp->errstr, undef, 'Checking that there was no error');
is($dsd->validate_parameters(
	[
	'id' => 123,
	'action' => 'save',
	'ns[1]/id' => 'Name',
	'ns[1]/name' => 'First',
	'ns[1]/ip[1]/type[4]' => 'ipv4',
	'ns[3]/name' => 'Third',
	]
	), undef,
	'Check valid parameters, should not fail.');
is($dsd->errstr,
	qq!Parameter 'ns[1]/id' has non-integer value ['Name']\nParameter 'ns[1]/ip[1]/type[4]' does not match structure parameter name at 'type[4]'\n!,
	'Errstr should be set');
