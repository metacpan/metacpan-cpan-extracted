#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Hidden;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Hidden->new(name => 'test', value => 'test', form => $form);

is($b->to_xhtml,'<input name="test" type="hidden" value="test" />','Test xhtml representation');
