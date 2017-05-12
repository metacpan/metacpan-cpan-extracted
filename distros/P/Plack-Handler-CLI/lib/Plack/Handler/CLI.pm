package Plack::Handler::CLI;
use 5.008_001;
use Mouse;

our $VERSION = '0.05';

use IO::Handle  (); # autoflush
use Plack::Util ();
use URI ();

use constant {
    _RES_STATUS  => 0,
    _RES_HEADERS => 1,
    _RES_BODY    => 2,
};

BEGIN {
    if(eval { require URI::Escape::XS }) {
        *_uri_escape = \&URI::Escape::XS::encodeURIComponent;
    }
    else {
        require URI::Escape;
        *_uri_escape = \&URI::Escape::uri_escape_utf8;
    }
}

my $CRLF = "\015\012";

has need_headers => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has stdin => (
    is      => 'ro',
    isa     => 'FileHandle',
    default => sub { \*STDIN },
);

has stdout => (
    is      => 'ro',
    isa     => 'FileHandle',
    default => sub { \*STDOUT },
);

has stderr => (
    is      => 'ro',
    isa     => 'FileHandle',
    default => sub { \*STDERR },
);

sub run {
    my($self, $app, $argv_ref) = @_;

    my @argv;
    if($argv_ref) {
        @argv = @{$argv_ref};
    }
    else {
        # skip after *.psgi
        @argv = @ARGV;
        if(grep { /\.psgi \z/xms } @argv) {
            while(@argv) {
                my $a = shift @argv;
                last if $a =~ /\.psgi \z/xms;
            }
        }
    }

    my @params;
    while(defined(my $s = shift @argv)) {
        if($s =~ s/\A -- //xms) {
            my($name, $value) = split /=/, $s, 2;
            if(not defined $value) {
                $value = @argv
                    ? shift(@argv)
                    : Plack::Util::TRUE;
            }
            push @params, $name, $value;
        }
        else {
            unshift @argv, $s; # push back
            last;
        }
    }

    my $uri = URI->new();
    if ( @argv &&  $argv[0] =~ m{\Ahttp} ) {
    	$uri = URI->new(shift @argv);
    }

    $uri->scheme('http') if not $uri->scheme;
    $uri->host('localhost') if not $uri->host;
    $uri->path_segments($uri->path_segments, @argv);
    $uri->query_form($uri->query_form, @params);

    my %env = (
        # HTTP
        HTTP_USER_AGENT => sprintf('%s/%s', ref($self), $self->VERSION),

        HTTP_COOKIE  => '', # TODO?
        HTTP_HOST    => $uri->host,

        # Client
        REQUEST_METHOD => 'GET',
        REQUEST_URI    => $uri,
        QUERY_STRING   => $uri->query,
        PATH_INFO      => $uri->path || '/',
        SCRIPT_NAME    => '',
        REMOTE_ADDR    => '0.0.0.0',
        REMOTE_USER    => $ENV{USER},

        # Server
        SERVER_PROTOCOL => 'HTTP/1.0',
        SERVER_PORT     => 0,
        SERVER_NAME     => 'localhost',
        SERVER_SOFTWARE => ref($self),

        # PSGI
        'psgi.version'      => [1,1],
        'psgi.url_scheme'   => $uri->scheme,
        'psgi.input'        => $self->stdin,
        'psgi.errors'       => $self->stderr,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::TRUE,
        'psgi.streaming'    => Plack::Util::FALSE,
        'psgi.nonblocking'  => Plack::Util::FALSE,

        %ENV, # override
    );
    $env{SCRIPT_NAME} = '' if $env{SCRIPT_NAME} eq '/';

    my $res = Plack::Util::run_app($app, \%env);

    if (ref $res eq 'ARRAY') {
        $self->_handle_response($res);
    }
    elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($_[0]);
        });
    }
    else {
        die "Bad response $res";
    }
}

sub _handle_response {
    my ($self, $res) = @_;

    my $stdout = $self->stdout;

    $stdout->autoflush(1);

    if($self->need_headers) {
        my $hdrs = "Status: $res->[_RES_STATUS]" . $CRLF;

        $hdrs .= "Server: " . ref($self) . $CRLF;

        my $headers = $res->[_RES_HEADERS];
        while (my ($k, $v) = splice @$headers, 0, 2) {
            $hdrs .= "$k: $v" . $CRLF;
        }
        $hdrs .= $CRLF;

        print $stdout $hdrs;
    }

    my $body = $res->[_RES_BODY];
    my $cb   = sub { print $stdout @_ };
    Plack::Util::foreach($body, $cb);
    return;
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Plack::Handler::CLI - Command line interface to PSGI applications

=head1 VERSION

This document describes Plack::Handler::CLI version 0.05.

=head1 SYNOPSIS

    #!perl -w
    # a cat(1) implementation on PSGI/CLI
    use strict;
    use Plack::Handler::CLI;
    use URI::Escape qw(uri_unescape);

    sub err {
        my(@msg) = @_;
        return [
            500,
            [ 'Content-Type' => 'text/plain' ],
            \@msg,
        ];
    }

    sub main {
        my($env) = @_;

        my @files = split '/', $env->{PATH_INFO};

        local $/;

        my @contents;
        if(@files) {
            foreach my $file(@files) {
                my $f = uri_unescape($file);
                open my $fh, '<', $f
                    or return err("Cannot open '$f': $!\n");

                push @contents, readline($fh);
            }
        }
        else {
            push @contents, readline($env->{'psgi.input'});
        }

        return [
            200,
            [ 'Content-Type' => 'text/plain'],
            \@contents,
        ];
    }

    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main);

=head1 DESCRIPTION

Plack::Handler::CLI is a PSGI handler which provides a command line interface
for PSGI applications.

=head1 INTERFACE

=head2 C<< Plack::Handler::CLI->new(%options) >>

Creates a Plack handler that implements a command line interface.

PSGI headers will be printed by default, but you can suppress them
by C<< need_headers => 0 >>.

=head2 C<< $cli->run(\&psgi_app, @argv) : Void >>

Runs I<&psgi_app> with I<@argv>.

C<< "--key" => "value" >> (or C<< "--key=value" >>) pairs in I<@argv>
are packed into C<QUERY_STRING>, while any other arguments are packed
into C<PATH_INFO>, so I<&psgi_app> can get command line arguments as
PSGI parameters. The first element of I<@argv> after the query parameters
could also be a absolute URL.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<PSGI>

L<Plack>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
