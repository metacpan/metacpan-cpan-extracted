#!/usr/bin/perl
use Test::More tests => 9;

BEGIN {
    use_ok('POE');
    use_ok('POE::Kernel');
    use_ok('POE::Session');
    use_ok('POE::Wheel::VimColor');
}

# TEST: Basic usage. 
{
    local $w;
    POE::Session->create(
        inline_states => {
            _start    => sub {
                $w = POE::Wheel::VimColor->new(DoneEvent => 'colorized');
                $w->put('print "hi\n";', 'perl');
                $_[HEAP]->{x} = 0;
                return;
            },
            _stop     => sub { },
            colorized => sub {
                $_[HEAP]->{x}++;
                if ($_[HEAP]->{x} == 1) {
                    like($_[ARG0], qr/span/, "Got HTML in handler");
                    like($_[ARG0], qr/hi/, "Got right code in handler");
                    $w->put('print "bye\n";', 'perl') 
                } else {
                    like($_[ARG0], qr/span/, "Got HTML in handler");
                    like($_[ARG0], qr/bye/, "Got right code in handler");
                    $w = undef;
                }
                return;
            },
        }
    );


    POE::Kernel->run();
    ok(1, "Kernel Ended");
}
