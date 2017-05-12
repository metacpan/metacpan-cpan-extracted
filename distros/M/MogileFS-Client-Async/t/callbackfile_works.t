use strict;
use warnings;
use Test::More;
use Test::Exception;
use MogileFS::Client::CallbackFile;
use Digest::SHA1;
use Digest::MD5;
use File::Temp qw/ tempfile /;
use Data::Dumper;

sub sha1 {
    open(FH, '<', shift) or die;
    my $sha = Digest::SHA1->new;
    $sha->addfile(*FH);
    close(FH);
    $sha->hexdigest;
}

my $exp_sha = sha1($0);

my $mogc = MogileFS::Client::CallbackFile->new(
    domain => "state51",
    hosts => [qw/
        tracker0.cissme.com:7001
        tracker1.cissme.com:7001
        tracker2.cissme.com:7001
    /],
);
ok $mogc, 'Have client';

{
    my $key = 'test-t0m-foobar';



    open(my $read_fh, "<", $0) or die "failed to open $0: $!";

    isa_ok($read_fh, 'GLOB');

    my $exp_len = -s $read_fh;
    my $callback = $mogc->store_file_from_fh($key, 'rip', $read_fh, $exp_len, {});

    isa_ok($callback, 'CODE');

    $callback->(0, 0);
    $callback->(1, 0);
    $callback->(2, 0);
    $callback->($exp_len, 0);
    $callback->($exp_len, 1);

    lives_ok {
        my ($fh, $fn) = tempfile;
        $mogc->read_to_file($key, $fn);
        is( -s $fn, $exp_len, 'Read file back with correct length' )
            or system("diff -u $0 $fn");
        is sha1($fn), $exp_sha, 'Read file back with correct SHA1';
        unlink $fn;
    };
}

{
    open(my $read_fh, "<", $0) or die "failed to open $0: $!";
    isa_ok($read_fh, 'GLOB');

    no strict 'refs';
    my $old_cc = \&MogileFS::Backend::do_request;
    local *MogileFS::Backend::do_request = sub {
        if ($_[1] eq 'create_close') {
            my $p = $_[2];
            ok(!exists($p->{checksum}));
            ok(!exists($p->{checksumverify}));

        }
        return $old_cc->(@_);
    };
    use strict;

    my $exp_len = -s $read_fh;
    my $key;
    my $callback = $mogc->store_file_from_fh(sub {
        $key = "test-".int(rand(100000));
    }, 'rip', $read_fh, $exp_len, {});

    isa_ok($callback, 'CODE');
    $callback->($exp_len, 1);

    diag "key finally is $key\n";

    lives_ok {
        my ($fh, $fn) = tempfile;
        $mogc->read_to_file($key, $fn);
        is( -s $fn, $exp_len, 'Read file back with correct length' )
            or system("diff -u $0 $fn");
        is sha1($fn), $exp_sha, 'Read file back with correct SHA1';
        unlink $fn;
    };
}

{
    open(my $read_fh, "<", $0) or die "failed to open $0: $!";

    my $md5 = Digest::MD5->new->addfile($read_fh)->hexdigest();
    seek($read_fh, 0, 0);

    isa_ok($read_fh, 'GLOB');

    no strict 'refs';
    my $old_cc = \&MogileFS::Backend::do_request;

    my $fail = 3;
    local *MogileFS::Backend::do_request = sub {
        if ($_[1] eq 'create_close') {
            die if $fail--;

            my $p = $_[2];
            is($p->{checksum}, "MD5:$md5");
            is($p->{checksumverify}, 1);

        }
        return $old_cc->(@_);
    };

    use strict;


    my $exp_len = -s $read_fh;
    my $key;
    my $keys_requested = 0;


    my $callback = $mogc->store_file_from_fh(sub {
        $keys_requested++;
        $key = "test-".int(rand(100000));
        diag "made key $key";
        return $key;
    }, 'rip', $read_fh, $exp_len, {});

    isa_ok($callback, 'CODE');
    $callback->($exp_len, 1, "MD5:$md5");

    diag "key finally is $key\n";
    is($keys_requested, 4);

    lives_ok {
        my ($fh, $fn) = tempfile;
        $mogc->read_to_file($key, $fn);
        is( -s $fn, $exp_len, 'Read file back with correct length' )
            or system("diff -u $0 $fn");
        is sha1($fn), $exp_sha, 'Read file back with correct SHA1';
        unlink $fn;
    };
}

{
    my $key = "test-store-file";
    my $exp_len = $mogc->store_file($key, "rip", $0);
    diag "length is $exp_len";
    is($exp_len, -s $0);

    lives_ok {
        my ($fh, $fn) = tempfile;
        $mogc->read_to_file($key, $fn);
        is( -s $fn, $exp_len, 'Read file back with correct length' )
            or system("diff -u $0 $fn");
        is sha1($fn), $exp_sha, 'Read file back with correct SHA1';
        unlink $fn;
    };

}

done_testing;

