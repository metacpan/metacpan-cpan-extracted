package TAEB::Meta::Overload;
use strict;
use warnings;
use Scalar::Util 'refaddr';

our %comparison = (
    q{==} => sub {
        my $self = shift;
        my $other = shift;

        refaddr($self) == refaddr($other)
    },
    q{!=} => sub {
        my $self = shift;
        my $other = shift;

        not($self == $other);
    },
);

$comparison{eq} = $comparison{'=='};
$comparison{ne} = $comparison{'!='};

our %stringification = (
    q{""} => sub {
        my $self = shift;
        sprintf "[%s: %s]",
            $self->meta->name,
            $self->debug_line;
    },
);

our %default = (
    fallback => undef,
    %comparison,
    %stringification,
);

1;

