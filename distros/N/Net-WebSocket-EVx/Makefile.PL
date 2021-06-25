use strict;
use ExtUtils::MakeMaker;
use EV::MakeMaker 'ev_args';
use Alien::Base::Wrapper ();

WriteMakefile(Alien::Base::Wrapper->new('Alien::Wslay')->mm_args2(ev_args(
    NAME => "Net::WebSocket::EVx",
    VERSION_FROM => "lib/Net/WebSocket/EVx.pm"
)));
