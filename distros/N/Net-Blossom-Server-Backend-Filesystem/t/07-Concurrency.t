use strictures 2;

use Config;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use POSIX qw(_exit);
use Test::More;

use lib "$FindBin::Bin/../lib";
use Net::Blossom::Server::Backend::Filesystem::BlobStore;

plan skip_all => 'fork is required for the concurrency test'
    unless $Config{d_fork};

my $root = tempdir(CLEANUP => 1);
my $store = Net::Blossom::Server::Backend::Filesystem::BlobStore->new(
    root       => $root,
    generation => sub { 'same' },
);
$store->deploy_schema;

pipe my $ready_r, my $ready_w or die "Unable to create ready pipe: $!";
pipe my $go_r, my $go_w or die "Unable to create start pipe: $!";

my @children;
for my $id (1, 2) {
    my $pid = fork;
    die "Unable to fork: $!" unless defined $pid;
    if (!$pid) {
        close $ready_r;
        close $go_w;
        my $body = $id == 1 ? 'first' : 'other';
        my $upload = $store->begin_upload;
        $upload->write($body);
        syswrite $ready_w, 'R' or _exit(2);
        my $go = '';
        sysread $go_r, $go, 1 or _exit(3);

        my $ok = eval {
            $upload->prepare(
                sha256 => 'c' x 64,
                size => length($body),
                type => 'text/plain',
                uploaded => $id,
            );
            $upload->commit;
            1;
        };
        $upload->abort unless $ok;
        my $result = File::Spec->catfile($root, "result-$id");
        open my $fh, '>', $result or _exit(4);
        print {$fh} $ok ? "ok\n" : $@;
        close $fh or _exit(5);
        _exit(0);
    }
    push @children, $pid;
}

close $ready_w;
close $go_r;
local $SIG{ALRM} = sub { die "concurrent publication test timed out\n" };
alarm 15;
my $ready = '';
while (length($ready) < 2) {
    my $read = sysread $ready_r, $ready, 2 - length($ready), length($ready);
    die "Unable to read ready pipe: $!" unless defined $read;
    die "Writer closed the ready pipe early\n" unless $read;
}
is($ready, 'RR', 'both writers stage bytes before publication');
is(syswrite($go_w, 'GG'), 2, 'both writers are released together');
close $go_w;
close $ready_r;

for my $pid (@children) {
    waitpid $pid, 0;
    is($?, 0, "writer process $pid exits successfully");
}

my @result = map { _read_file(File::Spec->catfile($root, "result-$_")) } 1, 2;
is(scalar(grep { $_ eq "ok\n" } @result), 1,
    'exactly one concurrent publisher succeeds');
is(scalar(grep { /already exists/ } @result), 1,
    'the losing publisher receives a collision error');

my $key = 'cc/cc/' . ('c' x 64) . '-same';
my $body = _read_file(File::Spec->catfile($root, 'blobs', split m{/}, $key));
ok($body eq 'first' || $body eq 'other',
    'the published file contains one complete writer body');
alarm 0;

done_testing;

sub _read_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $body = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return $body;
}
