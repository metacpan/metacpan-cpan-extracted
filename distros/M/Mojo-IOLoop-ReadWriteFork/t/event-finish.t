use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

my $rwf    = Mojo::IOLoop::ReadWriteFork->new;
my $output = '';

$rwf->on(error  => sub { diag "error: @_" });
$rwf->on(finish => sub { Mojo::IOLoop->stop });
$rwf->on(read   => sub { $output .= $_[1] });
$rwf->write("line one\nline two\n", sub { shift->close('stdin'); });
$rwf->run_p(sub { print while <>; print "FORCE\n"; })->wait;

like $output, qr/line one\nline two\nFORCE\n/, 'finish' or diag $output;

my ($got_event, $err, @errors) = (0);
$rwf = Mojo::IOLoop::ReadWriteFork->new;
$rwf->on(error  => sub { push @errors, $_[1]; die 'yikes!' });
$rwf->on(finish => sub { Carp::confess('infinite loop') if $got_event++ < 3 });
$rwf->run_p(sub { })->catch(sub { $err = shift })->wait;
is $got_event, 1, 'avoid infinite loop';
ok !$err,   'promise fullfills, even if close() and error() fail';
ok @errors, 'error was emitted';

undef $rwf;

done_testing;
