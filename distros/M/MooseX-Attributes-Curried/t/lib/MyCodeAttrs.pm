package MyCodeAttrs;
use MooseX::Attributes::Curried (
    has_guess => sub {
        if (/^\w$/) {
            return {
                isa => 'Int',
                %{$_[0]},
                @{$_[1]},
            };
        }
        else {
            return {
                isa => 'Str',
                %{$_[0]},
                @{$_[1]},
            };
        }
    },
);

1;


