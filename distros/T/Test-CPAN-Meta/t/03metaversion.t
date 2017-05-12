#!/usr/bin/perl -w
use strict;

use Test::More  tests => 108;
use Test::CPAN::Meta::Version;

my $spec = Test::CPAN::Meta::Version->new(spec => '1.3');

is($spec->header('header','--- #YAML:1.0'),1,'valid YAML header');
is($spec->header('header','--- #YAML:1.1'),0);
is($spec->header('header',''),0);
is($spec->header('header',undef),0);

is($spec->url('url','http://module-build.sourceforge.net/META-spec-v1.3.html'),1,'valid URL');
is($spec->url('url','http://'),0);
is($spec->url('url','://module-build.sourceforge.net/META-spec-v1.3.html'),0);
is($spec->url('url','test://'),0);
is($spec->url('url','test^example^com'),0);
is($spec->url('url',''),0);
is($spec->url('url',undef),0);

is($spec->url('url','http://www.gnu.org/licenses/#GPL'),1,'valid URL: http://www.gnu.org/licenses/#GPL');

is($spec->urlspec('spec','http://module-build.sourceforge.net/META-spec-v1.3.html'),1,'valid specification URL');
is($spec->urlspec('spec','http://module-build.sourceforge.net/META-spec-v1.2.html'),0);
is($spec->urlspec('spec','test.html'),0);
is($spec->urlspec('spec',''),0);
is($spec->urlspec('spec',undef),0);

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

for my $value (qw( perl gpl apache artistic artistic2 artistic-2.0 lgpl bsd gpl mit mozilla open_source unrestricted restrictive unknown )) {
    is($spec->license('license',$value),1,'license test = ' . $value);
}
is($spec->license('license','blah'),2);
is($spec->license('license',''),0);
is($spec->license('license',undef),0);

is($spec->resource('MailListing'),1,'valid resource - CamelCase');
is($spec->resource('MAILListing'),1,'valid resource - Caps start');
is($spec->resource('mailLISTing'),1,'valid resource - Caps middle');
is($spec->resource('mailListing'),1,'valid resource - 1 cap middle');
is($spec->resource('maillisting'),0);
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
is($spec->module('Test::CPAN::Meta'),1);
is($spec->module('Test-YAML-Meta'),0);
is($spec->module(''),0);
is($spec->module(undef),0);



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
