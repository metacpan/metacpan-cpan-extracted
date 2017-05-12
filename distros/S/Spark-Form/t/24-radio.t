#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Radio;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Radio->new(
    name => 'test', form => $form,
    value => 'test-2', options => ['test-1','test-2','test-3'],
);

is($b->to_xhtml,'<input name="test" type="radio" value="test-1" /> <input checked="checked" name="test" type="radio" value="test-2" /> <input name="test" type="radio" value="test-3" />','Test xhtml representation');
