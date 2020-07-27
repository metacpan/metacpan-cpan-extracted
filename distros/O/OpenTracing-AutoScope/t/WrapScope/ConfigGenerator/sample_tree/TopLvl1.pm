package TopLvl1;

sub top_1_stuff {
    if (top_1_something()) {
        if (_top_1_something()) {
            return;
        }
        die;
    }
    return top_1_something();
}
sub top_1_something {}
sub _top_1_private {}

1;
