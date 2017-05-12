#!perl -T

use Spark::Form;
use Test::More tests => 3;
use lib 't/lib';

use Spark::Form::Field;
use SparkX::Form::Field::Validator::NotEmpty;

my $f = Spark::Form->new();

my $test = Spark::Form::Field->new(form => $f, name => 'test');
SparkX::Form::Field::Validator::NotEmpty->meta->apply($test);

$f->add($test);
$f->data({});
$f->validate;
is(scalar $f->errors,1,"One error, unset");
$f->data({test => ''});
$f->validate;
is(scalar $f->errors,1,"One error, empty");
$f->data({test => 'foo'});
$f->validate;
is(scalar $f->errors,0,"No error");
