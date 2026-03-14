# maintained manually, based on output from EU:D
package OpenGL::Install::Files;
use strict;
use warnings;
require OpenGL::Config;

our $CORE = undef;
foreach (@INC) {
  if ( -f $_ . "/OpenGL/Install/Files.pm") {
    $CORE = $_ . "/OpenGL/Install/";
    last;
  }
}

our $self = {
  deps => [],
  inc => $OpenGL::Config->{INC},
  libs => $OpenGL::Config->{LIBS},
  typemaps => [$CORE."typemap"],
};

our @deps = @{ $self->{deps} };
our @typemaps = @{ $self->{typemaps} };
our $libs = $self->{libs};
our $inc = $self->{inc};

sub deps { @{ $self->{deps} }; }

sub Inline {
  my ($class, $lang) = @_;
  +{ map { (uc($_) => $self->{$_}) } qw(inc libs typemaps) };
}

1;
