use strict;
use warnings;

BEGIN { $ENV{PERL_RL} = 'Stub'; }

use Test::More;

use Term::ReadLine 1.09;
use Term::ReadLine::Event;

plan skip_all => "IO::Async is not installed" unless eval "
    use IO::Async;
    use IO::Async::Loop;
    use IO::Async::Timer::Periodic;
    use IO::Async::Handle;

    1";
plan tests => 2;
diag( "Testing Term::ReadLine::Event: IO::Async version $IO::Async::VERSION" );

my $loop = IO::Async::Loop->new;
my $term = Term::ReadLine::Event->with_IO_Async('test', loop => $loop);
isa_ok($term->trl, 'Term::ReadLine::Stub');

$loop->add(
           IO::Async::Timer::Periodic->new(
                                           interval => 0.1,
                                           on_tick => sub {
                                               pass;
                                               print {$term->OUT()} $Term::ReadLine::Stub::rl_term_set[3];
                                               exit 0
                                           }
                                          )->start
          );


$term->readline('> Do not type anything');
fail();
