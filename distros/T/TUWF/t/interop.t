#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More;
use Storable 'dclone';

BEGIN { use_ok 'TUWF::Validate', qw/compile/ };
use_ok 'TUWF::Validate::Interop';



sub h {
   my($schema, @html5) = @_;
   #use Data::Dumper 'Dumper'; diag Dumper compile({}, $schema)->analyze;
   is_deeply { compile({}, $schema)->analyze->html5_validation }, { @html5 };
}

h {}, required => 'required';
h { required => 0 };
h { minlength => 1 },     required => 'required', minlength => 1;
h { maxlength => 1 },     required => 'required', maxlength => 1;
h { length    => 1 },     required => 'required', minlength => 1, maxlength => 1;
h { length    => [1,2] }, required => 'required', minlength => 1, maxlength => 2;

h { uint      => 1 },     required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_uint);
h { email     => 1 },     required => 'required', maxlength => 254, pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_email);
h { uint => 1, regex => qr/^.{3}$/ }, required => 'required', pattern => '(?=(?:^(?:0|[1-9]\d*)$))(?:^.{3}$)';

h { min => 1 },        required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_num), min => 1;
h { max => 1 },        required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_num), max => 1;
h { range => [1,2] },  required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_num), min => 1, max => 2;
h { range => [1,2], min =>-1 }, required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_num), min => 1, max => 2;
h { range => [1,2], min => 2 }, required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_num), min => 2, max => 2;
h { range => [1,2], max => 3 }, required => 'required', pattern => TUWF::Validate::Interop::_re_compat($TUWF::Validate::re_num), min => 1, max => 2;




my @serialized = (
  [ {}, 1, '"1"' ],
  [ { anybool => 1 }, 'a', 'true' ],
  [ { jsonbool => 1 }, 'a', 'true' ],
  [ { num => 1 }, '20.1', '20.1' ],
  [ { uint => 1 }, '20.1', '20' ],
  [ { int => 1 }, '-20.1', '-20' ],
  [ { type => 'any' }, '20', '"20"' ],
  [ { type => 'any' }, [], '[]' ],
  [ { type => 'array' }, [], '[]' ],
  [ { type => 'array' }, [1,2,'3'], '[1,2,"3"]' ],
  [ { type => 'array', values => {anybool=>1} }, ['a',1,0], '[true,true,false]' ],
  [ { type => 'hash' }, {}, '{}' ],
  [ { type => 'hash' }, {a=>1,b=>'2'}, '{"a":1,"b":"2"}' ],
  [ { type => 'hash', keys => {b=>{}} }, {}, '{}' ],
  [ { type => 'hash', keys => {a=>{anybool=>1},b=>{int=>1}} }, {a=>1,b=>'10'}, '{"a":true,"b":10}' ],
  [ { required => 0 }, undef, 'null' ],
  [ { required => 0, jsonbool => 1 }, undef, 'null' ],
  [ { required => 0, num => 1 }, undef, 'null' ],
  [ { required => 0, int => 1 }, undef, 'null' ],
  [ { required => 0, type => 'hash' }, undef, 'null' ],
  [ { required => 0, type => 'array' }, undef, 'null' ],
);

subtest 'JSON::XS coercion', sub {
  eval { require JSON::XS; 1 } or plan skip_all => 'JSON::XS not installed';
  my @extra = (
    [ { type => 'num' }, '10', '10' ],
    [ { type => 'hash', keys => {a=>{anybool=>1},b=>{int=>1}} }, {a=>1,b=>'10',c=>[]}, '{"a":true,"b":10}' ],
    [ { type => 'hash', unknown => 'pass', keys => {a=>{anybool=>1},b=>{int=>1}} }, {a=>1,b=>'10',c=>[]}, '{"a":true,"b":10,"c":[]}' ],
  );
  my $js = JSON::XS->new->canonical->allow_nonref;
  for (@serialized, @extra) {
    my($schema, $in, $out) = @$_;
    my $inc = dclone([$in])->[0];
    is($js->encode(compile({}, $schema)->analyze->coerce_for_json($in)), $out);
    is_deeply $inc, $in;
  }
  is($js->encode(compile({}, { type => 'hash', keys => {} })->analyze->coerce_for_json({a=>1}, unknown => 'pass')), '{"a":1}');
  ok !eval { $js->encode(compile({}, { type => 'hash', keys => {} })->analyze->coerce_for_json({a=>1}, unknown => 'reject')); 1 };
};

subtest 'Cpanel::JSON::XS coercion', sub {
  eval { require Cpanel::JSON::XS; 1 } or plan skip_all => 'Cpanel::JSON::XS not installed';
  my @extra = (
    [ { type => 'num' }, '10', '10.0' ],
  );
  for (@serialized, @extra) {
    my($schema, $in, $out) = @$_;
    is(Cpanel::JSON::XS->new->canonical->allow_nonref->encode($in, compile({}, $schema)->analyze->json_type), $out);
  }
};


done_testing();
