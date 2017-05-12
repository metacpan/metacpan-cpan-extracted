package t::odea::Calculator;

use Moo;
use MooX::Lazier;

attributes (
    display  => [ 'rw', 0, { clearer => 1 } ],    
);

sub calculate { my $val = eval "$_[0]->display $_[3] $_[1]"; return $_[0]->display($val) }

sub add { return $_[0]->calculate($_[1], '+') }

sub subtract { return $_[0]->calculate($_[1], '-') }

sub multiply { return $_[0]->calculate($_[1], 'x') }

sub divide { return $_[0]->calculate($_[1], '/') }

sub print_display { return print $_[0]->display }

1;

=pod

    use t::odea::Calculator;

    my $calc = t::odea::Calculator->new();

    $calc->add('5');
    $calc->print_display  # 5
    $calc->subtract('2');
    $calc->print_display  # 3
    .....

=cut
