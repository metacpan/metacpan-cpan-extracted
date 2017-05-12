#!/usr/bin/perl
use Test::More tests => 1;
SKIP: {

      skip 'MouseX::POE::Role is currently borken', 1;

{
    package Getty;
    use Mouse::Role;
}

{
    package Pants;
    use MouseX::POE::Role;

    event 'wear' => sub {
        ::pass("I AM BEING WORN!");
    };
}

{
    package Clocks;
    use MouseX::POE;
    with 'Pants', 'Getty';

    sub bork {
        my ($self) = @_;
	::pass('bork');
        $self->yield('wear');
    }
}



my $c = Clocks->new;
$c->bork;
POE::Kernel->run;

}
