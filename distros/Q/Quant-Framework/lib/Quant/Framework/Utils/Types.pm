package Quant::Framework::Utils::Types;

use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw(Int Num Str);
use Moose::Util::TypeConstraints;

subtype 'qf_date_object', as 'Date::Utility';
coerce 'qf_date_object', from 'Str', via { Date::Utility->new($_) };

=head2 qf_timestamp

A valid ISO8601 timestamp, restricted specifically to the YYYY-MM-DDTHH:MI:SS format. Optionally, "Z", "UTC", or "GMT" can be appended to the end. No other time zones are supported.

qf_timestamp can be coerced from C<Date::Utility>

=cut

subtype 'qf_timestamp', as Str, where {
    if (/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|GMT|UTC)?$/) {
        my $date = try {
            DateTime->new(
                year      => $1,
                month     => $2,
                day       => $3,
                hour      => $4,
                minute    => $5,
                second    => $6,
                time_zone => 'GMT'
            );
        };
        return $date ? 1 : 0;
    } else {
        return 0;
    }
}, message {
    "Invalid timestamp $_, please use YYYY-MM-DDTHH:MM:SSZ format";
};

coerce 'qf_timestamp', from 'qf_date_object', via { $_->datetime_iso8601 };

my @interest_rate_types = qw(implied market);
subtype 'qf_interest_rate_type', as Str, where {
    my $regex = '(' . join('|', @interest_rate_types) . ')';
    /^$regex$/
}, message {
    "Invalid interest_rate type $_. Must be one of: " . join(', ', @interest_rate_types)
};

=head2 qf_surface_type

Volatility surface types.

=cut

my @surface_types = qw( delta flat moneyness);
subtype 'qf_surface_type', as Str, where {
    my $regex = '(' . join('|', @surface_types) . ')';
    /^$regex$/;
}, message {
    "Invalid surface type $_. Must be one of: " . join(', ', @surface_types);
};

1;
