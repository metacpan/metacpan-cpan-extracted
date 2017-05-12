#!/usr/bin/perl
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

my $testfile = "test.png";
my $testfile_path = catfile(t => $testfile);

my $testfile_content = do {
    my $fh = IO::File->new($testfile_path)
	or die "Couldn't open $testfile_path $!";
    local $/;
    <$fh>;
};

my ($reply_header, $reply_body) = do {
    my $binary_string = $testfile_content;
    my $length = length($binary_string);
    $binary_string =~ s/\n/\n         /sg;
    my $body = <<"EOF";
id: 873
Subject: 
Creator: 12
Created: 2013-11-06 07:15:36
Transaction: 1457
Parent: 871
MessageId: 
Filename: prova2.png
ContentType: image/png
ContentEncoding: base64

Headers: Content-Type: image/png; name="prova2.png"
         Content-Disposition: attachment; filename="prova2.png"
         Content-Transfer-Encoding: base64
         Content-Length: $length

Content: $binary_string
EOF
    ("RT/4.0.7 200 Ok", $body);
};

my $http_payload = 
    $reply_header                                       .
    "\n\n"                                              .
    $reply_body                                         .
    "\n\n"						;

my $http_reply =
    "HTTP/1.1 200 OK\r\n"                               .
    "Content-Type: text/plain; charset=utf-8\r\n\r\n"	.
    $http_payload					;

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
    $server->run;		                    # Run until killed
    die "unreachable code";
}

$pipe->reader;
chomp(my $port = <$pipe>);
#diag("set up web server on port $port");
$pipe->close;

unless ($port && $port =~ /^\d+$/) {
    kill 9, $pid;
    waitpid $pid, 0;
    plan skip_all => "could not get port number from child, skipping all tests";
}

plan tests => 4;

{
    my $res = HTTP::Response->parse( $http_reply );
    ok($res->content eq $http_payload,
        "self-test: HTTP::Response gives back correct payload");
}

my $rt = RT::Client::REST->new(
    server => "http://localhost:$port",
    timeout => 2,
);

# avoid need ot login
$rt->basic_auth_cb(sub { return });

{
    my $res = $rt->get_attachment(parent_id => 130, id => 873, undecoded => 1);
    ok($res->{Content} eq $testfile_content, "binary files match with undecoded option");
}

{
    my $res = $rt->get_attachment(parent_id => 130, id => 873, undecoded => 0);
    ok($res->{Content} ne encode("latin1", $testfile_content),
        "binary files don't match when decoded to latin1");
    ok($res->{Content} ne encode("utf-8", $testfile_content),
        "binary files don't match when decoded to utf8");
}

kill 9, $pid;
waitpid $pid, 0;
exit;
