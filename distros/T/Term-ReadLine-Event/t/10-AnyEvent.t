use strict;
use warnings;

BEGIN { $ENV{PERL_RL} = 'Stub'; }
BEGIN { $^W = 0 } # common::sense does funny things, we don't need to hear about it.

use Test::More;

use Term::ReadLine 1.09;
use Term::ReadLine::Event;

BEGIN {
    plan skip_all => "AnyEvent is not installed" unless eval "use AnyEvent; 1";
}
plan tests => 2;
diag( "Testing Term::ReadLine::Event: AnyEvent version $AnyEvent::VERSION" );

my $term = Term::ReadLine::Event->with_AnyEvent('test');
isa_ok($term->trl, 'Term::ReadLine::Stub');

my $w = AE::timer(0.1,0,
                  sub {
                      pass;
                      print {$term->OUT()} $Term::ReadLine::Stub::rl_term_set[3];
                      exit 0 
                  });

$term->readline('> Do not type anything');
fail();
