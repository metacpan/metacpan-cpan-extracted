package Parse::Daemontools::Service;

use strict;
use warnings;
use 5.008_005;
use bigint;

our $VERSION = '0.03';

use Carp;

sub new {
    my($class, $args) = @_;
    $args ||= {};

    my $self = bless {
        base_dir => '/service',
        %$args,
    }, $class;

    return $self;
}

sub base_dir {
    my($self, $base_dir) = @_;
    if ($base_dir) {
        if (! -d $base_dir) {
            Carp::carp("No such directory: $base_dir");
            return;
        }
        $self->{base_dir} = $base_dir;
    }
    return $self->{base_dir};
}

sub status {
    my($self, $service, $param) = @_;

    if (! $service) {
        Carp::carp("Missing mandatory args: service");
        return;
    }

    my $service_dir = join '/', $self->base_dir, $service;
    if (! -d $service_dir) {
        Carp::carp("No such directory: $service_dir");
        return;
    }

    ### down
    my $normallyup = 0;
    $normallyup = 1 if ! -e "$service_dir/down";

    ### supervise/status
    my $status_file = join '/', $service_dir, 'supervise', 'status';
    if (! -f $status_file) {
        Carp::carp("No such status file: $status_file");
        return;
    }

    open my $fh, '<', $status_file or do {
        Carp::carp("Failed to open status file: $status_file: $!");
        return;
    };
    my $status = do { local $/; <$fh> };
    close $fh;

    my($tai_h, $tai_l, $nanosec, $pid, $paused, $want) = unpack "NNLVCa", $status;

    $pid = undef if $pid == 0;

    my $when = ($tai_h << 32) + $tai_l;
    my $now  = tai64_now();
    if ($now < $when) {
        $when = $now;
    }
    my $elapse = $now - $when;

    my @info;
    push @info, "normally down" if ($pid && !$normallyup);
    push @info, "normally up"   if (!$pid && $normallyup);
    push @info, "paused"        if ($pid && $paused);
    push @info, "want up"       if (!$pid && $want eq 'u');
    push @info, "want down"     if ($pid && $want eq 'd');

    ### env/
    my $env = {};
    my @env_dir;
    if ($param->{env_dir}) {
        if (ref $param->{env_dir} eq 'ARRAY') {
            @env_dir = @{ $param->{env_dir} };
        } else {
            @env_dir = ($param->{env_dir});
        }
    } else {
        @env_dir = ("$service_dir/env");
    }
    for my $ed (@env_dir) {
        next unless -d $ed;

        if (opendir my $envdir, $ed) {
            while (my $k = readdir $envdir) {
                next if $k =~ /^\./;
                open my $fh, '<', "$ed/$k" or next;
                my $v = do { local $/; <$fh> };
                close $fh;
                chomp $v;
                $env->{$k} = $v;
            }
        } else {
            Carp::carp("Failed to open env dir: $ed: $!");
        }
    }

    my $start_at = tai642unix($when);
    $start_at = $start_at->numify if ref($start_at) && $start_at->can('numify');
    $elapse   = $elapse->numify   if ref($elapse)   && $elapse->can('numify');

    return {
        service  => $service_dir,
        status   => defined $pid ? 'up' : 'down',
        pid      => $pid,
        seconds  => $elapse,
        start_at => $start_at,
        info     => join(", ", @info),
        env      => $env,
    };
}

# http://cr.yp.to/libtai/tai64.html
# http://cr.yp.to/proto/tai64.txt
sub unix2tai64 {
    my $u = shift;
    return 4611686018427387914 + $u;
}

sub tai642unix {
    my $t = shift;
    return $t - 4611686018427387914;
}

sub tai64_now {
    return unix2tai64(time());
}

1;

__END__

=encoding utf-8

=begin html

<a href="https://travis-ci.org/hirose31/Parse-Daemontools-Service"><img src="https://travis-ci.org/hirose31/Parse-Daemontools-Service.png?branch=master" alt="Build Status" /></a>
<a href="https://coveralls.io/r/hirose31/Parse-Daemontools-Service?branch=master"><img src="https://coveralls.io/repos/hirose31/Parse-Daemontools-Service/badge.png?branch=master" alt="Coverage Status" /></a>

=end html

=head1 NAME

Parse::Daemontools::Service - Retrieve status and env of service under daemontools

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

Normally, Parse::Daemontools::Service requires root privileges because need to read /service/DAEMON/supervise/status file.

    use Parse::Daemontools::Service;
    
    my $ds = Parse::Daemontools::Service->new;
    my $status = $ds->status("qmail");
    
    my $status = $ds->status("my-daemon",
                             {
                                 env_dir => "/service/my-daemon/my-env-dir",
                             });
    
    my $status = $ds->status("my-daemon",
                             {
                                 env_dir => [
                                     "/service/my-daemon/env",
                                     "/service/my-daemon/my-env-dir",
                                 ],
                             });

=head1 DESCRIPTION

Parse::Daemontools::Service retrieves status and env of service under daemontools.

=head1 METHODS

=over 4

=item B<new>({ base_dir => Str })

base_dir (optional): base directory of daemontools. Default is "/service"

=item B<status>($service_name:Str, { env_dir => Str|ArrayRef[Str] })

Return status and env of $service_name as following HashRef.

    +{
        service  => Str, # "/service/my-daemon"
        pid      => Int, # PID of daemon process
        seconds  => Int, # uptime of this daemon process
        start_at => Int, # UNIX time of this daemon process started at
        status   => Str, # "up" | "down"
        info     => Str, # "" | "normally down" | "normally up" | ...
        env      => {    # environment variables in envdir
            BAR => "bar",
            FOO => "foo"
        },
    },

Default env_dir is "/service/my-daemon/env". You can specify env_dir(s) by Str or ArrayRef. When you specify more than one env_dirs, same key are overridden by latter env_dir.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31@gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/Parse-Daemontools-Service>

    git clone git://github.com/hirose31/Parse-Daemontools-Service.git

patches and collaborators are welcome.

=head1 SEE ALSO

svstat(1)

=head1 COPYRIGHT

Copyright HIROSE Masaaki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
