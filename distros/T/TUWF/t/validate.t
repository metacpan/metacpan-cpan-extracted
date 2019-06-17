#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Storable 'dclone';
use Test::More;

eval { require boolean; }; # Optional test, a blessed 'boolean' reference overloads some contexts, we should be able to handle that.

BEGIN { use_ok 'TUWF::Validate', qw/compile validate/ };


my %validations = (
  hex => { regex => qr/^[0-9a-f]*$/i },
  prefix => sub { my $p = shift; { func => sub { $_[0] =~ /^$p/ } } },
  bool => { required => 0, default => 0, func => sub { $_[0] = $_[0]?1:0; 1 } },
  collapsews => { rmwhitespace => 0, func => sub { $_[0] =~ s/\s+/ /g; 1 } },
  revnum => { type => 'array', sort => sub { $_[1] <=> $_[0] } },
  uniquelength => { type => 'array', values => { type => 'array' }, unique => sub { scalar @{$_[0]} } },
  person => {
    type => 'hash',
    unknown => 'accept',
    keys => {
      name => {},
      age => { required => 0 }
    }
  },
);


sub t {
  my($schema, $input, $output, $error) = @_;
  my $line = (caller)[2];

  my $schema_copy = dclone([$schema])->[0];
  my $input_copy = dclone([$input])->[0];

  my $res = validate \%validations, $schema, $input;
  #diag explain $res if $line == 82;
  is !!$res, !$error, "boolean context $line";
  is_deeply $schema, $schema_copy, "schema modification $line";
  is_deeply $input,  $input_copy,  "input modification $line";
  is_deeply $res->unsafe_data(), $output, "unsafe_data $line";
  is_deeply $res->data(), $output, "data ok $line" if !$error;
  ok !eval { $res->data; 1}, "data err $line" if $error;
  is_deeply $res->err(), $error, "err $line";

  my $res_b = compile(\%validations, $schema)->validate($input);
  is_deeply $schema, $schema_copy, "compile+validate schema modification $line";
  is_deeply $input,  $input_copy,  "compile+validate input modification $line";
  is_deeply $res_b->unsafe_data(), $output, "compile+validate unsafe_data $line";
  is_deeply $res_b->err(), $error, "compile+validate err $line";
}


# required / default
t {}, 0, 0, undef;
t {}, '', '', { validation => 'required' };
t {}, undef, undef, { validation => 'required' };
t { required => 0 }, undef, undef, undef;
t { required => 0 }, '', '', undef;
t { required => 0, default => '' }, undef, '', undef;

# rmwhitespace
t {}, " Va\rl id \n ", 'Val id', undef;
t { rmwhitespace => 0 }, " Va\rl id \n ", " Va\rl id \n ", undef;
t {}, '  ', '', { validation => 'required' };
t { rmwhitespace => 0 }, '  ', '  ', undef;

# arrays
t {}, [], [], { validation => 'type', expected => 'scalar', got => 'array' };
t { type => 'array' }, 1, 1, { validation => 'type', expected => 'array', got => 'scalar' };
t { type => 'array' }, [], [], undef;
t { type => 'array' }, [undef,1,2,{}], [undef,1,2,{}], undef;
t { type => 'array', scalar => 1 }, 1, [1], undef;
t { type => 'array', values => {} }, [undef], [undef], { validation => 'values', errors => [{ index => 0, validation => 'required' }] };
t { type => 'array', values => {} }, [' a '], ['a'], undef;
t { type => 'array', sort => 'str' }, [qw/20 100 3/], [qw/100 20 3/], undef;
t { type => 'array', sort => 'num' }, [qw/20 100 3/], [qw/3 20 100/], undef;
t { revnum => 1 },                    [qw/20 100 3/], [qw/100 20 3/], undef;
t { type => 'array', sort => 'num', unique => 1 }, [qw/3 2 1/], [qw/1 2 3/], undef;
t { type => 'array', sort => 'num', unique => 1 }, [qw/3 2 3/], [qw/2 3 3/], { validation => 'unique', index_a => 1, value_a => 3, index_b => 2, value_b => 3 };
t { type => 'array', unique => 1 }, [qw/3 1 2/], [qw/3 1 2/], undef;
t { type => 'array', unique => 1 }, [qw/3 1 3/], [qw/3 1 3/], { validation => 'unique', index_a => 0, value_a => 3, index_b => 2, value_b => 3, key => 3 };
t { uniquelength => 1 }, [[],[1],[1,2]], [[],[1],[1,2]], undef;
t { uniquelength => 1 }, [[],[1],[2]], [[],[1],[2]], { validation => 'unique', index_a => 1, value_a => [1], index_b => 2, value_b => [2], key => 1 };

