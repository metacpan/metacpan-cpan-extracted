#!perl -T

use Spark::Form;
use Test::More tests => 2;
use lib 't/lib';

use Spark::Form::Field;
use SparkX::Form::Field::Validator::Confirm;

my $f = Spark::Form->new();

my $t1 = Spark::Form::Field->new(form => $f, name => 't1');
my $t2 = Spark::Form::Field->new(form => $f, name => 't2');
SparkX::Form::Field::Validator::Confirm->meta->apply($t1);
$t1->confirm('t2');

$f->add($t1)->add($t2);
$f->data({t1 => 'foo', t2 => 'bar'});
$f->validate;
is(scalar $f->errors,1,"One error");
$f->data({t1 => 'foo', t2 => 'foo'});
$f->validate;
is(scalar @{$f->errors},0,"No errors");
