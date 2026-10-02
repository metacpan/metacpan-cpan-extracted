use strict;
use Test::More;

use Redis::Namespace;

# a dummy redis client that records the arguments
{
    package Dummy::Redis;
    our $AUTOLOAD;
    sub new { bless { calls => [] }, shift }
    sub DESTROY { }
    sub AUTOLOAD {
        my ($self, @args) = @_;
        my $command = $AUTOLOAD;
        $command =~ s/.*:://;
        push @{$self->{calls}}, [$command, @args];

        # emulate the behavior of Redis.pm
        my $reply = delete $self->{reply};
        if (@args && ref $args[-1] eq 'CODE') {
            $args[-1]->($reply, undef);
            return 1;
        }
        return wantarray && ref $reply eq 'ARRAY' ? @$reply : $reply;
    }
}

my $redis = Dummy::Redis->new;
my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

sub last_call {
    my $call = pop @{$redis->{calls}};
    @{$redis->{calls}} = ();
    return $call;
}

subtest 'generated commands' => sub {
    $ns->exists('foo', 'bar');
    is_deeply last_call(), ['exists', 'ns:foo', 'ns:bar'], 'exists';

    $ns->copy('foo', 'bar', 'REPLACE');
    is_deeply last_call(), ['copy', 'ns:foo', 'ns:bar', 'REPLACE'], 'copy';

    $ns->lmove('foo', 'bar', 'LEFT', 'RIGHT');
    is_deeply last_call(), ['lmove', 'ns:foo', 'ns:bar', 'LEFT', 'RIGHT'], 'lmove';

    $ns->lmpop(2, 'foo', 'bar', 'LEFT', 'COUNT', 1);
    is_deeply last_call(), ['lmpop', 2, 'ns:foo', 'ns:bar', 'LEFT', 'COUNT', 1], 'lmpop';

    $ns->blmpop(0, 2, 'foo', 'bar', 'LEFT');
    is_deeply last_call(), ['blmpop', 0, 2, 'ns:foo', 'ns:bar', 'LEFT'], 'blmpop';

    $ns->zunion(2, 'foo', 'bar', 'WEIGHTS', 1, 2);
    is_deeply last_call(), ['zunion', 2, 'ns:foo', 'ns:bar', 'WEIGHTS', 1, 2], 'zunion';

    $ns->msetex(2, 'foo', 'a', 'bar', 'b', 'EX', 10);
    is_deeply last_call(), ['msetex', 2, 'ns:foo', 'a', 'ns:bar', 'b', 'EX', 10], 'msetex';

    $ns->lcs('foo', 'bar', 'LEN');
    is_deeply last_call(), ['lcs', 'ns:foo', 'ns:bar', 'LEN'], 'lcs';

    $ns->bitop('AND', 'dest', 'foo', 'bar');
    is_deeply last_call(), ['bitop', 'AND', 'ns:dest', 'ns:foo', 'ns:bar'], 'bitop';

    # Valkey only
    $ns->delifeq('foo', 'value');
    is_deeply last_call(), ['delifeq', 'ns:foo', 'value'], 'delifeq';

    # shard channels
    $ns->spublish('foo', 'message');
    is_deeply last_call(), ['spublish', 'ns:foo', 'message'], 'spublish';

    $ns->ssubscribe('foo', 'bar');
    is_deeply last_call(), ['ssubscribe', 'ns:foo', 'ns:bar'], 'ssubscribe';
};

subtest 'keyword' => sub {
    $ns->georadius('foo', 0, 0, 10, 'km', 'STORE', 'bar', 'STOREDIST', 'baz');
    is_deeply last_call(), ['georadius', 'ns:foo', 0, 0, 10, 'km', 'STORE', 'ns:bar', 'STOREDIST', 'ns:baz'], 'georadius';

    $ns->migrate('localhost', 6379, '', 0, 1000, 'REPLACE', 'KEYS', 'foo', 'bar');
    is_deeply last_call(), ['migrate', 'localhost', 6379, '', 0, 1000, 'REPLACE', 'KEYS', 'ns:foo', 'ns:bar'], 'migrate';

    $ns->migrate('localhost', 6379, 'foo', 0, 1000, 'AUTH2', 'keys', 'password');
    is_deeply last_call(), ['migrate', 'localhost', 6379, 'ns:foo', 0, 1000, 'AUTH2', 'keys', 'password'], 'migrate with AUTH2';

    $ns->migrate('localhost', 6379, '', 0, 1000, 'AUTH', 'keys', 'KEYS', 'foo', 'keys', 'bar');
    is_deeply last_call(), ['migrate', 'localhost', 6379, '', 0, 1000, 'AUTH', 'keys', 'KEYS', 'ns:foo', 'ns:keys', 'ns:bar'], 'migrate with AUTH and KEYS';

    $ns->xread('COUNT', 2, 'STREAMS', 'foo', 'bar', 0, 0);
    is_deeply last_call(), ['xread', 'COUNT', 2, 'STREAMS', 'ns:foo', 'ns:bar', 0, 0], 'xread';

    $ns->xreadgroup('GROUP', 'group', 'streams', 'STREAMS', 'foo', '>');
    is_deeply last_call(), ['xreadgroup', 'GROUP', 'group', 'streams', 'STREAMS', 'ns:foo', '>'], 'xreadgroup';
};

