#!perl -w
use strict;
use URI::Escape qw(uri_unescape);
use Errno qw(ENOENT EPERM);
use Plack::Request;

our $VERSION = '0.05';

sub _request_error {
    my($errno, @msg) = @_;
    my $status =
          $errno == ENOENT ? 404  # not found
        : $errno == EPERM  ? 403  # permission denied
        :                    400; # something wrong

    return [
        $status,
        [ 'Content-Type' => 'text/plain' ],
        \@msg,
    ];
}

sub main {
    my($env) = @_;
    my $req  = Plack::Request->new($env);
    my $res  = $req->new_response(
        200,
        ['Content-Type' => 'text/plain; charset=utf8'],
    );

    if($req->param('version')) {
        $res->body("cat.psgi version $VERSION ($0)\n");
    }
    elsif($req->param('help')) {
        $res->body("cat.psgi [--version] [--help] files...\n");
    }
    else {
        my @files = grep { length } split '/', $req->path_info;

        local $/;

        my @contents;
        if(@files) {
            foreach my $file(@files) {
                my $f = uri_unescape($file);
                open my $fh, '<', $f
                    or return _request_error($!, "Cannot open '$f': $!\n");

                push @contents, readline($fh);
            }
        }
        else {
            push @contents, readline($env->{'psgi.input'});
        }
        $res->body(\@contents);
    }

    return $res->finalize();
}

if(caller) {
    return \&main;
}
else {
    require Plack::Handler::CLI;
    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main, \@ARGV);
}