# hashes
t { type => 'hash' }, [], [], { validation => 'type', expected => 'hash', got => 'array' };
t { type => 'hash' }, 'a', 'a', { validation => 'type', expected => 'hash', got => 'scalar' };
t { type => 'hash' }, {a=>[],b=>undef,c=>{}}, {}, undef;
t { type => 'hash', keys => { a=>{} } }, {}, {a=>undef}, { validation => 'keys', errors => [{ key => 'a', validation => 'required' }] }; # XXX: the key doesn't necessarily have to be created
t { type => 'hash', keys => { a=>{required=>0} } }, {}, {}, undef;
t { type => 'hash', keys => { a=>{required=>0,default=>undef} } }, {}, {a=>undef}, undef;
t { type => 'hash', keys => { a=>{} } }, {a=>' a '}, {a=>'a'}, undef; # Test against in-place modification
t { type => 'hash', keys => { a=>{} }, unknown => 'remove' }, { a=>1,b=>1 }, { a=>1 }, undef;
t { type => 'hash', keys => { a=>{} }, unknown => 'reject' }, { a=>1,b=>1 }, { a=>1,b=>1 }, { validation => 'unknown', keys => ['b'], expected => ['a'] };
t { type => 'hash', keys => { a=>{} }, unknown => 'accept' }, { a=>1,b=>1 }, { a=>1,b=>1 }, undef;

# default validations
t { minlength => 3 }, 'ab', 'ab', { validation => 'minlength', expected => 3, got => 2 };
t { minlength => 3 }, 'abc', 'abc', undef;
t { maxlength => 3 }, 'abcd', 'abcd', { validation => 'maxlength', expected => 3, got => 4 };
t { maxlength => 3 }, 'abc', 'abc', undef;
t { minlength => 3, maxlength => 3 }, 'abc', 'abc', undef;
t { length => 3 }, 'ab',   'ab',   { validation => 'length', expected => 3, got => 2 };
t { length => 3 }, 'abcd', 'abcd', { validation => 'length', expected => 3, got => 4 };
t { length => 3 }, 'abc',  'abc',  undef;
t { length => [1,3] }, 'abc',  'abc', undef;
t { length => [1,3] }, 'abcd', 'abcd', { validation => 'length', expected => [1,3], got => 4 };;
t { type => 'array', length => 0 }, [], [], undef;
t { type => 'array', length => 1 }, [1,2], [1,2], { validation => 'length', expected => 1, got => 2 };
t { type => 'hash', length => 0 }, {}, {}, undef;
t { type => 'hash', length => 1, unknown => 'accept' }, {qw/1 a 2 b/}, {qw/1 a 2 b/}, { validation => 'length', expected => 1, got => 2 };
t { type => 'hash', length => 1, keys => {a => {required=>0}, b => {required=>0}} }, {a=>1}, {a=>1}, undef;
t { regex => '^a' }, 'abc', 'abc', undef;  # XXX: Can't use qr// here because t() does dclone(). The 'hex' test covers that case anyway.
t { regex => '^a' }, 'cba', 'cba', { validation => 'regex', regex => '^a', got => 'cba' };
t { enum => [1,2] }, 1, 1, undef;
t { enum => [1,2] }, 2, 2, undef;
t { enum => [1,2] }, 3, 3, { validation => 'enum', expected => [1,2], got => 3 };
t { enum => 1 }, 1, 1, undef;
t { enum => 1 }, 2, 2, { validation => 'enum', expected => [1], got => 2 };
t { enum => {a=>1,b=>2} }, 'a', 'a', undef;
t { enum => {a=>1,b=>2} }, 'c', 'c', { validation => 'enum', expected => ['a','b'], got => 'c' };
t { anybool => 1 }, 1, 1, undef;
t { anybool => 1 }, undef, 0, undef;
t { anybool => 1 }, '', 0, undef;
t { anybool => 1 }, {}, 1, undef;
t { anybool => 1 }, [], 1, undef;
t { anybool => 1 }, bless({}, 'test'), 1, undef;
t { jsonbool => 1 }, 1, 1, { validation => 'jsonbool' };
t { jsonbool => 1 }, \1, \1, { validation => 'jsonbool' };
my($true, $false) = (1,0);
t { jsonbool => 1 }, bless(\$true, 'boolean'), bless(\$true, 'boolean'), undef;
t { jsonbool => 1 }, bless(\$false, 'boolean'), bless(\$false, 'boolean'), undef;
t { jsonbool => 1 }, bless(\$true, 'test'), bless(\$true, 'test'), { validation => 'jsonbool' };
t { ascii => 1 }, 'ab c', 'ab c', undef;
t { ascii => 1 }, "a\nb", "a\nb", { validation => 'ascii', got => "a\nb" };

