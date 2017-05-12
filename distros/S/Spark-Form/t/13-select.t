#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Select;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Select->new(
    name => 'test', form => $form,
    options => ['test-1','test-2','test-3'],
    value => 'test-2',
);

is($b->to_xhtml,'<select name="test"><option value="test-1">test-1</option> <option selected="selected" value="test-2">test-2</option> <option value="test-3">test-3</option></select>','Test xhtml representation');
