package Test::APIcast;
use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Fcntl qw(:flock SEEK_END);

our $VERSION = "0.24";

BEGIN {
    $ENV{TEST_NGINX_BINARY} ||= 'openresty';
}

use Test::Nginx::Socket::Lua -Base;

use Cwd qw(cwd abs_path);
use File::Spec::Functions qw(catfile);
use File::Slurp qw(read_file);

my $pwd = cwd();
our $path = $ENV{TEST_NGINX_APICAST_PATH} ||= "$pwd/gateway";
our $spec = "$pwd/spec";
our $servroot = $Test::Nginx::Util::ServRoot;

our $Fixtures = abs_path($ENV{TEST_NGINX_FIXTURES} || catfile('t', 'fixtures'));

# src/?/policy.lua allows us to require apicast.policy.apolicy
$ENV{TEST_NGINX_LUA_PATH} = "$path/src/?.lua;$path/src/?/policy.lua;;";
$ENV{TEST_NGINX_MANAGEMENT_CONFIG} = "$path/conf.d/management.conf";
$ENV{TEST_NGINX_UPSTREAM_CONFIG} = "$path/http.d/upstream.conf";
$ENV{TEST_NGINX_BACKEND_CONFIG} = "$path/conf.d/backend.conf";
$ENV{TEST_NGINX_APICAST_CONFIG} = "$path/conf.d/apicast.conf";
$ENV{APICAST_DIR} = $path;

if ($ENV{DEBUG}) {
    $ENV{TEST_NGINX_ERROR_LOG} ||= '/dev/stderr';
}

our @EXPORT = qw( get_random_port );

our @PORTS = ();

open(my $prove_filename_lock, ">", "/tmp/prove_lock");

sub lock {
    flock($prove_filename_lock, LOCK_EX) or bail_out "cannot get prove lock.";
    # and, in case someone appended while we were waiting...
    seek($prove_filename_lock, 0, SEEK_END) or bail_out "cannot get prove lock.";
}

sub unlock {
    flock($prove_filename_lock, LOCK_UN) or bail_out "Cannot release prove lock";
}

sub get_random_port {
    my $tries = 1000;
    my $ServerPort;
    lock();
    for (my $i = 0; $i < $tries; $i++) {
        my $port = int(rand 60000) + 1025;

        my $sock = IO::Socket::INET->new(
            LocalPort => $port,
            Proto => 'tcp',
        );

        if (defined $sock) {
            $sock->shutdown(0);
            $sock->close();
            push @PORTS, $sock;
            $ServerPort = $port;
            last;
        }

        if ($Test::Nginx::Util::Verbose) {
            warn "Try again, port $port is already in use: $@\n";
        }
    }
    unlock();

    if (!defined $ServerPort) {
        bail_out "Cannot find an available listening port number after $tries attempts.\n";
    }

    return $ServerPort;
}

env_to_nginx('APICAST_DIR');
env_to_nginx("TEST_NGINX_SERVER_PORT=$Test::Nginx::Util::ServerPortForClient");

log_level('debug');
repeat_each($ENV{TEST_NGINX_REPEAT_EACH} || 2);
no_root_location();

add_block_preprocessor(sub {
    my $block = shift;

    $ENV{TEST_NGINX_RANDOM_PORT} = $block->random_port;
});


sub close_random_ports {
   my $sock;
    while (defined($sock = shift @PORTS)){
        $sock->close();
    }
};

our $dns = sub ($$$) {
    my ($host, $ip, $ttl) = @_;

    return sub {
        # Get DNS request ID from passed UDP datagram
        my $dns_id = unpack("n", shift);
        # Set name and encode it
        my $name = $host;
        $name =~ s/([^.]+)\.?/chr(length($1)) . $1/ge;
        $name .= "\0";
        my $s = '';
        $s .= pack("n", $dns_id);
        # DNS response flags, hardcoded
        # response, opcode, authoritative, truncated, recursion desired, recursion available, reserved
        my $flags = (1 << 15) + (0 << 11) + (1 << 10) + (0 << 9) + (1 << 8) + (1 << 7) + 0;
        $flags = pack("n", $flags);
        $s .= $flags;
        $s .= pack("nnnn", 1, 1, 0, 0);
        $s .= $name;
        $s .= pack("nn", 1, 1); # query class A

        # Set response address and pack it
        my @addr = split /\./, $ip;
        my $data = pack("CCCC", @addr);

        # pointer reference to the first name
        # $name = pack("n", 0b1100000000001100);

        # name + type A + class IN + TTL + length + data(ip)
        $s .= $name. pack("nnNn", 1, 1, $ttl || 0, 4) . $data;
        return $s;
    }
};

sub Test::Base::Filter::random_port {
    my ($self, $code) = @_;

    my $block = $self->current_block;
    my $random_port = $block->random_port;

    if ( !defined $random_port ) {
        if ($Test::Nginx::Util::Randomize) {
            $random_port = get_random_port();
        } else {
            $random_port = 1953;
        }
    }

    $block->set_value('random_port', $random_port);

    $ENV{TEST_NGINX_RANDOM_PORT} = $random_port;

    return $code;
}


sub Test::Base::Filter::dns {
    my ($self, $code) = @_;

    my $input = eval $code;

    if ($@) {
        die "failed to evaluate code $code: $@\n";
    }

    return $dns->(@$input)
}


sub Test::Base::Filter::env {
    my ($self, $input) = @_;

    return Test::Nginx::Util::expand_env_in_config($input);
}

sub Test::Base::Filter::fixture {
    my $name = filter_arguments;

    if (! $name) {
        bail_out("fixture filter needs argument - file to be loaded");
    };

    my $file = catfile($Fixtures, $name);

    if (! -f $file) {
        bail_out("$file is not a file - fixture cannot be loaded");
    }
    my $contents = read_file($file);

    return $contents;
}


BEGIN {
    no warnings 'redefine';

    *write_config_file= \&Test::Nginx::Util::write_config_file;

    *Test::Nginx::Util::write_config_file = sub ($$) {
        write_config_file(@_);
        close_random_ports();
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::APIcast - Testing framework for L<APIcast|https://github.com/3scale/apicast>.

=head1 SYNOPSIS

    use Test::APIcast;

=head1 DESCRIPTION

Test::APIcast is testing framework for the APIcast gateway.

=head1 LICENSE

Copyright (C) Red Hat Inc.

This library is free software; you can redistribute it and/or modify
it under the terms of Apache License Version 2.0.

=head1 AUTHOR

Michal Cichra E<lt>mcichra@redhat.comE<gt>

=cut

