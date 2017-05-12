#!perl
#
# This file is part of SDLx-GUI
#
# This software is copyright (c) 2013 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use 5.016;
use warnings;

use Test::More;
use SDLx::App;
use SDLx::GUI;

# main sdl application
my $app = SDLx::App->new(
    title        => 'SDLx::GUI tests',
    width        => 640,
    height       => 480,
    exit_on_quit => 1,
    depth        => 32
);

# create a toplevel
my $top = toplevel( app => $app );
$top->Button( text=>"click" )->pack( side=>'bottom' );
my $i = 0;
foreach my $side ( qw{ left top top right bottom } ) {
    $i++;
    my $size = int(rand()*16) + 16;
    my $lab = $top->Label(text=>"$i $side ($size)", size=>$size);
    $lab->pack( side=>$side );
}
$top->draw;

# run the test
local $SIG{ALRM} = sub {
    pass("made it this far");
    done_testing;
    exit;
};
alarm 2;
$app->run;

