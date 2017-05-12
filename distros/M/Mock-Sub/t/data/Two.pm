package Two;

use lib '.';
use One;

sub test {
    my $obj = One->new;
    $obj->foo;
}
sub test2 {
    my $obj = One->new;
    $obj->bar;
}
sub test3 {
    my $obj = One->new;
    $obj->baz;
}

1;
