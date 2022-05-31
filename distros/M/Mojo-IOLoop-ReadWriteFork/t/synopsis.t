use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::More;

$ENV{PATH} ||= '';
plan skip_all => 'bash is missing' unless grep { -x "$_/bash" } split /:/, $ENV{PATH};

my $rwf    = Mojo::IOLoop::ReadWriteFork->new;
my $output = '';

$rwf->on(error  => sub { my ($rwf, $error)               = @_; diag $error; });
$rwf->on(finish => sub { my ($rwf, $exit_value, $signal) = @_; Mojo::IOLoop->stop; });
$rwf->on(read   => sub { my ($rwf, $buf)                 = @_; $output .= $buf });
$rwf->conduit({type => "pty"});

$ENV{RWF_INVISIBLE} = 'invisble';
$rwf->run(qw(bash -c), q(echo "$RWF_VISIBLE. RWF_INVISIBLE=$RWF_INVISIBLE."), {env => {RWF_VISIBLE => 'Hello'}});

is $rwf->pid, 0, 'no pid' or diag $rwf->pid;
Mojo::IOLoop->timer(3 => sub { Mojo::IOLoop->stop });    # guard
Mojo::IOLoop->start;
like $rwf->pid, qr{^[1-9]\d+$}, 'got pid' or diag $rwf->pid;

if ($output =~ /Can't exec/) {    # "Can't exec "bash": ..."
  like $output, qr/Can't exec/, 'could not start bash';
}
else {
  like $output, qr/Hello. RWF_INVISIBLE=\./, 'got stdout from "echo"' or diag $output;
}

done_testing;
