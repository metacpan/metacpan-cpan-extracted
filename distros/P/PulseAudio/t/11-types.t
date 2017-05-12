use PulseAudio::Types q(:all);
use Test::More tests => 9;

ok ( is_PA_Volume( 0x10000 ), 'Valid PA_Volume' );
ok ( is_PA_Volume( 0 ), 'Valid PA_Volume' );
ok ( is_PA_Volume( 65536 ), 'Valid PA_Volume' );

is ( to_PA_Volume( '100%' ), 0x10000, 'Coercion to_PA_VOLUME (full-vol)' );
is ( to_PA_Volume( 'MAX' ), 0x10000, 'Coercion to_PA_VOLUME (full-vol)' );
is ( to_PA_Volume( '50%' ), 0x10000 * 0.5, 'Coercion to_PA_VOLUME (half-vol)' );
is ( to_PA_Volume( 'HALF' ), 0x10000 * 0.5, 'Coercion to_PA_VOLUME (half-vol)' );
is ( to_PA_Volume( '0%' ), 0, 'Coercion to_PA_VOLUME (mute-vol)' );
is ( to_PA_Volume( 'MIN' ), 0, 'Coercion to_PA_VOLUME (mute-vol)' );

1;
