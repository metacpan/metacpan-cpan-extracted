#!/usr/bin/perl -w
use strict;

use Test::More  tests => 167;
use Test::CPAN::Meta::JSON::Version;

my $spec = Test::CPAN::Meta::JSON::Version->new(spec => '2');

is($spec->url('url','http://search.cpan.org/dist/CPAN-Meta/lib/CPAN/Meta/Spec.pm'),1,'valid URL');
is($spec->url('url','http://'),0);
is($spec->url('url','://search.cpan.org/dist/CPAN-Meta/lib/CPAN/Meta/Spec.pm'),0);
is($spec->url('url','test://'),0);
is($spec->url('url','test^example^com'),0);
is($spec->url('url',''),0);
is($spec->url('url'),0);

is($spec->url('url','http://www.gnu.org/licenses/#GPL'),1,'valid URL: http://www.gnu.org/licenses/#GPL');

is($spec->string('string','string'),1,'valid string');
is($spec->string('string','0'),1);
is($spec->string('string',''),0);
is($spec->string('string',undef),0);

is($spec->string_or_undef('string_or_undef','string'),1,'valid string or undef');
is($spec->string_or_undef('string_or_undef','0'),1);
is($spec->string_or_undef('string_or_undef',''),0);
is($spec->string_or_undef('string_or_undef',undef),1);

is($spec->file('file','file'),1,'valid file');
is($spec->file('file',''),1);
is($spec->file('file',undef),0);

is($spec->exversion('exversion','0'),1,'valid extended version');
is($spec->exversion('exversion','<= 5, >=2, ==3, !=4, >1, <6'),1);
is($spec->exversion('exversion','='),0);
is($spec->exversion('exversion',''),0);
is($spec->exversion('exversion',undef),0);
is($spec->exversion('exversion'),0);

is($spec->version('version','0'),1,'valid basic version');
is($spec->version('version','0.00'),1);
is($spec->version('version','0.00_00'),1);
is($spec->version('version','0.0.0'),1);
is($spec->version('version','v0.0.0'),1);
is($spec->version('version','<6'),1);
is($spec->version('version','!4'),0);
is($spec->version('version',''),0);
is($spec->version('version',undef),0);
is($spec->version('version'),0);

is($spec->boolean('boolean','0'),1,     'boolean = 0');
is($spec->boolean('boolean','1'),1,     'boolean = 1');
is($spec->boolean('boolean','true'),1,  'boolean = true');
is($spec->boolean('boolean','false'),1, 'boolean = false');
is($spec->boolean('boolean','blah'),0,  'boolean = blah');
is($spec->boolean('boolean',''),0,      'boolean = (blank)');
is($spec->boolean('boolean',undef),0,   'boolean = (undef value)');
is($spec->boolean('boolean'),0,         'boolean = (undef)');

for my $value (qw( 
          agpl_3
          apache_1_1
          apache_2_0
          artistic_1
          artistic_2
          bsd
          freebsd
          gfdl_1_2
          gfdl_1_3
          gpl_1
          gpl_2
          gpl_3
          lgpl_2_1
          lgpl_3_0
          mit
          mozilla_1_0
          mozilla_1_1
          openssl
          perl_5
          qpl_1_0
          ssleay
          sun
          zlib
          open_source
          restricted
          unrestricted
          unknown
        )) {
    is($spec->license('license',$value),1,'license test = ' . $value);
}
is($spec->license('license','perl'),0); # no longer valid
is($spec->license('license','blah'),0);
is($spec->license('license',''),0);
is($spec->license('license',undef),0);

is($spec->resource('MailListing'),1,'valid resource - CamelCase');
is($spec->resource('MAILListing'),1,'valid resource - Caps start');
is($spec->resource('mailLISTing'),1,'valid resource - Caps middle');
is($spec->resource('mailListing'),1,'valid resource - 1 cap middle');
is($spec->resource('maillisting'),0);
is($spec->resource('1234567890'),0);
is($spec->resource(''),0);
is($spec->resource(undef),0);

