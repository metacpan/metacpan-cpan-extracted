use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

$ENV{PATH} ||= '';
plan skip_all => 'bash is missing' unless grep { -x "$_/bash" } split /:/, $ENV{PATH};

my $fork   = Mojo::IOLoop::ReadWriteFork->new;
my $output = '';

$fork->on(error  => sub { my ($fork, $error)               = @_; diag $error; });
$fork->on(finish => sub { my ($fork, $exit_value, $signal) = @_; Mojo::IOLoop->stop; });
$fork->on(read   => sub { my ($fork, $buf)                 = @_; $output .= $buf });
$fork->conduit({type => "pty"});

$ENV{RWF_INVISIBLE} = 'invisble';
$fork->run(qw(bash -c), q(echo "$RWF_VISIBLE. RWF_INVISIBLE=$RWF_INVISIBLE."), {env => {RWF_VISIBLE => 'Hello'}});

is $fork->pid, 0, 'no pid' or diag $fork->pid;
Mojo::IOLoop->timer(3 => sub { Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;
like $fork->pid, qr{^[1-9]\d+$}, 'got pid' or diag $fork->pid;

if ($output =~ /Can't exec/) {    # "Can't exec "bash": ..."
  like $output, qr/Can't exec/, 'could not start bash';
}
else {
  like $output, qr/Hello. RWF_INVISIBLE=\./, 'got stdout from "echo"' or diag $output;
}

done_testing;
