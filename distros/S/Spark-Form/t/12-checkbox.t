#!perl -T

use Test::More tests => 2;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Checkbox;

my $form = Spark::Form->new;
my $c = SparkX::Form::Field::Checkbox->new(name => 'test', form => $form);
my $c2 = SparkX::Form::Field::Checkbox->new(name => 'test', form => $form, value => 1);
is($c->to_xhtml,'<input name="test" type="checkbox" value="1" />','Test xhtml representation');
is($c2->to_xhtml,'<input checked="checked" name="test" type="checkbox" value="1" />','Test xhtml representation');
