use Test::SMTP;
use Test::More;

use Net::Server::Mail::ESMTP;

my $messages = [
   { 'ok' => 1,
     'desc' => 'Little message',
     'data' => [ "Test Message\n" ]
   },
   { 'ok' => 0,
     'desc' => '2 70 char lines', 
     'data' => [ map { '.' x 68 . "\n" } (1..2) ]
   },
   { 'ok' => 1,
     'desc' => '10 .. lines', 
     'data' => [ map { '.' . "\n" } (1..10) ]
   },
];

plan tests => scalar(@$messages) * 5;

my $server_port = 2525;
my $server;

while(not defined $server && $server_port < 4000)
{
    $server = new IO::Socket::INET
    (
        Listen      => 1,
        LocalPort   => ++$server_port,
    );
}

my $pid = fork;
if(!$pid)
{
    while(my $conn = $server->accept)
    {
        my $m = new Net::Server::Mail::ESMTP socket => $conn, idle_timeout => 5
            or die "can't start server on port $server_port";
        $m->register('Net::Server::Mail::ESMTP::SIZE');
	$m->set_size(30);
        $m->process;
    }
}


foreach $test (@$messages){
    my $smtp = Test::SMTP->connect_ok("Connect to server on $server_port for $test->{'desc'}", 
                                      Host => 'localhost', 
                                      Port => $server_port,
                                      AutoHello => 1,
                                      Debug => 0 
				      );
    $smtp->supports_cmp_ok('SIZE', '==', 30);
    my $rcpt = "<test\@domain.com> SIZE=" . message_length($test->{'data'});
    if ($test->{'ok'} == 1){
        $smtp->mail_from_ok($rcpt);
    } else {
        $smtp->mail_from_ko($rcpt);
    }
    $smtp->rcpt_to('postmaster');
    $smtp->data_ok();
    $smtp->datasend($test->{'data'});
    if ($test->{'ok'} == 1){
        $smtp->dataend_ok($test->{'desc'});
    } else {
        $smtp->dataend_ko($test->{'desc'});
    }
    $smtp->quit();
}

sub message_length {
     my ($message) = @_;
     my $length = 0;
     # count the length of each line + 1 (
     # Net::SMTP converts \n to \r\n
     map { $length += length($_) + 1  } @$message;
     return $length;
}

kill 1, $pid;
wait;

