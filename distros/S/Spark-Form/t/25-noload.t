use Test::More tests => 1;
use Spark::Form;

#Local lib
use lib 't/lib';

#Create a form, mixing in the printer. This ensures it correctly loads the module.
eval {
    my $form = Spark::Form->new( printer => 'SparkX::Form::Printer::List' );
};
is($@,'',"$@ is empty");