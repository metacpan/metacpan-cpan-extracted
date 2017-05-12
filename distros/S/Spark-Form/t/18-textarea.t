#!perl -T

use Test::More tests => 1;
use lib 't/lib';
use Spark::Form;
use SparkX::Form::Field::Textarea;

my $form = Spark::Form->new;
my $b = SparkX::Form::Field::Textarea->new(name => 'test', form => $form, value=>'test');

is($b->to_xhtml,'<textarea name="test">test</textarea>','Test xhtml representation');
