use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Test::CGI::External;

# Now start the tests.


my $tester = Test::CGI::External->new ();
$tester->set_verbosity (1);
$tester->set_cgi_executable ("$Bin/test.cgi", '--gzip');
$tester->do_compression_test (1);
$tester->expect_charset ('utf-8');

my %options;

$options{REQUEST_METHOD} = 'GET';
$tester->run (\%options);

$options{REQUEST_METHOD} = 'HEAD';
$tester->run (\%options);

$options{REQUEST_METHOD} = 'POST';
$options{input} = 'hallo baby.';
$tester->run (\%options);

$options{mime_type} = 'text/html';
$tester->run (\%options);

{
    # Check the warnings from the test_status method.
    my $warning;
    local $SIG{__WARN__} = sub { 
	($warning) = @_;
    };
    my $t2 = Test::CGI::External->new ();
    $t2->test_status (101);
    like ($warning, qr/no headers in this object/);
    $t2->test_status ("300 Funny Business");
    like ($warning, qr/not a valid HTTP status/);
}

done_testing ();
