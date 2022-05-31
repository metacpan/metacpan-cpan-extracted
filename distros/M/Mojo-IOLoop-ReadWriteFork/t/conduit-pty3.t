use Mojo::Base -strict;
use Test::More;
use Mojo::File qw(path);
use Mojo::IOLoop::ReadWriteFork;

plan skip_all => 'READWRITEFORK_SSH=host is not set' unless $ENV{READWRITEFORK_SSH};

my $password ||= -e '.readwritefork_ssh_password' ? path('.readwritefork_ssh_password')->slurp : 's3cret';
chomp $password;

my @ssh_options = (
  -o => 'IdentitiesOnly=no',
  -o => 'NumberOfPasswordPrompts=1',
  -o => 'PreferredAuthentications=keyboard-interactive,password'
);

my $rwf = Mojo::IOLoop::ReadWriteFork->new->conduit({type => 'pty3'});
my %out = map { ($_ => '') } qw(pty stderr stdout);

$rwf->on(
  pty => sub {
    my ($rwf, $chunk) = @_;
    $out{pty} .= $chunk;
    $rwf->write("$password\n") if $chunk =~ m![Pp]assword:!;
  }
);

$rwf->on(
  stderr => sub {
    my ($rwf, $chunk) = @_;
    $out{stderr} .= $chunk;
  }
);

$rwf->on(
  stdout => sub {
    my ($rwf, $chunk) = @_;
    $out{stdout} .= $chunk;
  }
);

$rwf->run_p(ssh => @ssh_options, $ENV{READWRITEFORK_SSH}, qw(ls -l /))->wait;
like $out{pty},    qr{password:\s+$}s, 'pty';
like $out{stdout}, qr{\sroot\s}s,      'stdout';
is $out{stderr}, '', 'stderr';

done_testing;
