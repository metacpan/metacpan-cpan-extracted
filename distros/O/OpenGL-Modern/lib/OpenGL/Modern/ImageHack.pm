package    # hide from cpan
  OpenGL;
use strict;
use warnings;
use Import::Into;

BEGIN {    # prevent the real one from being loaded
    die "OpenGL already loaded" if $INC{"OpenGL.pm"};
    $INC{"OpenGL.pm"} = "Loaded from OpenGL::Modern";
}

sub import {
    my ( undef, @args ) = @_;
    $args[0] = ':all' if $args[0] eq ':constants';    # O::M doesn't have :constants yet
    my $target = caller;
    OpenGL::Modern->import::into( $target, @args );
}
