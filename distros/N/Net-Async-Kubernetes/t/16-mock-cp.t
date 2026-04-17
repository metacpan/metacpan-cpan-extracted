use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use IO::Async::Loop;
use Future;

use Net::Async::Kubernetes;

{
    package Test::CP::Session;
    use strict;
    use warnings;
    use Future;

    sub new { bless { writes => [] }, shift }
    sub write_stdin {
        my ($self, $chunk) = @_;
        push @{$self->{writes}}, $chunk;
        return Future->done(1);
    }
    sub writes { $_[0]->{writes} }
}

sub make_kube {
    my ($loop) = @_;
    my $kube = Net::Async::Kubernetes->new(
        server      => { endpoint => 'https://mock.local' },
        credentials => { token => 'mock-token' },
        resource_map_from_cluster => 0,
    );
    $loop->add($kube);
    return $kube;
}

subtest 'cp_to_pod streams local bytes via exec stdin' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);
    my $tmp = tempdir(CLEANUP => 1);
    my $local = File::Spec->catfile($tmp, 'in.txt');
    my $content = "hello\nworld\n";
    open my $fh, '>:raw', $local or die $!;
    print {$fh} $content;
    close $fh;

    my ($captured, $session);
    no warnings 'redefine';
    local *Net::Async::Kubernetes::exec = sub {
        my ($self, $short, $name, %args) = @_;
        $captured = { short => $short, name => $name, %args };
        $session = Test::CP::Session->new;
        $self->loop->later(sub { $args{on_close}->() if $args{on_close} });
        return Future->done($session);
    };

    my $result = $kube->cp_to_pod('Pod', 'nginx',
        namespace  => 'default',
        local      => $local,
        remote     => '/tmp/out.txt',
        chunk_size => 4,
    )->get;

    is($captured->{name}, 'nginx', 'pod name forwarded');
    is($captured->{stdin}, 1, 'stdin enabled');
    is($captured->{stdout}, 0, 'stdout disabled');
    is($captured->{stderr}, 1, 'stderr enabled');
    like(join(' ', @{$captured->{command}}), qr/head -c/, 'uses bounded head command');
    is(join('', @{$session->writes}), $content, 'all local bytes streamed');
    is($result->{bytes}, length($content), 'result bytes matches content size');
};

subtest 'cp_to_pod fails on remote failure status' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);
    my $tmp = tempdir(CLEANUP => 1);
    my $local = File::Spec->catfile($tmp, 'in.txt');
    open my $fh, '>:raw', $local or die $!;
    print {$fh} "x";
    close $fh;

    no warnings 'redefine';
    local *Net::Async::Kubernetes::exec = sub {
        my ($self, $short, $name, %args) = @_;
        my $session = Test::CP::Session->new;
        $self->loop->later(sub {
            $args{on_frame}->(3, '{"status":"Failure","message":"permission denied"}');
            $args{on_close}->();
        });
        return Future->done($session);
    };

    my $f = $kube->cp_to_pod('Pod', 'nginx',
        local  => $local,
        remote => '/root/blocked',
    );
    my $ok = eval { $f->get; 1 };
    ok(!$ok, 'future failed');
    like($@, qr/cp_to_pod failed/i, 'failure message propagated');
};

subtest 'cp_from_pod collects stdout and writes local file' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);
    my $tmp = tempdir(CLEANUP => 1);
    my $local = File::Spec->catfile($tmp, 'download.txt');

    my $captured;
    no warnings 'redefine';
    local *Net::Async::Kubernetes::exec = sub {
        my ($self, $short, $name, %args) = @_;
        $captured = { short => $short, name => $name, %args };
        $self->loop->later(sub {
            $args{on_frame}->(1, "abc");
            $args{on_frame}->(1, "def");
            $args{on_frame}->(2, "warn");
            $args{on_close}->();
        });
        return Future->done(Test::CP::Session->new);
    };

    my $result = $kube->cp_from_pod('Pod', 'nginx',
        namespace => 'default',
        remote    => '/tmp/source.txt',
        local     => $local,
    )->get;

    is($captured->{stdin}, 0, 'stdin disabled');
    is($captured->{stdout}, 1, 'stdout enabled');
    is_deeply($captured->{command}, ['cat', '/tmp/source.txt'], 'cat command used');
    is($result->{bytes}, 6, 'downloaded byte count');
    is($result->{stderr}, 'warn', 'stderr returned in result');

    open my $fh, '<:raw', $local or die $!;
    local $/ = undef;
    my $content = <$fh>;
    close $fh;
    is($content, 'abcdef', 'local file content matches stdout stream');
};

subtest 'cp_from_pod validation' => sub {
    my $loop = IO::Async::Loop->new;
    my $kube = make_kube($loop);

    my $f1 = $kube->cp_from_pod('Pod', remote => '/tmp/x', local => '/tmp/y');
    ok($f1->is_failed, 'name required');
    like($f1->failure, qr/name required for cp_from_pod/, 'name required message');

    my $f2 = $kube->cp_from_pod('Pod', 'nginx', local => '/tmp/y');
    ok($f2->is_failed, 'remote required');
    like($f2->failure, qr/remote path required/, 'remote required message');
};

done_testing;
