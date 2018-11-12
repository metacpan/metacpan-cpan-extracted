#!perl
#
# This script tests whether submited data looks good

use strict;
use warnings;

use Test::More;

use IO::File;
use IO::Pipe;
use RT::Client::REST;
use File::Spec::Functions;
use Encode;
use HTTP::Response;
use HTTP::Server::Simple;

# this file, has more than one line but no endline on the last line
my $testfile = 'nonewline.txt';
my $testfile_path = catfile('t' => 'data' => $testfile);

my $testfile_content = do {
    my $fh = IO::File->new($testfile_path)
        or die "Couldn't open $testfile_path $!";
    local $/;
    <$fh>;
};

my ($reply_header, $reply_body) = do {
    my $binary_string = $testfile_content;
    my $length = length($binary_string);
    my $spaces = ' ' x length('Content: ');
    $binary_string =~ s/\n/\n$spaces/sg;
    my $body = <<"EOF";
id: 873
Subject: spaces.txt
Creator: 322136
Created: 2018-11-10 05:23:01
Transaction: 1818943
Parent: 130
MessageId: \nFilename: spaces.txt
ContentType: text/plain
ContentEncoding: none

Headers: MIME-Version: 1.0
         Subject: spaces.txt
         X-Mailer: MIME-tools 5.504 (Entity 5.504)
         Content-Type: text/plain; charset="utf-8"; name="spaces.txt"
         Content-Disposition: inline; filename="spaces.txt"
         Content-Transfer-Encoding: binary
         X-RT-Original-Encoding: utf-8
         Content-Length: $length

Content: $binary_string
EOF
    ('RT/4.0.7 200 Ok', $body);
};

my $http_payload =
    $reply_header                                       .
    "\n\n"                                              .
    $reply_body                                         .
    "\n\n"                                              ;

my $http_reply =
    "HTTP/1.1 200 OK\r\n"                               .
    "Content-Type: text/plain; charset=utf-8\r\n\r\n"   .
    $http_payload                                       ;

my $pipe = IO::Pipe->new;                           # Used to get port number
my $pid = fork;
die "cannot fork: $!" if not defined $pid;

if (0 == $pid) {                                    # Child
    $pipe->writer;
    {
        package My::Web::Server;
        use base qw(HTTP::Server::Simple::CGI);
        sub handle_request {
            print $http_reply;
        }
        # A hack to get HTTP::Server::Simple listen on ephemeral port.
        # See RT#72987
        sub after_setup_listener {
            use Socket;
            my $sock = getsockname HTTP::Server::Simple::HTTPDaemon;
            my ($port) = (sockaddr_in($sock))[0];
            $pipe->print("$port\n");
            $pipe->close;
        }
    }
    my $server = My::Web::Server->new('00');
    alarm 120;                                      # Just in case, don't hang people
    $server->run;                                   # Run until killed
    die 'unreachable code';
}

$pipe->reader;
chomp(my $port = <$pipe>);
#diag("set up web server on port $port");
$pipe->close;

unless ($port && $port =~ /^\d+$/) {
    kill 9, $pid;
    waitpid $pid, 0;
    plan skip_all => 'could not get port number from child, skipping all tests';
}

plan tests => 3;

{
    my $res = HTTP::Response->parse( $http_reply );
    ok($res->content eq $http_payload,
        'self-test: HTTP::Response gives back correct payload');
}

my $rt = RT::Client::REST->new(
    server => "http://127.0.0.1:$port",
    timeout => 2,
);

# avoid need to login
$rt->basic_auth_cb(sub { return });

{
    my $res = $rt->get_attachment(parent_id => 130, id => 873, undecoded => 1);
    ok($res->{Content} eq $testfile_content, 'files match with undecoded option');
}
{
    my $res = $rt->get_attachment(parent_id => 130, id => 873, undecoded => 0);
    ok($res->{Content} eq $testfile_content, 'files match w/o undecoded option');
}

kill 9, $pid;
waitpid $pid, 0;
exit;
