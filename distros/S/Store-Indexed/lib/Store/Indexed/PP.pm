package Store::Indexed::PP;
$Store::Indexed::PP::VERSION = '0.1';
use strict;
use warnings;

sub new {
    my ($class, @keys) = @_;
    
    my $cols = scalar @keys;
    my %offset;
    my $i = 0;
    $offset{$_} = $i++ for sort @keys;
    my $self = bless [], $class;
    for my $key (keys %offset) {
        my $col = $offset{$key};
        no strict 'refs';
        *{"${class}::get_$key"} = sub { $_[0]->[$_[1] * $cols + $col] };
        *{"${class}::set_$key"} = sub { $_[0]->[$_[1] * $cols + $col] = $_[2] };
        *{"${class}::exists_$key"} = sub { exists $_[0]->[$_[1] * $cols + $col] };
        *{"${class}::delete_$key"} = sub { delete $_[0]->[$_[1] * $cols + $col] };
    }

    return $self;
}

1;