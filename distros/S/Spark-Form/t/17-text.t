#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Text;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Text->new(name => 'test', value => 'test', form => $form);

is($b->to_xhtml,'<input name="test" type="text" value="test" />','Test xhtml representation');
