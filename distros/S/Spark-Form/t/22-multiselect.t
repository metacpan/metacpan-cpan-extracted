#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::MultiSelect;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::MultiSelect->new(
    name => 'test', form => $form,
    value => ['1','3'],
    options => ['1','2','3','4'],
);

is($b->to_xhtml,'<select multiple="multiple" name="test"><option selected="selected" value="1"></option> <option value="2"></option> <option selected="selected" value="3"></option> <option value="4"></option></select>','Test xhtml representation');
