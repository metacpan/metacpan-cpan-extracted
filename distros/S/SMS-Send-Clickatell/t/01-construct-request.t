#!perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::MockObject;

BEGIN {
	use_ok( 'SMS::Send' );
}

my $send = SMS::Send->new( 'Clickatell',
    _api_id => "999999",
    _user => "someone",
    _password => "secret",
 );

isa_ok($send,'SMS::Send');

# Let's not send any real SMS!
my $mock_ua = Test::MockObject->new;

my (@requests,@mock_responses);

$mock_ua->mock( 
    request => sub {
	shift;
	push @requests => shift;
	shift @mock_responses or die;
    } );


{
    # Ugly but we need to mung the User Agent inside the driver inside the
    # object
    my $driver = $send->{OBJECT};

    isa_ok($driver,'SMS::Send::Clickatell');
    $driver->{ua} = $mock_ua;
}

my @message = (
    text => 'Hi there',
    # From Ofcom's Telephone Numbers for drama purposes (TV, Radio etc)
    to   => '+447700900999',
    );   

my %expected_content = ( 
 'password' => 'secret',
 'to' => '447700900999',
 'api_id' => '999999',
 'text' => 'Hi+there',
 'user' => 'someone',
 'concat' => '3'
    );

sub check_request {
    my ($case,$expect_ok,$stati) = @_;
    @mock_responses = map { HTTP::Response->new($_) } @$stati;
    @requests = ();
    # use Data::Dumper; print Dumper \@mock_responses;
    is(!!$send->send_sms(@message), !!$expect_ok, "send_sms() status $case");
    my %content = $requests[-1]->content =~ /\G(.*?)=(.*?)(?:&|$)/g;
    is_deeply(\%content,\%expected_content, "request content $case")
	if %expected_content;
    ok(!@mock_responses,"number of requests $case");
}

check_request("without from",1,[200]);

push @message => ( _from => ($expected_content{from} = 'sender'));

check_request("with from",1,[200]);

undef %expected_content;

check_request("404 error",0,[404]);
check_request("single 502 error",1,[502,200]);
check_request("double 502 error",0,[502,502]);

# For reasons I don't understand leaving the SMS::Send to the global
# destruction causes problems under the test harness but not if this
# test is run directly.

undef $send;

diag( "Testing SMS::Send::Clickatell $SMS::Send::Clickatell::VERSION, Perl $], $^X" );
