#!perl -T

use Test::More;

my @fields = qw(
  Button Checkbox File Hidden Image
  MultiSelect Password Radio Reset
  Select Submit Text Textarea
);

BEGIN {
    plan tests => (5 + scalar @fields);

    use_ok($_) foreach (qw[
        Spark::Form
        Spark::Form::Field
        ]);
    use_ok("SparkX::Form::Field::$_") foreach @fields;
    use_ok('SparkX::Form::BasicFields');
    use_ok('SparkX::Form::Printer::List');
    use_ok('SparkX::Form::BasicValidators');
}

diag("Testing Spark::Form $Spark::Form::VERSION, Perl $], $^X");