# custom validations
t { hex => 1 }, 'DeadBeef', 'DeadBeef', undef;
t { hex => 1 }, 'x', 'x', { validation => 'hex', error => { validation => 'regex', regex => '(?^i:^[0-9a-f]*$)', got => 'x' } };
t { prefix => 'a' }, 'abc', 'abc', undef;
t { prefix => 'a' }, 'cba', 'cba', { validation => 'prefix', error => { validation => 'func', result => '' } };
t { bool => 1 }, 'abc', 1, undef;
t { bool => 1 }, undef, 0, undef;
t { bool => 1 }, '', 0, undef;
t { bool => 1, required => 1 }, undef, undef, { validation => 'required' };
t { bool => 1, required => 1 }, 0, 0, undef;
t { collapsews => 1, required => 0 }, " \t\n ", ' ', undef;
t { collapsews => 1 }, '   x  ', ' x ', undef;
t { collapsews => 1, rmwhitespace => 1 }, '   x  ', 'x', undef;
t { person => 1 }, 1, 1, { validation => 'type', expected => 'hash', got => 'scalar' };
t { person => 1 }, {}, { name => undef }, { validation => 'person', error => { validation => 'keys', errors => [{ key => 'name', validation => 'required' }] } };
t { person => 1 }, {name => 'x'}, { name => 'x' }, undef;
t { person => 1, keys => {age => { required => 1 }} }, {name => 'x'}, { name => 'x', age => undef }, { validation => 'keys', errors => [{ key => 'age', validation => 'required' }] };
t { person => 1, keys => {extra => {}} }, {name => 'x', extra => 1}, { name => 'x', extra => 1 }, undef;
t { person => 1, keys => {extra => {}} }, {name => 'x', extra => ''}, { name => 'x', extra => '' }, { validation => 'keys', errors => [{ key => 'extra', validation => 'required' }] };
t { person => 1 }, {name => 'x', extra => 1}, {name => 'x', extra => 1}, undef;
t { person => 1, unknown => 'remove' }, {name => 'x', extra => 1}, {name => 'x'}, undef;

