package Templates::EachFieldTmpl;
use Su::Template;

my $model;

sub process {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  return
      "Test11" . ":"
    . $model->{field1} . ":"
    . $model->{field2} . ":"
    . $model->{field3};
} ## end sub process

sub model {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my $arg = shift;
  if ($arg) {
    $model = $arg;
  } else {
    return $model;
  }
} ## end sub model

1;
