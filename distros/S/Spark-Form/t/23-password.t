#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Password;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Password->new(name => 'test', form => $form);

is($b->to_xhtml,'<input name="test" type="password" />','Test xhtml representation');
