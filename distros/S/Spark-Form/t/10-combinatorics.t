#!perl -T

use Spark::Form;
use Test::More tests => 4;
use lib 't/lib';

use Spark::Form::Field;
use SparkX::Form::Field::Validator::Regex;
use SparkX::Form::Field::Validator::MinLength;
use SparkX::Form::Field::Validator::MaxLength;
use SparkX::Form::Field::Validator::Confirm;

my $f = Spark::Form->new();

my $test = Spark::Form::Field->new(
    form => $f,
    name => 'test'
);

SparkX::Form::Field::Validator::Regex->meta->apply($test);
SparkX::Form::Field::Validator::MinLength->meta->apply($test);
SparkX::Form::Field::Validator::MaxLength->meta->apply($test);
SparkX::Form::Field::Validator::Confirm->meta->apply($test);
$test->regex(qr/^[A-Z]+[0-9]$/);
$test->min_length(6);
$test->max_length(6);
$test->confirm('test');

$f->add($test);
$f->data({test => ''});
$f->validate;
is(scalar $f->errors,2,"Two errors, unset");
$f->data({test => 'ABCDE'});
$f->validate;
is(scalar $f->errors,2,"Two errors");
$f->data({test => 'ABCDEFG'});
$f->validate;
is(scalar $f->errors,2,"Two errors,");
$f->data({test => 'ABCDE1'});
$f->validate;
is(scalar $f->errors,0,"No errors");
