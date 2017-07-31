use strict;
use warnings;

use Test::More;
use Test::Deep;

use Ryu;

subtest 'map with sub' => sub {
    my $src = Ryu::Source->new;
    my @actual;
    $src->map(sub { 2 * $_ })->each(sub {
        push @actual, $_;
    });
    $src->emit(1..3);
    cmp_deeply(\@actual, [ map 2 * $_, 1..3 ], 'map operation was performed');
    done_testing;
};

subtest 'map with hashref key' => sub {
    my $src = Ryu::Source->new;
    my @actual;
    $src->map('something')->each(sub {
        push @actual, $_;
    });
    $src->emit({ something => 7 });
    $src->emit({ else => 3, something => 6 });
    $src->emit({ random => 4, stuff => 5 });
    $src->emit({ something => 'test' });
    cmp_deeply(\@actual, [ 7, 6, undef, 'test' ], 'map operation was performed');
    done_testing;
};

subtest 'map with method name' => sub {
    my $src = Ryu::Source->new;
    {
        package Example::Class;
        sub new { bless { @_[1..$#_] }, $_[0] }
        sub something { shift->{item} }
    }
    my @actual;
    $src->map('something')->each(sub {
        push @actual, $_;
    });
    $src->emit(Example::Class->new(item => 8));
    $src->emit(Example::Class->new());
    $src->emit(Example::Class->new(item => 'test'));
    cmp_deeply(\@actual, [ 8, undef, 'test' ], 'map operation was performed');
    done_testing;
};
done_testing;

