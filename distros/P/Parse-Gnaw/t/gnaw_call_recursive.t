#!perl -T

use 5.006;
use strict;
no  strict 'vars';
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;
use lib 'lib';

use Test::More;

plan tests => 2;

eval{
		use lib 'lib';
		use Parse::Gnaw;

		predeclare('myrule');

		rule('myrule', 
			'c', 
			call('myrule'),
		);

};

if($@){
	print "something went wrong. \$@ should be '' but it is '$@'\n";
}

ok(not($@), "check that we don't get any errors about nonexistent rule or anything");

print Dumper $myrule;

ok(scalar(@$myrule)==3, "check that myrule is 3 deep");

__DATA__


$VAR1 = [
          [
            'rule',
            'myrule',
            {
              'methodname' => 'rule',
              'filename' => 't/gnaw_call_recursive.t',
              'linenum' => 21,
              'payload' => 'myrule',
              'quantifier' => '',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'c',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_call_recursive.t',
              'linenum' => 21,
              'payload' => 'c',
              'package' => 'main'
            }
          ],
          [
            'call',
            'myrule',
            {
              'methodname' => 'call',
              'filename' => 't/gnaw_call_recursive.t',
              'payload' => 'myrule',
              'linenum' => 21,
              'package' => 'main'
            }
          ]
        ];


