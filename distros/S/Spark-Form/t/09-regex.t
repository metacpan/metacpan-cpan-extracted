#!perl -T

use Spark::Form;
use Test::More tests => 3;
use lib 't/lib';

use Spark::Form::Field;
use SparkX::Form::Field::Validator::Regex;

my $f = Spark::Form->new();

my $test = Spark::Form::Field->new(name => 'test', form => $f);
SparkX::Form::Field::Validator::Regex->meta->apply($test);
$test->regex(qr/^[A-Z][0-9]$/);

$f->add($test);
$f->data({});
$f->validate;
is(scalar $f->errors,1,"One error, unset");
$f->data({test => 'AB'});
$f->validate;
is(scalar $f->errors,1,"One error, no match");
$f->data({test => 'A1'});
$f->validate;
is(scalar $f->errors,0,"No error, match");