# numbers
sub nerr { +{ validation => 'num', got => $_[0] } }
t { num => 1 }, 0, 0, undef;
t { num => 1 }, '-', '-', nerr '-';
t { num => 1 }, '00', '00', nerr '00';
t { num => 1 }, '1', '1', undef;
t { num => 1 }, '1.1.', '1.1.', nerr '1.1.';
t { num => 1 }, '1.-1', '1.-1', nerr '1.-1';
t { num => 1 }, '.1', '.1', nerr '.1';
t { num => 1 }, '0.1e5', '0.1e5', undef;
t { num => 1 }, '0.1e+5', '0.1e+5', undef;
t { num => 1 }, '0.1e5.1', '0.1e5.1', nerr '0.1e5.1';
t { int => 1 }, 0, 0, undef;
t { int => 1 }, -123, -123, undef;
t { int => 1 }, -123.1, -123.1, { validation => 'int', got => -123.1 };
t { uint => 1 }, 0, 0, undef;
t { uint => 1 }, 123, 123, undef;
t { uint => 1 }, -123, -123, { validation => 'uint', got => -123 };
t { min => 1 }, 1, 1, undef;
t { min => 1 }, 0.9, 0.9, { validation => 'min', expected => 1, got => 0.9 };
t { min => 1 }, 'a', 'a', { validation => 'min', error => nerr 'a' };
t { max => 1 }, 1, 1, undef;
t { max => 1 }, 1.1, 1.1, { validation => 'max', expected => 1, got => 1.1 };
t { max => 1 }, 'a', 'a', { validation => 'max', error => nerr 'a' };
t { range => [1,2] }, 1, 1, undef;
t { range => [1,2] }, 2, 2, undef;
t { range => [1,2] }, 0.9, 0.9, { validation => 'range', error => { validation => 'min', expected => 1, got => 0.9 } };
t { range => [1,2] }, 2.1, 2.1, { validation => 'range', error => { validation => 'max', expected => 2, got => 2.1 } };
t { range => [1,2] }, 'a', 'a', { validation => 'range', error => { validation => 'max', error => nerr 'a' } }; # XXX: Error validation type depends on evaluation order

# email template
t { email => 1 }, $_->[1], $_->[1], $_->[0] ? undef : { validation => 'email', got => $_->[1] } for (
  [ 0, 'abc.com' ],
  [ 0, 'abc@localhost' ],
  [ 0, 'abc@10.0.0.' ],
  [ 0, 'abc@256.0.0.1' ],
  [ 0, '<whoami>@blicky.net' ],
  [ 0, 'a @a.com' ],
  [ 0, 'a"@a.com' ],
  [ 0, 'a@[:]' ],
  [ 1, 'a@a.com' ],
  [ 1, 'a@a.com.' ],
  [ 1, 'a@127.0.0.1' ],
  [ 1, 'a@[::1]' ],
  [ 1, 'é@yörhel.nl' ],
  [ 1, 'a+_0-c@yorhel.nl' ],
  [ 1, 'é@x-y_z.example' ],
  [ 1, 'abc@x-y_z.example' ],
);
my $long = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx@xxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxx';
t { email => 1 }, $long, $long, { validation => 'email', error => { validation => 'maxlength', got => 255, expected => 254 } };

# weburl template
t { weburl => 1 }, $_->[1], $_->[1], $_->[0] ? undef : { validation => 'weburl', got => $_->[1] } for (
  [ 0, 'http' ],
  [ 0, 'http://' ],
  [ 0, 'http:///' ],
  [ 0, 'http://x/' ],
  [ 0, 'http://x/' ],
  [ 0, 'http://256.0.0.1/' ],
  [ 0, 'http://blicky.net:050/' ],
  [ 0, 'ftp//blicky.net/' ],
  [ 1, 'http://blicky.net/' ],
  [ 1, 'http://blicky.net:50/' ],
  [ 1, 'https://blicky.net/' ],
  [ 1, 'https://[::1]:80/' ],
  [ 1, 'https://l-n.x_.example.com/' ],
  [ 1, 'https://blicky.net/?#Who\'d%20ever%22makeaurl_like-this/!idont.know' ],
);


# Things that should fail
ok !eval { compile { recursive => { recursive => 1 } }, { recursive => 1 }; 1 }, 'recursive';
ok !eval { compile { a => { b => 1 }, b => { a => 1 } }, { a => 1 }; 1 }, 'mutually recursive';
ok !eval { compile {}, { wtfisthis => 1 }; 1 }, 'unknown validation';
ok !eval { compile { a => { type => 'array' } }, { type => 'scalar', a => 1 }; 1 }, 'incompatible types';
ok !eval { validate {}, { type => 'x' }, 1; 1 }, 'unknown type';
ok !eval { compile {}, { type => 'array', regex => qr// }; 1 }, 'incompatible type for regex';
ok !eval { compile {}, { type => 'hash', keys => {a => {wtfisthis => 1}} }; 1 }, 'unknown type in hash key';

done_testing;
