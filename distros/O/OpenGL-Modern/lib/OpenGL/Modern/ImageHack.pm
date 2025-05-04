package    # hide from cpan
  OpenGL;
use strict;
use warnings;

BEGIN {    # prevent the real one from being loaded
    die "OpenGL already loaded" if $INC{"OpenGL.pm"};
    $INC{"OpenGL.pm"} = "Loaded from OpenGL::Modern";
}

sub import {
  my ( undef, @args ) = @_;
  $args[0] = ':all' if $args[0] eq ':constants';    # O::M doesn't have :constants yet
  require OpenGL::Modern;
  my ($target, $file, $line) = caller(1);
  my $sub = eval qq{
package $target;
#line $line "$file"
sub { shift->import(\@_) }
};
  OpenGL::Modern->$sub(@args);
}