is($spec->keyword($_),1,"valid keyword $_")     for(qw(test X_TEST x_test test-test test_test));
is($spec->keyword($_),0,"invalid keyword $_")   for(qw(X-TEST Test TEST test:));
is($spec->keyword(''),0,'invalid keyword <empty string>');
is($spec->keyword(undef),0,'invalid keyword <undef>');

is($spec->identifier($_),1,"valid identifier $_")   for(qw(test Test TEST X_TEST x_test test_test));
is($spec->identifier($_),0,"invalid identifier $_") for(qw(X-TEST test-test test:));
is($spec->identifier(''),0,'invalid identifier <empty string>');
is($spec->identifier(undef),0,'invalid identifier <undef>');

is($spec->module('Test'),1,'valid module name');
is($spec->module('Test::CPAN::Meta::JSON'),1);
is($spec->module('Test-JSON-Meta'),0);
is($spec->module(''),0);
is($spec->module(undef),0);

$spec->{data}{version} = undef;
is($spec->release_status('release_status',$_),1,"valid release_status $_")   for(qw(stable testing unstable));

$spec->{data}{version} = '0.01';
is($spec->release_status('release_status',$_),1,"valid release_status $_")   for(qw(stable testing unstable));
is($spec->release_status('release_status',$_),0,"invalid release_status $_") for(qw(X-TEST test-test test:));
is($spec->release_status('release_status',''),0,'invalid release_status <empty string>');
is($spec->release_status('release_status',undef),0,'invalid irelease_statusdentifier <undef>');
$spec->{data}{version} = '0.01_01';
is($spec->release_status('release_status',$_),1,"valid development release_status $_")   for(qw(testing unstable));
is($spec->release_status('release_status',$_),0,"invalid development release_status $_")   for(qw(stable));

is($spec->custom_1($_),1,"valid custom_1 $_")   for(qw(Test TEST));
is($spec->custom_1($_),0,"invalid custom_1 $_") for(qw(test X_TEST x_test test_test X-TEST test-test test:));
is($spec->custom_1(''),0,'invalid custom_1 <empty string>');
is($spec->custom_1(undef),0,'invalid custom_1 <undef>');

is($spec->custom_2($_),1,"valid custom_2 $_")   for(qw(X_TEST x_test));
is($spec->custom_2($_),0,"invalid custom_2 $_") for(qw(Test TEST X-TEST test_test test-test test:));
is($spec->custom_2(''),0,'invalid custom_2 <empty string>');
is($spec->custom_2(undef),0,'invalid custom_2 <undef>');

is($spec->phase($_),1,"valid phase $_")   for(qw(configure build test runtime develop));
is($spec->phase($_),0,"invalid phase $_") for(qw(X-TEST test-test test:));
is($spec->phase(''),0,'invalid phase <empty string>');
is($spec->phase(undef),0,'invalid phase <undef>');

is($spec->relation($_),1,"valid relation $_")   for(qw(requires recommends suggests conflicts));
is($spec->relation($_),0,"invalid relation $_") for(qw(X-TEST test-test test:));
is($spec->relation(''),0,'invalid relation <empty string>');
is($spec->relation(undef),0,'invalid relation <undef>');


my $hash_spec = { file       => { list => { value => 'string' } },
                  directory  => { list => { value => 'string' } },
                  'package'  => { list => { value => 'string' } },
                  namespace  => { list => { value => 'string' } },
};

my $list_spec = { value => 'string' };

my $hash_test = { 'directory' => [ 't', 'examples' ] };
my $list_test = [ 't', 'examples' ];

my $this = scalar($spec->errors);
eval { $spec->check_map($hash_spec,$hash_test); };
my $that = scalar($spec->errors);
is($that-$this,0, 'valid map check - hash vs hash');

$this = $that;
eval { $spec->check_list($list_spec,$list_test); };
$that = scalar($spec->errors);
is($that-$this,0, 'valid list check - array vs array');

$this = $that;
eval { $spec->check_map($hash_spec,$list_test); };
$that = scalar($spec->errors);
is($that-$this,1, 'invalid map check - hash vs array');

$this = $that;
eval { $spec->check_list($list_spec,$hash_test); };
$that = scalar($spec->errors);
is($that-$this,1, 'invalid list check - array vs hash');
