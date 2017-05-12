package ClassH;

sub import {
    my $caller = caller(0);
    no warnings 'redefine';
    *{"$caller\::export"} = sub { 'OK' };
}

1;

