package SDL::Tutorial::Tetris;

use SDL::Tutorial::Tetris::EventManager;
use SDL::Tutorial::Tetris::View;
use SDL::Tutorial::Tetris::Controller::Keyboard;
use SDL::Tutorial::Tetris::Controller::CPUSpinner;
use SDL::Tutorial::Tetris::Controller::Game;

our $VERSION = 0.04;

sub play {
    my ($class, $EDEBUG, $KEYDEBUG, $GDEBUG, $FPS) = @_;

    my $keybd    = SDL::Tutorial::Tetris::Controller::Keyboard->new();
    my $spinner  = SDL::Tutorial::Tetris::Controller::CPUSpinner->new();
    my $gameView = SDL::Tutorial::Tetris::View::Game->new();

    my $game     = SDL::Tutorial::Tetris::Controller::Game->new(
        EDEBUG      => ${EDEBUG},
        GDEBUG      => ${GDEBUG},
        KEYDEBUG    => ${KEYDEBUG},
        FPS         => $FPS,
    );

    $spinner->run;
}

if (!caller) {
    SDL::Tutorial::Tetris->play(@ARGV);
}

1;
__END__


=head1 NAME

SDL::Tutorial::Tetris - tetris game using SDL(2)

=head1 USAGE

	Tetris.pl

=head1 AUTHOR

    Kartik Thakore
    CPAN ID: KTHAKORE
    kthakore@CPAN.org
    http://yapgh.blogspot.com

=head1 CONTRIBUTORS

    Nelson Ferraz
    CPAN ID: NFERRAZ
    nferraz@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), SDL(2).
