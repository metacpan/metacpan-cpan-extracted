use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;

# A closed channel has self->channel == NULL. Before the guard every channel
# method handed that NULL straight to libssh, which absorbed it and returned
# a plausible-looking value: exit_status() gave -1 (indistinguishable from
# "the remote process has not exited yet") and read() gave "". A caller that
# got the documented order wrong therefore got silent wrong answers instead
# of an error. Each method must now croak.

my $srv = TestSSHD->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

my $ssh = Net::LibSSH->new;
$ssh->option(host       => $srv->host);
$ssh->option(port       => $srv->port);
$ssh->option(user       => scalar getpwuid($<));
$ssh->option(knownhosts => $srv->known_hosts);

$ssh->connect
    or plan skip_all => 'connect failed: ' . ($ssh->error // '');
$ssh->auth_publickey($srv->client_key)
    or plan skip_all => 'auth failed: ' . ($ssh->error // '');

my $ch = $ssh->channel;
ok defined $ch, 'channel() returns object';

# The documented order still works: read the output and the exit status
# while the channel is open.
ok $ch->exec('echo hello'), 'exec() succeeds on an open channel';
my $out = $ch->read;
chomp $out;
is $out, 'hello', 'read() returns output on an open channel';
is $ch->exit_status, 0, 'exit_status() readable before close()';

$ch->close;

# close() owns teardown and must stay idempotent — svt_free calls the same
# path again when the SV is collected.
eval { $ch->close; 1 };
is $@, '', 'close() is idempotent';

for my $case (
    [ exec        => sub { $_[0]->exec('echo x') } ],
    [ read        => sub { $_[0]->read           } ],
    [ read        => sub { $_[0]->read(16)       } ],
    [ write       => sub { $_[0]->write('x')     } ],
    [ send_eof    => sub { $_[0]->send_eof       } ],
    [ eof         => sub { $_[0]->eof            } ],
    [ exit_status => sub { $_[0]->exit_status    } ],
) {
    my ($method, $code) = @$case;
    my $rv = eval { $code->($ch); 1 };
    ok !$rv, "$method() after close() does not return a value";
    like $@, qr/\QNet::LibSSH::Channel::$method\E: channel is closed/,
        "$method() after close() croaks naming the method";
}

# A fresh channel on the same session is unaffected by the close above.
my $ch2 = $ssh->channel;
ok defined $ch2, 'channel() still works after a channel was closed';
ok $ch2->exec('exit 42'), 'exec() succeeds on the new channel';
$ch2->read;
is $ch2->exit_status, 42, 'exit_status() on the new channel is correct';
$ch2->close;

done_testing;
