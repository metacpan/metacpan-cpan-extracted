use v5.10;
use Test::More;
use Digest::MD5 qw(md5_hex);
use HTTP::Date;
use Data::Dumper;

use_ok('Net::UpYun');

my $test_bucket = 'xxxx';
my $test_account = 'xxxx';
my $test_password = 'xxxx';

my $upyun = Net::UpYun->new(
    bucket => $test_bucket,
    bucket_account => $test_account,
    bucket_password => $test_password,
    );
{
    my $date = time2str(time);
    my $sign = md5_hex('GET&/demobucket/&'.$date.'&0&'.md5_hex($test_password));
    is($upyun->sign('GET','/demobucket/',0),'UpYun '.$test_account.':'.$sign,'sign');
}

# live test
SKIP: {
    ($test_bucket,$test_account,$test_password) = 
        @ENV{qw(UPYUN_TEST_BUCKET UPYUN_TEST_BUCKET_ACCOUNT UPYUN_TEST_BUCKET_PASSWORD)};
    unless ($test_bucket && $test_account && $test_password) {
        diag('setup ENV{qw(UPYUN_TEST_BUCKET UPYUN_TEST_BUCKET_ACCOUNT UPYUN_TEST_BUCKET_PASSWORD)} to run live test.');
        skip 'live test',1;
    }
    $upyun->use_bucket($test_bucket,$test_account,$test_password);
    {
        my $res = $upyun->do_request('/p5test/?usage','GET');
        ok($res->is_success,'do_request');
        # diag($res->content);
    }
    my $usage = $upyun->usage;
    ok($upyun->is_success,'usage');
    diag('usage is '.$usage);
    my $ok;
    $ok = $upyun->mkdir('/demo');
    ok($ok,'mkdir');
    $ok = $upyun->rmdir('/demo');
    ok($ok,'rmdir');

    # build subdir
    $upyun->mkdir('/demo');
    $ok = $upyun->mkdir('/demo/child');
    ok($ok,'mkdir/build path tree');
    # rm dir
    $ok = $upyun->rmdir('/demo');
    ok(!$ok,'rmdir/dir must be empty');
    $upyun->rmdir('/demo/child');
    # upload bytes
    my $bytes = '123456';
    $ok = $upyun->put('/demo/test.txt',$bytes);
    ok($ok,'put/bytes');
    # get
    my $get_s = $upyun->get('/demo/test.txt');
    ok($upyun->is_success,'get/success');
    is($get_s,$bytes,'get file');

    $upyun->list('/demo');

    # delete file
    $ok = $upyun->delete('/demo/test.txt');
    ok($ok,'delete file');

    $upyun->get('/demo/test.txt');
    is($upyun->error_code,'404','deleted file check');
}

done_testing;
