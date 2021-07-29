use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

catch_run('[header]');

subtest 'single header' => sub {
    my $msg = new Protocol::HTTP::Request();
    
    is $msg->headers_size, 0;
    is $msg->header("a"), undef;

    $msg->header("a", "1");
    is $msg->header("a"), 1;
    is $msg->headers_size, 1;

    $msg->header("b", "2");
    is $msg->header("b"), 2;
    is $msg->headers_size, 2;
    
    $msg->header("b", undef);
    is $msg->headers_size, 1;
    is $msg->header("b"), undef;
};

subtest 'multi header' => sub {
    my $msg = new Protocol::HTTP::Request();
    
    is_deeply [$msg->multiheader("a")], [];
    
    $msg->multiheader("a", 1);
    is $msg->headers_size, 1;
    is_deeply [$msg->multiheader("a")], [1];

    $msg->multiheader("a", 2);
    is $msg->headers_size, 2;
    is_deeply [$msg->multiheader("a")], [1,2];
    
    $msg->multiheader("a", 3, 4);
    is $msg->headers_size, 4;
    is_deeply [$msg->multiheader("a")], [1,2,3,4];
    
    $msg->header("a", undef);
    is $msg->headers_size, 0;
    is_deeply [$msg->multiheader("a")], [];
    
    $msg->multiheader("a", 3, 4);
    $msg->multiheader("a", undef);
    is $msg->headers_size, 2;
    is_deeply [$msg->multiheader("a")], [3,4];    
};

subtest 'objects should stringify in header values' => sub {
    my $msg = new Protocol::HTTP::Request({
        headers => { Location => URI::XS->new("https://example.com") }
    });
    is $msg->header("Location"), "https://example.com";
    
    $msg->headers({ Hello => URI::XS->new("/world") });
    is $msg->header("Hello"), "/world";
    
    $msg->header("Key", URI::XS->new("/world"));
    is $msg->header("Key"), "/world";
};

done_testing();