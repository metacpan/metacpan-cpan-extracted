package Plack::Middleware::Camelcadedb;

=head1 NAME

Plack::Middleware::Camelcadedb - interactive debugging for Plack applications

=head1 SYNOPSIS

    # should be the first/one of the first modules to be loaded
    use Plack::Middleware::Camelcadedb (
        remote_host => "localhost:9000",
    );
    use Plack::Builder;

    builder {
        enable "Camelcadedb";
        $app;
    };

=back

=cut

use strict;
use warnings;

our $VERSION = '0.02';

use constant {
    DEBUG_SINGLE_STEP_ON        =>  0x20,
    DEBUG_USE_SUB_ADDRESS       =>  0x40,
    DEBUG_REPORT_GOTO           =>  0x80,
    DEBUG_ALL                   => 0x7ff,
};

use constant {
    DEBUG_OFF                   => 0x0,
    DEBUG_PREPARE_FLAGS         => # 0x73c
        DEBUG_ALL & ~(DEBUG_USE_SUB_ADDRESS|DEBUG_REPORT_GOTO|DEBUG_SINGLE_STEP_ON),
};

our @ISA;

sub import {
    my ($class, %args) = @_;

    die "Specify 'remote_host'"
        unless $args{remote_host};
    my ($host, $port) = split /:/, $args{remote_host}, 2;

    $ENV{PERL5_DEBUG_HOST} = $host;
    $ENV{PERL5_DEBUG_PORT} = $port;
    $ENV{PERL5_DEBUG_ROLE} = 'client';
    $ENV{PERL5_DEBUG_AUTOSTART} = 0;

    if ($args{enbugger}) {
        require Enbugger;

        Enbugger->VERSION(2.014);
        Enbugger->load_source;
    }

    my $inc_path = $args{debug_client_path};
    unshift @INC, ref $inc_path ? @$inc_path : $inc_path
        if $inc_path;
    require Devel::Camelcadedb;

    $^P = DEBUG_PREPARE_FLAGS;

    require Plack::Middleware;
    require Plack::Request;
    require Plack::Response;
    require Plack::Util;

    @ISA = qw(Plack::Middleware);
}

sub reopen_camelcadedb_connection {
    DB::connect_or_reconnect();
    DB::enable() if DB::is_connected();
}

sub close_camelcadedb_connection {
    DB::disconnect();
    DB::disable();
    # this works around uWSGI bug fixed by
    # https://github.com/unbit/uwsgi/commit/c6f61719106908b82ba2714fd9d2836fb1c27f22
    $^P = DEBUG_OFF;
}

sub call {
    my($self, $env) = @_;

    reopen_camelcadedb_connection();

    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
        return sub {
            # use $_[0] to try to avoid a copy
            if (!defined $_[0] && DB::is_connected()) {
                close_camelcadedb_connection();
            }

            return $_[0];
        };
    });
}

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2015-2016 Mattia Barbon. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
