#!perl -T

use Test::More tests => 2;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Button;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Button->new(name => 'test', form => $form);
my $b2 = SparkX::Form::Field::Button->new(
    name => 'test', form => $form,
    content=>'<img src="foo" />'
);
is($b->to_xhtml,'<button name="test"></button>','Test xhtml representation');
is($b2->to_xhtml,'<button name="test"><img src="foo" /></button>','Test xhtml representation');
