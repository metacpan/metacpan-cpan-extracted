package Nginx::Runner;

use strict;
use warnings;
use 5.008_001;

our $VERSION = '0.001';

use Nginx::Runner::Config;
use File::Temp;
use Time::HiRes 'usleep';
use IPC::Open3 'open3';

require Carp;

sub new {
    my ($class, @args) = @_;

    bless {
        nginx_bin  => "/usr/sbin/nginx",
        error_log  => "/tmp/nginx.error",
        access_log => "/tmp/nginx.access",
        servers    => [],
        @args
    }, $class;
}

sub DESTROY {
    my $self = shift;

    $self->stop if $self->is_running;
}

sub proxy {
    my ($self, $src, $dst, @args) = @_;

    if (my ($proto, $address) = ($src =~ m{^(\w+)://(.+?)(/.+)?$})) {
        if ($proto eq 'http') {
            $src = $address;
        }
        elsif ($proto eq 'https') {
            $src = $address;
            push @args, [ssl => 'on'];
        }
    }

    push @{$self->{servers}},
      [ server => [
            [listen   => $src],
            [location => '/' => [[proxy_pass => "http://$dst"]]], @args
        ]
      ];

    $self;
}

sub is_running { $_[0]->{pid} }

sub run {
    my $self = shift;

    return if $self->is_running;

    my ($pid_fh, $pid_fn) =
      File::Temp::tempfile(UNLINK => 1, SUFFIX => '.pid');

    my $config = [
        [worker_processes => 1],
        [error_log        => $self->{error_log}, "info"],
        [pid              => $pid_fn],
        [daemon           => "on"],
        [events => [[worker_connections => 1024], [use => "epoll"]]],
        [http => [[access_log => $self->{access_log}], @{$self->{servers}}]]
    ];

    my ($conf_fh, $conf_fn) =
      File::Temp::tempfile(UNLINK => 1, SUFFIX => '.conf');
    $conf_fh->print(Nginx::Runner::Config::encode($config));
    $conf_fh->close;

    my ($stdout, $stderr);

    my $pid =
      open3(undef, $stdout, undef, $self->{nginx_bin} . " -c $conf_fn");
    waitpid($pid, 0);

    if ($?) {
        my @stdout = <$stdout>;
        die "Unable to run nginx: $stdout[-1]" if $?;
    }

    undef $pid;
    while (!($pid = <$pid_fh>)) { usleep 50; }
    $pid_fh->close;

    $self->{pid} = $pid;
}

sub stop {
    my $self = shift;

    kill "TERM", delete $self->{pid};
}

1;
__END__

=head1 NAME

Nginx::Runner - run nginx proxy server

=head1 SYNOPSIS

    use Nginx::Runner;

    my $nginx = Nginx::Runner->new;

    $nginx->proxy("127.0.0.1:8080" => "127.0.0.1:3000");
    
    $nginx->proxy(
        "https://127.0.0.1:8443" => "127.0.0.1:3000",
        [ssl_certificate     => "/etc/ssl/nginx/nginx.pem"],
        [ssl_certificate_key => "/etc/ssl/nginx/nginx.pem"]
    );
    
    $nginx->run;

    $SIG{INT} = sub { $nginx->stop };

    print "Server available at ",
      "http://127.0.0.1:8080 and https://127.0.0.1:8443\n";

    sleep;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Sergey Zasenko.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.14.

=head1 SEE ALSO

    L<http://nginx.org>

=cut
