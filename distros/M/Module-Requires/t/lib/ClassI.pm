package ClassI;

sub import {
    my($class, @names) = @_;
    my $caller = caller(0);
    if (@names) {
        for my $name (@names) {
            *{"$caller\::$name"} = sub { 'OK' };
        }
    } else {
        *{"$caller\::export"} = sub { 'OK' };
    }
}

1;
