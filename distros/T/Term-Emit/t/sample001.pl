#!perl -w
use strict;
use warnings;
use Term::Emit qw/:all/;

emit "Contract to build house";
build_house();
emit_done;

exit 0;

sub build_house {
    emit "Building house";
    sitework();
    shell();
    emit_text "
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Vestibulum varius libero nec emitus. Mauris eget ipsum eget quam sodales ornare. Suspendisse nec nibh. Duis lobortis mi at augue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.
";
    mechanical();
    finish();
    emit_done;
}

sub sitework {
    emit;
    sleep 1;  #simulate doing something
    emit_ok;
}


sub shell {
    emit;
    foundation();
    framing();
    roofing();
    emit_ok;
}

sub foundation {
    my $tracker = emit;
    sleep 1;  #simulate doing something
    # Omit closing, will automatically be closed
}

sub framing {
    emit "Now we do the framing task, which has a really long text title that should wrap nicely in the space we give it";
    sleep 1;  #simulate doing something
    emit_warn;
}

sub roofing {
    emit;
    sleep 1;  #simulate doing something
    emit_ok;
}

sub mechanical {
    emit "The MECHANICAL task is also a lengthy one so this is a bunch of text that should also wrap";
    electrical();
    plumbing();
    hvac();
    emit_fail;
}

sub electrical {
    emit;
    sleep 1;  #simulate doing something
    emit_ok;
}

sub plumbing {
    emit;
    sleep 1;  #simulate doing something
    emit_ok;
}

sub hvac {
    emit;
    sleep 1;  #simulate doing something
    emit_ok;
}

sub finish {
    emit;
    sleep 1;  #simulate doing something
    emit_ok;
}