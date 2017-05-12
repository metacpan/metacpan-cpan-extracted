#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;


use Test::More;
use Test::Warn;

plan tests => 3;




my $regexp = qr /redefining rule 'rule1' for package/;

print "regexp is '$regexp'\n";


warning_like {
		use lib 'lib';
		use Parse::Gnaw 'rule';


		rule('rule1', 
			'a', 
			'b');
	
		rule('rule1', 
			'c', 
			'd',
			'e',
		);

		no strict 'vars';

		ok(scalar(@$rule1)==4, "check rule1 is size4, can only be size4 if new rule1 replaced old rule1");


		print Dumper $rule1;


	}
	$regexp,
	" rule has been redefined warning was received "
;


# make sure there are no error messages, no "die" calls.
ok(not($@), "check that there are no eval errors");

print "error message expected '',  actual '$@'\n";



__DATA__

This is trying to show how the code would work for rule redefinition.

If user declares a rule of the same name, throw a warning and replace old rule wiht new rule.

original rule: $VAR1 = 'rule1';
new rule: $VAR1 = {
          'methodname' => 'rule',
          'filename' => 't/gnaw_rule_redefine.t',
          'linenum' => 32,
          'payload' => 'rule1',
          'quantifier' => '',
          'package' => 'main'
        };


$VAR1 = [
          [
            'rule',
            'rule1',
            {
              'methodname' => 'rule',
              'filename' => 't/gnaw_rule_redefine.t',
              'linenum' => 32,
              'payload' => 'rule1',
              'quantifier' => '',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'c',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule_redefine.t',
              'linenum' => 32,
              'payload' => 'c',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'd',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule_redefine.t',
              'linenum' => 32,
              'payload' => 'd',
              'package' => 'main'
            }
          ],
          [
            'lit',
            'e',
            {
              'methodname' => 'lit',
              'filename' => 't/gnaw_rule_redefine.t',
              'linenum' => 32,
              'payload' => 'e',
              'package' => 'main'
            }
          ]
        ];





