use strict;
use warnings;

package Test::Fatal::Assert;
use Test::More;
use Test::Fatal qw( exception );
use Sub::Exporter::Progressive -setup => {
  exports => [qw( nofatals fatals and_fatal_is )],
  groups  => {
    default => [qw( nofatals fatals )],
  },
};

our $REPORT_PASS;

sub nofatals($$;@) {
  my ( $reason, $code, %extra ) = @_;
  my $result = exception { $code->() };
  my $callback = $extra{and_fatal_is};
  if ($result) {
    fail("$reason raised no exception");
    diag($result);
    if ($callback) {
      local $_ = $result;
      $callback->($result);
    }
  }
  else {
    $REPORT_PASS and pass("$reason raised no exception");
  }
}

sub fatals($$;@) {
  my ( $reason, $code, %extra ) = @_;
  my $result = exception { $code->() };
  my $callback = $extra{and_fatal_is};
  if ( not $result ) {
    fail("$reason should raise exception");
  }
  else {
    pass("$reason should raise exception");
    if ( defined $callback ) {
      local $_ = $result;
      $callback->($result);
    }
  }
}

sub and_fatal_is(&) {
  my ($code) = @_;
  return ( and_fatal_is => $code );
}
1;
