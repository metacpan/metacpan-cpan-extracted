use Test::More;

BEGIN { $ENV{PERL_RL} = 'Stub o=0'; }
BEGIN { $^W = 0 } # common::sense does funny things, we don't need to hear about it.

use strict;
use warnings;

use Term::ReadLine 1.09;
use Term::ReadLine::Event;

BEGIN {
    plan skip_all => "AnyEvent is not installed" unless eval "use AnyEvent; 1";
    plan skip_all => "Coro is not installed" unless eval "use Coro; use Coro::AnyEvent; 1";
}
plan tests => 1;
diag( "Testing Term::ReadLine::Event: AnyEvent version $AnyEvent::VERSION" );
diag( "Testing Term::ReadLine::Event: Coro version $Coro::VERSION" );

my $term = Term::ReadLine::Event->with_Coro('test');

Coro::async {
    Coro::AnyEvent::sleep(0.1);
    print {$term->OUT()} $Term::ReadLine::Stub::rl_term_set[3];
    pass();
    exit 0
};

$term->readline('> Do not type anything');
fail();
