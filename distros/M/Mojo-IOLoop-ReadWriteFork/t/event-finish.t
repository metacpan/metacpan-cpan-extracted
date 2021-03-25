use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $fork   = Mojo::IOLoop::ReadWriteFork->new;
my $output = '';

$fork->on(error  => sub { diag "error: @_" });
$fork->on(finish => sub { Mojo::IOLoop->stop });
$fork->on(read   => sub { $output .= $_[1] });
$fork->write("line one\nline two\n", sub { shift->close('stdin'); });
$fork->run_p(sub { print while <>; print "FORCE\n"; })->wait;

like $output, qr/line one\nline two\nFORCE\n/, 'finish' or diag $output;

my ($got_event, $err, @errors) = (0);
$fork = Mojo::IOLoop::ReadWriteFork->new;
$fork->on(error  => sub { push @errors, $_[1]; die 'yikes!' });
$fork->on(finish => sub { Carp::confess('infinite loop') if $got_event++ < 3 });
$fork->run_p(sub { })->catch(sub { $err = shift })->wait;
is $got_event, 1, 'avoid infinite loop';
ok !$err,   'promise fullfills, even if close() and error() fail';
ok @errors, 'error was emitted';

undef $fork;

done_testing;
