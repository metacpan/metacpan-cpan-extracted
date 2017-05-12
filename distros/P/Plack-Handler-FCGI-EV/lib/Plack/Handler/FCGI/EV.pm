package Plack::Handler::FCGI::EV;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.01';

use Socket;
use Fcntl;
use Plack::Util;
use EV;
use FCGI::EV;
use AnyEvent;

sub new {
    my ( $class, %args ) = @_;
    bless { %args }, $class;
}

sub register_service {
    my($self, $app) = @_;

    my $listen = $self->{listen}[0]
        or die "FCGI daemon host/port or socket is not specified\n";

    my $sock;
    if ($listen =~ /:\d+$/) {
        my($host, $port) = split /:/, $listen, 2;
        require IO::Socket::INET;
        $sock = IO::Socket::INET->new(
            LocalAddr => $host || '0.0.0.0',
            LocalPort => $port,
            ReuseAddr => 1,
            Proto     => 'tcp',
            Listen    => 10,
            Blocking  => 0,
        );
    } else {
        require IO::Socket::UNIX;
        socket $sock, AF_UNIX, SOCK_STREAM, 0;
        unlink $listen;
        my $umask = umask 0;
        bind $sock, sockaddr_un($listen);
        umask $umask;
        listen $sock, SOMAXCONN;
        fcntl $sock, F_SETFL, O_NONBLOCK;
        bless $sock, 'IO::Socket::UNIX';
    }

    $sock or die "Couldn't launch FCGI daemon on $listen";
    warn "Running FCGI daemon on $listen\n";

    # HACK: we return an object and pass it to handler_class. Because it works, and is cleaner
    my $handler = Plack::Handler::FCGI::EV::Handler->factory($app);

    my $w = EV::io $sock, EV::READ, sub {
        my $client = $sock->accept or die "No socket";
        $client->blocking(0);
        FCGI::EV->new( $client, $handler );
    };

    $self->{_sock} = $sock;
    $self->{_guard} = $w;

    return $self;
}

sub run {
    my $self = shift;
    $self->register_service(@_);

    # Could use EV::run, but this is prone to a crash due to:
    # syswrite() on closed filehandle GEN1653 at .../lib/site_perl/5.12.3/IO/Stream/EV.pm line 160.
    # At least AnyEvent will catch these errors

    # EV::run;

    AE::cv->recv;
}

package Plack::Handler::FCGI::EV::Handler;

use strict;
use Plack::Util;

use Carp ();
use URI::Escape;

sub factory {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

# HACK: This is called from FCGI::EV - but it's actually an instance
# method since we pass our own object to 'handler_class'.
sub new {
    my $factory = shift;
    my ($server, $env) = @_;

    my $app = $factory->{app};

    $env = {
        SCRIPT_NAME       => '',
        'psgi.version'    => [ 1, 0 ],
        'psgi.errors'     => *STDERR,
        'psgi.url_scheme' => 'http',
        'psgi.nonblocking'  => 1,
        'psgi.streaming'    => 1,
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 1,
        'psgi.run_once'     => 0,
        'psgix.input.buffered' => 1,
        %$env,
    };

    my $request_uri = $env->{REQUEST_URI};
    my ( $file, $query_string ) = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?
    $env->{PATH_INFO} = URI::Escape::uri_unescape $file;
    $env->{QUERY_STRING} = $query_string || '';
    $env->{SERVER_NAME} =~ s/:\d+$//;
    # warn Dumper $env;

    my $self = {
        stdin => '',
        server => $server,
        env => $env,
        app => $app,
    };
    bless $self, ref $factory;
}

# not support Async Input yet
sub stdin {
    my ($self, $stdin, $is_eof) = @_;
    $self->{stdin} .= $stdin;
    if ($is_eof) {
        open my $input, "<", \$self->{stdin};
        $self->{env}->{'psgi.input'} = $input;
        $self->run_app;
    }
}

sub run_app {
    my $self = shift;
    my $res  = Plack::Util::run_app $self->{app}, $self->{env};

    if (ref $res eq 'ARRAY') {
        $self->handle_response($res);
    } elsif (ref $res eq 'CODE') {
        $res->(sub { $self->handle_response($_[0]) });
    } else {
        Carp::croak("Unknown response: $res");
    }
}

sub handle_response {
    my($self, $res) = @_;

    my $hdrs = "Status: $res->[0]\r\n";
    Plack::Util::header_iter $res->[1], sub {
        $hdrs .= "$_[0]: $_[1]\r\n";
    };
    $hdrs .= "\r\n";
    $self->{server}->stdout($hdrs);

    if (defined $res->[2]) {
        my $cb = sub { $self->{server}->stdout( $_[0] ) };
        Plack::Util::foreach( $res->[2], $cb );
        $self->{server}->stdout( "", 1 );
    } else {
        return Plack::Util::inline_object
            write => sub { $self->{server}->stdout($_[0]) },
            close => sub { $self->{server}->stdout("", 1) };
    }
}

package Plack::Handler::FCGI::EV;

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Handler::FCGI::EV - PSGI handler for FCGI::EV

=head1 SYNOPSIS

  > plackup -s FCGI::EV --listen :8080 myapp.psgi

=head1 DESCRIPTION

Plack::Handler::FCGI::EV is an asynchronous PSGI handler using
L<FCGI::EV> as its backend.

=head1 AUTHORS

mala

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2011- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
