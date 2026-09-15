#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Path 'make_path';
use File::Spec;
use File::Temp;

use FindBin '$Bin';
use lib File::Spec->catfile($Bin, '..', 'lib');

use Sys::Path;
use Sys::Path::SPc;

my $tmp_dir = File::Temp->newdir();
my $localstatedir = File::Spec->catdir($tmp_dir, 'var');
my $sharedstatedir = File::Spec->catdir($localstatedir, 'lib');
my $registry_dir = File::Spec->catdir($sharedstatedir, 'syspath');
make_path($registry_dir);
Sys::Path::SPc->localstatedir($localstatedir);

my $worker_count = 12;
pipe(my $ready_reader, my $ready_writer) or die "pipe failed: $!";
pipe(my $start_reader, my $start_writer) or die "pipe failed: $!";
my @children;

for my $worker (1 .. $worker_count) {
    my $pid = fork();
    die "fork failed: $!" if not defined $pid;
    if ($pid == 0) {
        close $ready_reader;
        close $start_writer;
        syswrite($ready_writer, '.', 1) == 1
            or die "ready signal failed: $!";
        sysread($start_reader, my $signal, 1) == 1
            or die "start signal failed: $!";
        Sys::Path->install_checksums(
            "worker-$worker" => "checksum-$worker",
        );
        exit 0;
    }
    push @children, $pid;
}

close $ready_writer;
close $start_reader;
my $ready = '';
while (length($ready) < $worker_count) {
    my $bytes_read = read(
        $ready_reader,
        $ready,
        $worker_count - length($ready),
        length($ready),
    );
    die "failed to synchronize workers: $!"
        if not defined($bytes_read) or $bytes_read == 0;
}
syswrite($start_writer, 'x' x $worker_count, $worker_count) == $worker_count
    or die "failed to release workers: $!";
close $start_writer;

my $children_ok = 1;
for my $pid (@children) {
    waitpid($pid, 0);
    $children_ok &&= ($? == 0);
}
ok($children_ok, 'concurrent checksum writers exit successfully');

my %checksums = Sys::Path->install_checksums;
is_deeply(
    \%checksums,
    { map { ("worker-$_" => "checksum-$_") } 1 .. $worker_count },
    'concurrent disjoint checksum updates are all retained',
);

my $registry_file = File::Spec->catfile(
    $registry_dir,
    'install-checksums.json',
);
ok(-f $registry_file.'.lock', 'checksum updates use a stable lock file');

my ($reader_writer, $reader_writer_gate) = start_paused_writer({
    'during-update' => 'complete',
});
pipe(my $reader_ready, my $reader_signal) or die "pipe failed: $!";
my $reader = fork();
die "fork failed: $!" if not defined $reader;
if ($reader == 0) {
    close $reader_ready;
    syswrite($reader_signal, '.', 1) == 1
        or die "reader signal failed: $!";
    my %during_update = Sys::Path->install_checksums;
    exit($during_update{'during-update'} eq 'complete' ? 0 : 1);
}
close $reader_signal;
sysread($reader_ready, my $reader_started, 1) == 1
    or die "reader did not start: $!";
syswrite($reader_writer_gate, '.', 1) == 1
    or die "failed to release writer: $!";
close $reader_writer_gate;
waitpid($reader_writer, 0);
is($?, 0, 'writer observed by a concurrent reader exits successfully');
waitpid($reader, 0);
is($?, 0, 'a reader waits for an active update and reads complete JSON');

Sys::Path->install_checksums('stable' => 'before-interruption');
my ($interrupted_writer, $interrupted_writer_gate) = start_paused_writer({
    'interrupted' => 'must-not-replace-live-registry',
});
kill 'KILL', $interrupted_writer;
close $interrupted_writer_gate;
waitpid($interrupted_writer, 0);
my %after_interruption = Sys::Path->install_checksums;
is(
    $after_interruption{'stable'},
    'before-interruption',
    'an interrupted publication leaves the previous registry readable',
);

done_testing();

sub start_paused_writer {
    my ($update) = @_;
    pipe(my $ready_reader, my $ready_writer) or die "pipe failed: $!";
    pipe(my $gate_reader, my $gate_writer) or die "pipe failed: $!";
    my $pid = fork();
    die "fork failed: $!" if not defined $pid;
    if ($pid == 0) {
        close $ready_reader;
        close $gate_writer;
        my $original_open = \&IO::AtomicFile::open;
        no warnings 'redefine';
        local *IO::AtomicFile::open = sub {
            my $fh = $original_open->(@_);
            syswrite($ready_writer, '.', 1) == 1
                or die "writer signal failed: $!";
            sysread($gate_reader, my $release, 1) == 1
                or die "writer release failed: $!";
            return $fh;
        };
        Sys::Path->install_checksums(%{$update});
        exit 0;
    }
    close $ready_writer;
    close $gate_reader;
    sysread($ready_reader, my $ready, 1) == 1
        or die "writer did not pause during atomic publication: $!";
    close $ready_reader;
    return ($pid, $gate_writer);
}
