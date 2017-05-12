#!perl -w
use strict;
use warnings;
use Term::Emit qw/:all/, {-color => 1,
                    -fh => *STDERR};

{   emit "Watch the percentage climb";
    for (1..10) {
        emit_over " " . ($_ * 10) . "%";
        select(undef,undef,undef, 0.100);
    }
    emit_over ""; # erase the percentage
}

{   emit "Watch the dots move";
    for (1..40) {
        emit_prog $_%10?q:.::':'; # just being difficult...ha!
        select(undef,undef,undef, 0.100);
    }
}

{   emit "Here's a spinner";
    my @spin = qw{| / - \\ | / - \\};
    for (1..64) {
        emit_over $spin[$_ % @spin];
        select(undef,undef,undef, 0.125);
    }
    emit_over;  # remove spinner
}

{   emit "Zig zags on parade";
    for (1..200) {
        emit_prog $_%2? '/' : '\\';
        select(undef,undef,undef, 0.025);
    }
}


{   emit "Making progress";
    for (1..10) {
        emit_over " $_/10";
        select(undef,undef,undef, 0.100);
    }
}

{   emit "Engines on";
    for (reverse(1..5)) {
        emit_prog " $_ ";
        select(undef,undef,undef, 1.000);
    }
    emit_done "Gone!";
}

exit 0;
