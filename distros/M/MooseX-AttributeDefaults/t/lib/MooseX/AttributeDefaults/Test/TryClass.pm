package MooseX::AttributeDefaults::Test::TryClass;
use Test::More;
use Exporter qw(import);
our @EXPORT = qw(run_tests);

sub run_tests {
  my $class = shift;
  my $obj = eval { $class->new };
  ok($obj, 'created okay');
  ok($obj->can('attr'), 'has accessor');
  is($obj->attr, "default value for attr", 'default value correct');
}

1;
