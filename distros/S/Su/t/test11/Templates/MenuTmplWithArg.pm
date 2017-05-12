package Templates::MenuTmplWithArg;
use Su::Template;

my $model;

sub process {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my $arg = shift;
  return "Test11 " . $arg;

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
