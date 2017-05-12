#line 1
use strict;
use warnings;
package Test::Fatal;
BEGIN {
  $Test::Fatal::VERSION = '0.003';
}
# ABSTRACT: incredibly simple helpers for testing code with exceptions


use Carp ();
use Try::Tiny 0.07;

use Exporter 5.59 'import';

our @EXPORT    = qw(exception);
our @EXPORT_OK = qw(exception success);


sub exception (&) {
  my ($code) = @_;

  return try {
    $code->();
    return undef;
  } catch {
    return $_ if $_;

    my $problem = defined $_ ? 'false' : 'undef';
    Carp::confess("$problem exception caught by Test::Fatal::exception");
  };
}


sub success (&) {
  my ($code) = @_;
  return finally {
    return if @_; # <-- only run on success
    $code->();
  }
}

1;

__END__
#line 142

