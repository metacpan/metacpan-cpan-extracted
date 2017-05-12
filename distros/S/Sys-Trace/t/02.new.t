use Test::More;
use Sys::Trace;
use POSIX ();
use My::CanTrace tests => 1;

my $trace = Sys::Trace->new;
isa_ok $trace, "Sys::Trace";

