use strict;
use warnings;
use Test::More;
use Test::Exception;
use MogileFS::Client::Async;
use Digest::SHA1;
use File::Temp qw/ tempfile /;

sub sha1 {
    open(FH, '<', shift) or die;
    my $sha = Digest::SHA1->new;
    $sha->addfile(*FH);
    close(FH);
    $sha->hexdigest;
}

my $exp_sha = sha1($0);

my $mogc = MogileFS::Client::Async->new(
    domain => "state51",
    hosts => [qw/
        tracker0.cissme.com:7001
        tracker1.cissme.com:7001
        tracker2.cissme.com:7001
    /],
);
ok $mogc, 'Have client';

my $key = 'test-t0m-foobar';

my $exp_len = -s $0;
lives_ok {
    is $mogc->store_file($key, 'rip', $0), $exp_len,
        'Stored file of expected length';
};

lives_ok {
    my ($fh, $fn) = tempfile;
    $mogc->read_to_file($key, $fn);
    is( -s $fn, $exp_len, 'Read file back with correct length' )
        or system("diff -u $0 $fn");
    is sha1($fn), $exp_sha, 'Read file back with correct SHA1';
    unlink $fn;
};

done_testing;

