use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use Mojo::File qw(path);
use Time::HiRes qw(sleep);
use lib 'lib';
use Mogura::Scanner::Config;
my $dir = tempdir(CLEANUP => 1);
use Mogura::Scanner;
my $config = Mogura::Scanner::Config->new(state => $dir, runtime => "$dir/run");
path($config->runtime)->make_path;

# A surviving exec child must keep a second scanner out after its parent
# closes the lock; releasing only the parent's descriptor is insufficient.
{
    my $first = Mogura::Scanner->new(config => $config);
    my $second = Mogura::Scanner->new(config => $config);
    $first->acquire_lock;
    eval { $second->acquire_lock };
    like($@, qr/already running/, 'A second scanner cannot acquire the disk-operation lock');
    my $ready = "$dir/child.ready";
    my $child = fork;
    die "fork: $!" unless defined $child;

    if (!$child) {
        my $program = <<'PERL';
open my $ready_file, '>', $ARGV[0] or die $!;
close $ready_file;
sleep 30;
PERL
        exec $^X, '-e', $program, $ready;
        die "exec: $!";
    }
    for (1 .. 200) {
        last if -f $ready;
        sleep 0.01;
    }
    ok(-f $ready, 'External child started');
    close delete $first->{lock};
    eval { $second->acquire_lock };
    like(
        $@,
        qr/already running/,
        'An exec child holds the lock after the scanner descriptor closes'
    );
    kill 'TERM', $child;
    waitpid $child, 0;
    ok(eval { $second->acquire_lock; 1 }, 'Lock releases only after the surviving child exits');
}
ok(!grep(m{^Mogura/Server}, keys %INC), 'Scanner runs without loading server modules');
done_testing;
