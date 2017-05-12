use strict;
use warnings;

BEGIN { $ENV{PERL_RL} = 'Stub'; }

use Test::More;

use Term::ReadLine 1.09;
use Term::ReadLine::Event;

plan skip_all => "Reflex is not installed" unless eval "
    use Reflex 0.097; # bug in 0.096 that keeps this from working
    use Reflex::Filehandle; 
    use Reflex::Interval;
    1";
plan tests => 2;
diag( "Testing Term::ReadLine::Event: Reflex version $Reflex::VERSION" );

my $term = Term::ReadLine::Event->with_Reflex('test');
isa_ok($term->trl, 'Term::ReadLine::Stub');

my $ticker = Reflex::Interval->new(
                                   interval => 1,
                                   on_tick  => sub {
                                       pass;
                                       print {$term->OUT()} $Term::ReadLine::Stub::rl_term_set[3];
                                       exit 0 
                                   },
                                  );

$term->readline('> Do not type anything');
fail();
