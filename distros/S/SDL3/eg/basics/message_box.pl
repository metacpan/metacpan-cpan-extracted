use v5.38;
use SDL3 qw[:all];

# Pops up two message boxes. The first is the complex version with mutiple buttons. The second is
# very simple.
#
# Controls:
#  - Click somethng.
#
SDL_ShowMessageBox(
    {   flags      => 0,
        window     => undef,
        title      => 'Wow!',
        message    => 'Hi!',
        numbuttons => 4,
        buttons    => [
            { buttonID => 1, text => 'One' },
            { buttonID => 2, text => 'Two' },
            { buttonID => 3, text => 'Three' },
            { buttonID => 4, text => 'Four' }
        ]
    },
    my $btn
);
say 'User clicked button #' . $btn;
#
SDL_ShowSimpleMessageBox( SDL_MESSAGEBOX_INFORMATION, 'Hi', 'Hello', undef );
