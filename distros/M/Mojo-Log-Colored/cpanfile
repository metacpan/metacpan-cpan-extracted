requires 'perl', '5.008001';
requires 'Term::ANSIColor', '3.00';
requires 'Mojolicious', '5.00';

if ($^O eq 'MSWin32') {
    requires 'Win32::Console::ANSI';
}

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Capture::Tiny';
};

