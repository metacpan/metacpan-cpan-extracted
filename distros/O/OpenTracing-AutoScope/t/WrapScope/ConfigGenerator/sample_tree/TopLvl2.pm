package TopLvl2;

sub top_2_stuff {
    if (top_2_something()) {
        if (_top_2_something()) {
            return;
        }
        die;
    }
    return top_2_something();
}
sub top_2_something {}
sub _top_2_private {}

1;
