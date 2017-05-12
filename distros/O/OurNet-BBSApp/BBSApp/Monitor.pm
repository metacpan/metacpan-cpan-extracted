package OurNet::BBSApp::Monitor;

use vars qw/@blacklist @newblacklist/;

sub add {
    push @newblacklist, $_[0];
}

sub del {
    my $trg = shift;
    my @nl;
    foreach my $item (@blacklist) {
        push @nl, $item unless $item eq $trg;
    }
    @blacklist = @nl;
}

sub process {
    foreach my $item (@newblacklist) {
        $item->refresh;
        push @blacklist, $item;
        $item->process;
    }

    @newblacklist = ();

    foreach my $item (@blacklist) {
        $item->process if $item->refresh;
    }
}

1;
