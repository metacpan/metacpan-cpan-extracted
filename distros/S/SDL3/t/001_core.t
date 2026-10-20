use v5.40;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use SDL3 qw[:all];

# Pre-test: Set the dummy driver so we can test safely in headless environments
SDL_SetHint( SDL_HINT_VIDEO_DRIVER, 'dummy' );
SDL_SetHint( SDL_HINT_AUDIO_DRIVER, 'dummy' );
subtest ':audio' => sub {
    imported_ok qw[SDL_Init SDL_Quit SDL_INIT_AUDIO SDL_GetNumAudioDrivers SDL_GetAudioDriver];
    ok SDL_Init(SDL_INIT_AUDIO), 'SDL_Init(SDL_INIT_AUDIO)';
    my $num_drivers = SDL_GetNumAudioDrivers();
    ok $num_drivers >= 0, "Number of audio drivers: $num_drivers";
    if ( $num_drivers > 0 ) {
        my $driver = SDL_GetAudioDriver(0);
        ok defined($driver), "First audio driver: $driver";
    }
    SDL_Quit();
};
subtest ':joystick and :gamepad' => sub {
    imported_ok qw[SDL_Init SDL_Quit SDL_INIT_JOYSTICK SDL_INIT_GAMEPAD SDL_HasJoystick SDL_HasGamepad];
    ok SDL_Init( SDL_INIT_JOYSTICK | SDL_INIT_GAMEPAD ), 'SDL_Init(JOYSTICK | GAMEPAD)';

    # We might not have a joystick/gamepad on CI, but the call should still be valid.
    my $has_joystick = SDL_HasJoystick();
    my $has_gamepad  = SDL_HasGamepad();

    # Just verify they return boolean-ish values (not crashing)
    ok defined($has_joystick), "SDL_HasJoystick: " . ( $has_joystick ? 'Yes' : 'No' );
    ok defined($has_gamepad),  "SDL_HasGamepad: " .  ( $has_gamepad  ? 'Yes' : 'No' );
    SDL_Quit();
};
subtest ':sensor' => sub {
    imported_ok qw[SDL_Init SDL_Quit SDL_INIT_SENSOR SDL_GetSensors];
    ok SDL_Init(SDL_INIT_SENSOR), 'SDL_Init(SDL_INIT_SENSOR)';
    my $count   = 0;
    my $sensors = SDL_GetSensors( \$count );
    ok defined($count), "Sensor count: $count";

    # On many desktop/CI environments, this will be 0, which is fine.
    SDL_Quit();
};
subtest ':power' => sub {
    imported_ok qw[SDL_GetPowerInfo SDL_POWERSTATE_UNKNOWN];
    my ( $seconds, $percent ) = ( 0, 0 );
    my $state = SDL_GetPowerInfo( \$seconds, \$percent );
    ok defined($state),   "Power state: $state";
    ok defined($seconds), "Seconds: $seconds";
    ok defined($percent), "Percent: $percent";
};
subtest 'Dynamic Memory IOStream' => sub {
    imported_ok qw[
        SDL_IOFromDynamicMem SDL_WriteU32LE SDL_ReadU32LE
        SDL_SeekIO SDL_TellIO SDL_GetIOSize SDL_CloseIO SDL_IO_SEEK_SET
    ];
    my $io = SDL_IOFromDynamicMem();
    ok $io, 'Created dynamic memory SDL_IOStream';
    if ($io) {

        # Write two 32-bit unsigned little-endian integers (0x12345678 and 0xAABBCCDD)
        ok SDL_WriteU32LE( $io, 0x12345678 ), 'Wrote first uint32';
        ok SDL_WriteU32LE( $io, 0xAABBCCDD ), 'Wrote second uint32';
        is SDL_TellIO($io),    8, 'Stream position is at 8 bytes';
        is SDL_GetIOSize($io), 8, 'Total stream size is 8 bytes';

        # Seek back to beginning
        ok SDL_SeekIO( $io, 0, SDL_IO_SEEK_SET() ) >= 0, 'Seeked to start';

        # Read back and verify values
        my $val1 = 0;
        ok SDL_ReadU32LE( $io, \$val1 ), 'Read first uint32';
        is $val1, 0x12345678, 'First value matches';
        my $val2 = 0;
        ok SDL_ReadU32LE( $io, \$val2 ), 'Read second uint32';
        is $val2, 0xAABBCCDD, 'Second value matches';
        SDL_CloseIO($io);
        pass 'Closed dynamic IOStream';
    }
};
subtest 'Custom Event Registration & Dispatch' => sub {
    imported_ok qw[
        SDL_Init SDL_Quit SDL_INIT_EVENTS
        SDL_RegisterEvents SDL_PushEvent SDL_PollEvent
    ];
    ok SDL_Init(SDL_INIT_EVENTS), 'SDL_Init(SDL_INIT_EVENTS)';
    my $custom_event_type = SDL_RegisterEvents(1);
    ok $custom_event_type != 0xFFFFFFFF, "Registered custom event type ID: $custom_event_type";
    my $event = { user => { type => $custom_event_type, code => 42 } };
    ok SDL_PushEvent($event), 'SDL_PushEvent queued custom event';
    my $polled;
    my $found = 0;

    while ( SDL_PollEvent($polled) ) {
        if ( defined $polled && defined $polled->{type} && $polled->{type} == $custom_event_type ) {
            $found = 1;

            # Affix flattens the union, so 'code' lives directly on $polled
            is $polled->{user}{code}, 42, 'Polled event preserved user code';
            last;
        }
    }
    ok $found, 'Successfully retrieved custom event from queue';
    SDL_Quit();
};
#
done_testing;