subtest 'after filters' => sub {
    $redis->{reply} = ['ns:foo', 'ns:value'];
    is_deeply [$ns->blpop('foo', 0)], ['foo', 'ns:value'], 'list context';
    last_call();

    $redis->{reply} = ['ns:foo', 'ns:value'];
    is_deeply scalar($ns->blpop('foo', 0)), ['foo', 'ns:value'], 'scalar context';
    last_call();

    my $result;
    $redis->{reply} = ['ns:foo', 'ns:value'];
    $ns->blpop('foo', 0, sub { $result = shift });
    is_deeply $result, ['foo', 'ns:value'], 'callback';
    my $call = last_call();
    is_deeply [@$call[0..2]], ['blpop', 'ns:foo', 0], 'callback is passed';
    is ref $call->[3], 'CODE', 'callback is passed';

    $redis->{reply} = ['ns:foo', 'ns:bar'];
    is_deeply [$ns->keys('*')], ['foo', 'bar'], 'keys';
    is_deeply last_call(), ['keys', 'ns:*'], 'keys';

    $redis->{reply} = [0, ['ns:foo', 'ns:bar']];
    is_deeply [$ns->scan(0)], [0, ['foo', 'bar']], 'scan';
    is_deeply last_call(), ['scan', 0, 'match', 'ns:*'], 'scan';
};

subtest 'upper case method names' => sub {
    $ns->GET('foo');
    is_deeply last_call(), ['get', 'ns:foo'], 'GET';
};

subtest 'sub-commands' => sub {
    $ns->object_encoding('foo');
    is_deeply last_call(), ['object_encoding', 'ns:foo'], 'object_encoding';

    $ns->object('ENCODING', 'foo');
    is_deeply last_call(), ['object', 'ENCODING', 'ns:foo'], 'object ENCODING';

    $ns->memory('usage', 'foo');
    is_deeply last_call(), ['memory', 'usage', 'ns:foo'], 'memory usage';

    $ns->xgroup_create('foo', 'group', '$');
    is_deeply last_call(), ['xgroup_create', 'ns:foo', 'group', '$'], 'xgroup_create';

    $ns->client_list;
    is_deeply last_call(), ['client_list'], 'client_list';

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $ns->client('unknown-subcommand', 'foo');
    is_deeply last_call(), ['client', 'unknown-subcommand', 'foo'], 'unknown sub-command';
    like $warnings[0], qr/unknown command 'client unknown-subcommand'/, 'warn unknown sub-command';
};

subtest 'strict mode' => sub {
    my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns', strict => 1);
    eval { $ns->client('unknown-subcommand', 'foo') };
    like $@, qr/unknown command 'client unknown-subcommand'/, 'croak unknown sub-command';

    eval { $ns->unknown_command('foo') };
    like $@, qr/unknown command 'unknown_command'/, 'croak unknown command';

    eval { $ns->config_get('foo') };
    like $@, qr/unsafe command 'config'/, 'croak unsafe sub-command';

    eval { $ns->flushall };
    like $@, qr/unsafe command 'flushall'/, 'croak unsafe command';

    eval { $ns->cluster_migrateslots };
    like $@, qr/unsafe command 'cluster'/, 'croak unsafe sub-command of Valkey';

    eval { $ns->acl_setuser('user') };
    like $@, qr/unsafe command 'acl setuser'/, 'croak unsafe sub-command method';

    eval { $ns->acl('SETUSER', 'user') };
    like $@, qr/unsafe command 'acl setuser'/, 'croak unsafe sub-command';

    $ns->acl_whoami;
    is_deeply last_call(), ['acl_whoami'], 'safe sub-command method';

    $ns->acl('WHOAMI');
    is_deeply last_call(), ['acl', 'WHOAMI'], 'safe sub-command';
};

done_testing;
