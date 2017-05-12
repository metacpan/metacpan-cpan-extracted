package App;
use Moose;

sub run {
    while (<>) {
        sleep 3;
        print "App awake: $$\n";
    }
}

1;
