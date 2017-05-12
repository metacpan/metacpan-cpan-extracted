use Mojo::Base -strict;
use Test::More tests => 7;

use MojoX::Log::Log4perl;

can_ok( 'MojoX::Log::Log4perl', qw( unsubscribe on emit ) );

my $logger = MojoX::Log::Log4perl->new;
isa_ok( $logger, 'Mojo::EventEmitter' );

my $messages = [];
$logger->unsubscribe( 'message' )->on(
  message => sub {
    my ($log, $level, @messages) = @_;
    push @$messages, $level, @messages;
  }
);

$logger->debug( 'Moo', 1, 2, 3 );
is_deeply $messages, [ qw(debug Moo 1 2 3) ], 'right message for debug';

$messages = [];
$logger->info( 'Moo', 1, 2, 3 );
is_deeply $messages, [ qw(info Moo 1 2 3) ], 'right message for info';

$messages = [];
$logger->warn( 'Moo', 1, 2, 3 );
is_deeply $messages, [ qw(warn Moo 1 2 3) ], 'right message for warn';

$messages = [];
$logger->error( 'Moo', 1, 2, 3 );
is_deeply $messages, [ qw(error Moo 1 2 3) ], 'right message for error';

$messages = [];
$logger->fatal( 'Moo', 1, 2, 3 );
is_deeply $messages, [ qw(fatal Moo 1 2 3) ], 'right message for fatal';


