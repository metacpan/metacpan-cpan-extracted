#!perl -T

use Spark::Form;
use Test::More tests => 3;
use lib 't/lib';

use Spark::Form::Field;
use SparkX::Form::Field::Validator::MinLength;

my $f = Spark::Form->new();

my $test = Spark::Form::Field->new(form => $f, name => 'test');
SparkX::Form::Field::Validator::MinLength->meta->apply($test);
$test->min_length(3);

$f->add($test);
$f->data({test => 'qu'});
$f->validate;
is(scalar $f->errors,1,"One error, borderline");
$f->data({test => 'quu'});
$f->validate;
is(scalar $f->errors,0,"No errors, borderline");
$f->data({test => 'quux'});
$f->validate;
is(scalar $f->errors,0,"One error");
