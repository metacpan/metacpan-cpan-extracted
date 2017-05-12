package Templates::FilterProc;
use Su::Template;

my $model = {};

sub map_filter {

  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my @results = @_;

  for (@results) {
    s/key/modified_key/g;
  }

  return @results;
} ## end sub map_filter

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
