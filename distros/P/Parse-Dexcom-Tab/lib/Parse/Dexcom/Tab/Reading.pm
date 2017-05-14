package Parse::Dexcom::Tab::Reading;
use Moose;
use Moose::Util::TypeConstraints;
use DateTime;
use Date::Parse;

subtype 'Parse::Dexcom::Tab::Reading::DateTimeType';
coerce 'Parse::Dexcom::Tab::Reading::DateTimeType' 
    => from 'Str'
    => via { 
        # Comes in the format in GMT: YYYY-MM-DD HH:MM:SS
        return DateTime->from_epoch( 
            epoch => str2time( $_ )
        );
    };

has 'gmt' => (
    is => 'rw',
    isa => 'Parse::Dexcom::Tab::Reading::DateTimeType',
    coerce => 1
);


__PACKAGE__->meta->make_immutable;
