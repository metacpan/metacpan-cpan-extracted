# -*- perl -*-

use strict;
use warnings;
use Test::More;
use HTTP::Request;

use Net::Amazon::SignatureVersion4;
my $sig=new Net::Amazon::SignatureVersion4();

my $test_suite_location="t/aws4_testsuite";

my $testsuite; #Dirhandle for testsuite.

if ( ! opendir($testsuite, $test_suite_location)){
    BAIL_OUT("Can't open testsuite directory");
    exit(1);
}

my @tests=readdir $testsuite;
while(my $_=pop @tests) {
    next unless ($_=~m/(.*)\.req/);
    my $test=$1;
#    diag "Test: $test\n";
    use File::Slurp;
    my $request = read_file("$test_suite_location/$test.req");
    my $hr = HTTP::Request->parse( $request );
    $sig->set_request($hr);
    $sig->set_region('us-east-1');
    $sig->set_service('host');
    $sig->set_Access_Key_ID('AKIDEXAMPLE');
    $sig->set_Secret_Access_Key('wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY');
    my $canonical_request_actual=$sig->get_canonical_request();
    write_file("$test_suite_location/$test.me", $canonical_request_actual);
    #diag($canonical_request_actual);
    my $canonical_request_correct=read_file("$test_suite_location/$test.creq");
    #diag($canonical_request_correct);
    ok($canonical_request_actual eq $canonical_request_correct, "$test Canonical Request" );
    my $string_to_sign_actual=$sig->get_string_to_sign();
    write_file("$test_suite_location/$test.sts.me", $string_to_sign_actual);
#    diag($string_to_sign_actual);
    my $string_to_sign_correct=read_file("$test_suite_location/$test.sts");
    ok($string_to_sign_actual eq $string_to_sign_correct, "$test String to Sign");
    my $authorization_actual=$sig->get_authorization();
    write_file("$test_suite_location/$test.authz.me", $authorization_actual);
#    diag($authorization_actual);
    my $authorization_correct=read_file("$test_suite_location/$test.authz");
    ok($authorization_actual eq $authorization_correct, "$test Authorization");
    my $authorized_request_actual=$sig->get_authorized_request()->as_string();
    write_file("$test_suite_location/$test.sreq.me", $authorized_request_actual);
#    diag($authorized_request_actual);
    my $ar_string=read_file("$test_suite_location/$test.sreq");
    my $authorized_request_correct=HTTP::Request->parse($ar_string);
    my @symmetric_difference=get_symmetric_difference($authorized_request_actual,$authorized_request_correct->as_string());
    foreach my $diff (@symmetric_difference){
	diag("DIFF: $diff");
    }
    ok($#symmetric_difference == -1, "$test Signed Request");
}
closedir $testsuite;

done_testing();

sub get_symmetric_difference{
    my $a=shift;
    my $b=shift;
    my @a=split /\n/, $a;
    my @b=split /\n/, $b;
    use List::Compare;
    my $lc = List::Compare->new(\@a, \@b);
    return $lc->get_symmetric_difference();
}
