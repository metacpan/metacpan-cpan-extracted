#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 267;

use FindBin qw($Bin);
use_ok('Net::Respite::Validate');

my $v;
my $e;

sub validate { scalar Net::Respite::Validate->new->validate(@_) }

### required
$v = {foo => {required => 1, alias => 'ffoooo'}};
$e = validate({}, $v);
ok($e, 'required => 1 - fail');

$e = validate({foo => 1}, $v);
ok(! $e, 'required => 1 - good');

$e = validate({ffoooo => 1}, $v);
ok(! $e, 'required => 1 (with alias) - good');

### validate_if
$v = {foo => {required => 1, validate_if => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'validate_if - true');

$e = validate({bar => 1}, $v);
ok($e, 'validate_if - false');

$v = {text1 => {required => 1, validate_if => 'text2 was_valid'}, text2 => {validate_if => 'text3'}};
$e = validate({}, $v);
ok(! $e, "Got no error on validate_if with was_valid");
$e = validate({text2 => 1}, $v);
ok(! $e, "Got no error on validate_if with was_valid with non-validated data");
$e = validate({text3 => 1}, $v);
ok(! $e, "Got no error on validate_if with was_valid with validated - bad data");
$e = validate({text2 => 1, text3 => 1}, $v);
ok(! $e, "Got error on validate_if with was_valid with validated - good data");
$e = validate({text1 => 1, text2 => 1, text3 => 1}, $v);
ok(! $e, "No error on validate_if with was_valid with validated - good data");

$v = {text1 => {required => 1, validate_if => 'text2 had_error'}, text2 => {required => 1}};
$e = validate({}, $v);
ok($e, "Got error on validate_if with had_error");
$e = validate({text2 => 1}, $v);
ok(! $e, "No error on validate_if with had_error and bad_data");
$e = validate({text1 => 1}, $v);
ok($e && ! $e->{'text1'}, "No error on validate_if with had_error and good data");

$e = validate({text1 => ""}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2'}});
ok(!$e, "validate_ifstr - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2'}});
ok($e, "validate_ifstr - had error");

$e = validate({text1 => ""}, {'m/^(tex)t1$/' => {required => 1, validate_if => {field => '$1t2',required => 1}}});
ok(!$e, "validate_if - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => {field => '$1t2',required => 1}}});
ok($e, "validate_if - had error");

$e = validate({text1 => ""}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2 was_valid'}});
ok(!$e, "was valid - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2 was_valid'}});
ok(!$e, "was valid - no error");

$e = validate({text1 => "", text2 => 1}, {'m/^(tex)t1$/' => {required => 1, validate_if => '$1t2 was_valid'}, text2 => {required => 1}, 'group order' => [qw(text2)]});
ok($e, "was valid - had error");

### required_if
$v = {foo => {required_if => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'required_if - false');

$e = validate({bar => 1}, $v);
ok($e , 'required_if - true');

### max_values
$v = {foo => {required => 1}};
$e = validate({foo => [1,2]}, $v);
ok($e, 'max_values');

$v = {foo => {max_values => 2}};
$e = validate({}, $v);
ok(! $e, 'max_values');

$e = validate({foo => "str"}, $v);
ok(! $e, 'max_values');

$e = validate({foo => [1]}, $v);
ok(! $e, 'max_values');

$e = validate({foo => [1,2]}, $v);
ok(! $e, 'max_values');

$e = validate({foo => [1,2,3]}, $v);
ok($e, 'max_values');

### min_values
$v = {foo => {min_values => 3, max_values => 10}};
$e = validate({foo => [1,2,3]}, $v);
ok(! $e, 'min_values');

$e = validate({foo => [1,2,3,4]}, $v);
ok(! $e, 'min_values');

$e = validate({foo => [1,2]}, $v);
ok($e, 'min_values');

$e = validate({foo => "str"}, $v);
ok($e, 'min_values');

$e = validate({}, $v);
ok($e, 'min_values');

### enum
$v = {foo => {enum => [1, 2, 3]}, bar => {enum => "1 || 2||3"}};
$e = validate({}, $v);
ok($e, 'enum');

$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'enum');

$e = validate({foo => 1, bar => 2}, $v);
ok(! $e, 'enum');

$v->{'foo'}->{'match'} = 'm/3/';
$e = validate({foo => 1, bar => 2}, $v);
ok($e, 'enum');
is($e->{'foo'}, "foo contains invalid characters.", 'enum shortcircuit');

$e = validate({foo => 4, bar => 1}, $v);
ok($e, 'enum');
is($e->{'foo'}, "foo is not in the given list.", 'enum shortcircuit');

# equals
$v = {foo => {equals => 'bar'}};
$e = validate({}, $v);
ok(! $e, 'equals');

$e = validate({foo => 1}, $v);
ok($e, 'equals');

$e = validate({bar => 1}, $v);
ok($e, 'equals');

$e = validate({foo => 1, bar => 2}, $v);
ok($e, 'equals');

$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'equals');

$v = {foo => {equals => '"bar"'}};
$e = validate({foo => 1, bar => 1}, $v);
ok($e, 'equals');

$e = validate({foo => 'bar', bar => 1}, $v);
ok(! $e, 'equals');

$e = validate({text1 => "foo", text2 =>  "bar"}, {'m/^(tex)t1$/' => {equals => '$1t2'}});
ok($e, "equals - had error");

$e = validate({text1 => "foo", text2 => "foo"}, {'m/^(tex)t1$/' => {equals => '$1t2'}});
ok(!$e, "equals - no error");


### min_len
$v = {foo => {min_len => 10}};
$e = validate({}, $v);
ok($e, 'min_len');

$e = validate({foo => ""}, $v);
ok($e, 'min_len');

$e = validate({foo => "123456789"}, $v);
ok($e, 'min_len');

$e = validate({foo => "1234567890"}, $v);
ok(! $e, 'min_len');

### max_len
$v = {foo => {max_len => 10}};
$e = validate({}, $v);
ok(! $e, 'max_len');

$e = validate({foo => ""}, $v);
ok(! $e, 'max_len');

$e = validate({foo => "1234567890"}, $v);
ok(! $e, 'max_len');

$e = validate({foo => "12345678901"}, $v);
ok($e, 'max_len');

### match
$v = {foo => {match => qr/^\w+$/}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc."}, $v);
ok($e, 'match');

$v = {foo => {match => [qr/^\w+$/, qr/^[a-z]+$/]}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc1"}, $v);
ok($e, 'match');

$v = {foo => {match => 'm/^\w+$/'}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc."}, $v);
ok($e, 'match');

$v = {foo => {match => 'm/^\w+$/ || m/^[a-z]+$/'}};
$e = validate({foo => "abc"}, $v);
ok(! $e, 'match');

$e = validate({foo => "abc1"}, $v);
ok($e, 'match');

$v = {foo => {match => '! m/^\w+$/'}};
$e = validate({foo => "abc"}, $v);
ok($e, 'match');

$e = validate({foo => "abc."}, $v);
ok(! $e, 'match');

$v = {foo => {match => 'm/^\w+$/'}};
$e = validate({}, $v);
ok($e, 'match');

$v = {foo => {match => '! m/^\w+$/'}};
$e = validate({}, $v);
ok(! $e, 'match');

### compare
$v = {foo => {compare => '> 0'}};
$e = validate({}, $v);
ok($e, 'compare');
$v = {foo => {compare => '== 0'}};
$e = validate({}, $v);
ok(! $e, 'compare');
$v = {foo => {compare => '< 0'}};
$e = validate({}, $v);
ok($e, 'compare');

$v = {foo => {compare => '> 10'}};
$e = validate({foo => 11}, $v);
ok(! $e, 'compare');
$e = validate({foo => 10}, $v);
ok($e, 'compare');

$v = {foo => {compare => '== 10'}};
$e = validate({foo => 11}, $v);
ok($e, 'compare');
$e = validate({foo => 10}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => '< 10'}};
$e = validate({foo => 9}, $v);
ok(! $e, 'compare');
$e = validate({foo => 10}, $v);
ok($e, 'compare');

$v = {foo => {compare => '>= 10'}};
$e = validate({foo => 10}, $v);
ok(! $e, 'compare');
$e = validate({foo => 9}, $v);
ok($e, 'compare');

$v = {foo => {compare => '!= 10'}};
$e = validate({foo => 10}, $v);
ok($e, 'compare');
$e = validate({foo => 9}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => '<= 10'}};
$e = validate({foo => 11}, $v);
ok($e, 'compare');
$e = validate({foo => 10}, $v);
ok(! $e, 'compare');


$v = {foo => {compare => 'gt ""'}};
$e = validate({}, $v);
ok($e, 'compare');
$v = {foo => {compare => 'eq ""'}};
$e = validate({}, $v);
ok(! $e, 'compare');
$v = {foo => {compare => 'lt ""'}};
$e = validate({}, $v);
ok($e, 'compare'); # 68

$v = {foo => {compare => 'gt "c"'}};
$e = validate({foo => 'd'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'c'}, $v);
ok($e, 'compare');

$v = {foo => {compare => 'eq c'}};
$e = validate({foo => 'd'}, $v);
ok($e, 'compare');
$e = validate({foo => 'c'}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => 'lt c'}};
$e = validate({foo => 'b'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'c'}, $v);
ok($e, 'compare');

$v = {foo => {compare => 'ge c'}};
$e = validate({foo => 'c'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'b'}, $v);
ok($e, 'compare');

$v = {foo => {compare => 'ne c'}};
$e = validate({foo => 'c'}, $v);
ok($e, 'compare');
$e = validate({foo => 'b'}, $v);
ok(! $e, 'compare');

$v = {foo => {compare => 'le c'}};
$e = validate({foo => 'd'}, $v);
ok($e, 'compare');
$e = validate({foo => 'c'}, $v);
ok(! $e, 'compare');


$v = {foo => {compare => 'le field:bar'}};
$e = validate({foo => 'd', bar => 'c'}, $v);
ok($e, 'compare');
$e = validate({foo => 'c', bar => 'c'}, $v);
ok(! $e, 'compare');
$e = validate({foo => 'c'}, $v);
ok($e, 'compare') || debug $e;
$e = validate({foo => ''}, $v);
ok(!$e, 'compare') || debug $e;


$v = {foo => {compare => '<= field:bar'}};
$e = validate({foo => 3, bar => 2}, $v);
ok($e, 'compare');
$e = validate({foo => 2, bar => 2}, $v);
ok(! $e, 'compare');
$e = validate({foo => 2}, $v);
ok($e, 'compare') || debug $e;
$e = validate({foo => 0}, $v);
ok(!$e, 'compare') || debug $e;

### sql
### can't really do anything here without prompting for a db connection

### custom
my $n = 1;
$v = {foo => {custom => $n}};
$e = validate({}, $v);
ok(! $e, 'custom');
$e = validate({foo => "str"}, $v);
ok(! $e, 'custom');

$n = 0;
$v = {foo => {custom => $n}};
$e = validate({}, $v);
ok($e, 'custom');
$e = validate({foo => "str"}, $v);
ok($e, 'custom');

$n = sub { my ($key, $val) = @_; return defined($val) ? 1 : 0};
$v = {foo => {custom => $n}};
$e = validate({}, $v);
ok($e, 'custom');
$e = validate({foo => "str"}, $v);
ok(! $e, 'custom');

$e = validate({foo => "str"}, {foo => {custom => sub { my ($k, $v) = @_; die "Always fail ($v)\n" }}});
ok($e, 'Got an error');
is($e->{'foo'}, "Always fail (str)", "Passed along the message from die");

### type checks
$v = {foo => {type => 'ip', match => 'm/^203\./'}};
$e = validate({foo => '209.108.25'}, $v);
ok($e, 'type ip');
is($e->{'foo'}, 'foo did not match type ip.', 'type ip'); # make sure they short circuit
$e = validate({foo => '209.108.25.111'}, $v);
ok($e, 'type ip - but had match error');
is($e->{'foo'}, 'foo contains invalid characters.', 'type ip');
$e = validate({foo => '203.108.25.111'}, $v);
ok(! $e, 'type ip');

$v = {foo => {type => 'domain'}};
$e = validate({foo => 'bar.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => 'bing.bar.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => 'bi-ng.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => '123456789012345678901234567890123456789012345678901234567890123.com'}, $v);
ok(! $e, 'type domain');
$e = validate({foo => 'xn--80aaaaaicw7bh5btdcjqe.xn--p1ai'}, $v);
ok(! $e, 'type domain');


$e = validate({foo => 'com'}, $v);
ok($e, 'type domain');
$e = validate({foo => 'bi-.com'}, $v);
ok($e, 'type domain');
$e = validate({foo => 'bi..com'}, $v);
ok($e, 'type domain');
$e = validate({foo => '1234567890123456789012345678901234567890123456789012345678901234.com'}, $v);
ok($e, 'type domain');

ok(!validate({n => $_}, {n => {type => 'num'}}),  "Type num $_")  for qw(0 2 23 -0 -2 -23 0.0 .1 0.1 0.10 1.0 1.01);
ok(!validate({n => $_}, {n => {type => 'unum'}}), "Type unum $_") for qw(0 2 23 0.0 .1 0.1 0.10 1.0 1.01);
ok(!validate({n => $_}, {n => {type => 'int'}}),  "Type int $_")  for qw(0 2 23 -0 -2 -23 2147483647 -2147483648);
ok(!validate({n => $_}, {n => {type => 'uint'}}), "Type uint $_") for qw(0 2 23 4294967295);
ok(validate({n => $_}, {n => {type  => 'num'}}),  "Type num invalid $_")  for qw(0a a2 -0a 0..0 00 001 1.);
ok(validate({n => $_}, {n => {type  => 'unum'}}), "Type unum invalid $_") for qw(0a a2 -0a 0..0 00 001 1. -5 -3.14);
ok(validate({n => $_}, {n => {type  => 'int'}}),  "Type int invalid $_")  for qw(1.1 0.1 0.0 -1.1 0a a2 a 00 001 2147483648 -2147483649);
ok(validate({n => $_}, {n => {type  => 'uint'}}), "Type uint invalid $_") for qw(-1 -0 1.1 0.1 0.0 -1.1 0a a2 a 00 001 4294967296);

### min_in_set checks
$v = {foo => {min_in_set => '2 of foo bar baz', max_values => 5}};
$e = validate({foo => 1}, $v);
ok($e, 'min_in_set');
$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'min_in_set');
$e = validate({foo => 1, bar => ''}, $v); # empty string doesn't count as value
ok($e, 'min_in_set');
$e = validate({foo => 1, bar => 0}, $v);
ok(! $e, 'min_in_set');
$e = validate({foo => [1, 2]}, $v);
ok(! $e, 'min_in_set');
$e = validate({foo => [1]}, $v);
ok($e, 'min_in_set');
$v = {foo => {min_in_set => '2 foo bar baz', max_values => 5}};
$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'min_in_set');

### max_in_set checks
$v = {foo => {max_in_set => '2 of foo bar baz', max_values => 5}};
$e = validate({foo => 1}, $v);
ok(! $e, 'max_in_set');
$e = validate({foo => 1, bar => 1}, $v);
ok(! $e, 'max_in_set');
$e = validate({foo => 1, bar => 1, baz => 1}, $v);
ok($e, 'max_in_set');
$e = validate({foo => [1, 2]}, $v);
ok(! $e, 'max_in_set');
$e = validate({foo => [1, 2, 3]}, $v);
ok($e, 'max_in_set');

### validate_if revisited (but negated - uses max_in_set)
$v = {foo => {required => 1, validate_if => '! bar'}};
$e = validate({}, $v);
ok($e, 'validate_if - negated');

$e = validate({bar => 1}, $v);
ok(! $e, 'validate_if - negated');

### default value
my $f = {};
$v = {foo => {required => 1, default => 'hmmmm'}};
$e = validate($f, $v);
ok(! $e, 'default');

ok($f->{foo} && $f->{foo} eq 'hmmmm', 'had right default');

### canonical field name
$f = {foo => 'test'};
$v = {foo => {required => 1, canonical => 'ffoooo'}};
$e = validate($f, $v);
ok(! $e, 'canonical');
ok($f->{'ffoooo'} && $f->{'ffoooo'} eq 'test', 'returned canonical field name');
ok(! $f->{'foo'}, 'did not return non-canonical field name');






###----------------------------------------------------------------###

### test single group for extra fields
$v = {
  'group no_extra_fields' => 1,
  foo => {max_len => 10},
};

$e = validate({}, $v);
ok(! $e);

$e = validate({foo => "foo"}, $v);
ok(! $e);

$e = validate({foo => "foo", bar => "bar"}, $v);
ok($e);

$e = validate({bar => "bar"}, $v);
ok($e);

$v = {
  'group no_extra_fields' => 1,
  foo => {max_values=>20,type=>{recursion=>{max_len=>10}}},
};

$e = validate({foo => { recursion => 1 }}, $v);
ok(!$e);

$e = validate({foo => [{},{},{ recursion => 1 }]}, $v);
ok(!$e) or note explain $e;

$e = validate({foo => { bar => 1 }}, $v);
ok($e);

$e = validate({foo => [{},{},{ bar => 1 }]}, $v);
ok($e);

### test on failed validate if
$v = {
  'group no_extra_fields' => 1,
  'group validate_if' => 'baz',
  foo => {max_len => 10},
};

$e = validate({}, $v);
ok(! $e);

$e = validate({foo => "foo"}, $v);
ok(! $e);

$e = validate({foo => "foo", bar => "bar"}, $v);
ok(! $e);

$e = validate({bar => "bar"}, $v);
ok(! $e);

### test on successful validate if
$v = {
  'group no_extra_fields' => 1,
  'group validate_if' => 'baz',
  foo => {max_len => 10},
  baz => {max_len => 10},
};

$e = validate({baz => 1}, $v);
ok(! $e);

$e = validate({baz => 1, foo => "foo"}, $v);
ok(! $e);

$e = validate({baz => 1, foo => "foo", bar => "bar"}, $v);
ok($e);

$e = validate({baz => 1, bar => "bar"}, $v);
ok($e);

### test on type field
$v = {
  'group no_extra_fields' => 1,
  foo => { },
};

$e = validate({foo => { bar => 1 }}, $v);
ok(! $e, 'No error when supplying a hashref when type is not defined') or note explain $e;

### test on type field
$v = {
  'group no_extra_fields' => 1,
  foo => { type => { bar => { max_len => 10 } } },
};

$e = validate({foo => { bar => 1 }}, $v);
ok(! $e, 'No error when supplying a hashref when type is defined as hashref') or note explain $e;

$e = validate({foo => { baz => 1 }}, $v);
ok($e, 'Error when supplying an extra field inside a hashref when type is defined as hashref');




###----------------------------------------------------------------###

$v = {
  foo => {
    max_len => 10,
    replace => 's/[^\d]//g',
  },
};

$e = validate({
  foo => '123-456-7890',
}, $v);
ok(! $e, "Didn't get error");


my $form = {
  key1 => 'Bu-nch @of characte#rs^',
  key2 => '123 456 7890',
  key3 => '123',
};


$v = {
  key1 => {
    replace => 's/[^\s\w]//g',
  },
};

$e = validate($form, $v);
ok(! $e, "No error");
is($form->{'key1'}, 'Bunch of characters',  "key1 updated");

$v = {
  key2 => {
    replace => 's/(\d{3})\D*(\d{3})\D*(\d{4})/($1) $2-$3/g',
  },
};

$e = validate($form, $v);
ok(! $e, "No error");
is($form->{'key2'}, '(123) 456-7890', "Phone updated");

$v = {
  key2 => {
    replace => 's/.+//g',
    required => 1,
  },
};

$e = validate($form, $v);
ok($e, "Error");
is($form->{'key2'}, '', "All replaced");

$v = {
    key3 => {
        replace => 's/\d//',
    },
};
$e = validate($form, $v);
ok(! $e, "No error");
is($form->{'key3'}, '23', "Non-global is fine");

###----------------------------------------------------------------###

$v = {
    foo => {
        validate_if => 'foo',
        type => {
            baz => {required => 1}, # required only if "foo" exists
        },
    },
};
$e = validate({}, $v);
ok(! $e, "Type hash, optional check") || debug $e;

$e = validate({foo => 1}, $v);
is_deeply($e, {foo => 'foo did not match type hash.'}, "Type hash, type check");

$e = validate({foo => {}}, $v);
is_deeply($e, {'foo.baz' => 'foo.baz is required.'}, "Type hash, inner required check");

$e = validate({foo => {baz => 1}}, $v);
ok(! $e, "Type hash, inner required ok");

$v = {
    foo => {
        max_values => 2,
        type => {
            baz => {required => 1}, # required only if "foo" exists
        },
    },
};
$e = validate({foo => {baz => 1}}, $v);
ok(! $e, "Type hash, array 1 element ok");

$e = validate({foo => []}, $v);
ok(! $e, "Type hash, array 0 elements ok");

$e = validate({foo => [{baz => 1},{baz=>2}]}, $v);
ok(! $e, "Type hash, array 2 elements ok");

$e = validate({foo => [{baz => 1},{baz=>2},{baz=>3}]}, $v);
is_deeply($e, {'foo' => 'foo had more than 2 values.'}, "Type hash, over max_values");

$e = validate({foo => [{baz => 1},{fail=>1}]}, $v);
is_deeply($e, {'foo.baz' => 'foo.baz is required.'}, "Type hash, inner required check");


$v = {
    foo => {
        type => {
            baz => {
                max_values => 2,
                type => {
                    bar => {},
                },
            },
        },
    },
};
$e = validate({foo => {baz => [{},{}]}}, $v);
ok(! $e, "Type hash, nested array 2 elements ok");

$e = validate({foo => {baz => [{},{},{}]}}, $v);
ok($e, "Type hash, nested array 3 elements, over max_values");


$v = {
    foo => {
        max_values => 3,
        type => {
            baz => {
                required => 1, # required only if "foo" exists
                default => '2',
            },
        },
        #validate_if => 'foo', #added later
    },
};

$form = {foo => [{baz => 1},{}]};
$e = validate($form, $v);
ok(! $e, "Type hash, array 2 elements ok");
is_deeply($form, { 'foo' => [ { 'baz' => 1 }, { 'baz' => '2' } ] }, 'defaults set without validate_if');

$v->{foo}{validate_if} = 'foo';

$form = { foo => [ {} ] };
$e = validate($form, $v);
ok(!$e, "Type hash, array 1 elements ok");
is_deeply($form, { 'foo' => [ { 'baz' => '2' } ] }, 'default works with validate_if');

$form = { foo => [ {baz=>1}, {x=>1}, {} ] };
$e = validate($form, $v);
ok(!$e, "Type hash, array 3 elements ok");
is_deeply($form, { 'foo' => [ {baz=>1}, {x=>1,baz=>2}, {baz=>2} ] }, 'defaults set with validate_if containing an array of multiple values');


$v = {
    'group no_extra_fields' => 1,
    foo => {
        max_values => 3,
        type => 'uint',
    },
};

$form = {foo => [3]};
$e = validate($form, $v);
ok(! $e, "Verify no_extra_fields works on non-hash data inside an array") or note explain $e;
