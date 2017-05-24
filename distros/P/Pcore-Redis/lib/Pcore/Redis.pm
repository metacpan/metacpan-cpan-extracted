package Pcore::Redis v0.8.0;

use Pcore -dist, -class;

has data_dir => ( is => 'ro', isa => Str, required => 1 );

sub run ( $self, $cb ) {
    my $cfg = -f $self->data_dir . '/redis.json' ? P->cfg->load( $self->data_dir . '/redis.json' ) : $self->default_config;

    # generate password
    $cfg->{requirepass} //= P->random->bytes_hex(32);

    P->cfg->store( $self->data_dir . '/redis.json', $cfg, readable => 1 ) if !-f $self->data_dir . '/redis.json';

    $self->store_config($cfg);

    say "PASSWORD: $cfg->{requirepass}";

    # create and prepare unix socket dir
    P->file->mkdir('/tmp/redis.sock') if !-d '/tmp/redis.sock';

    # init log dir
    my $log_dir = "$ENV->{DATA_DIR}";

    # run server
    P->pm->run_proc(
        [ 'redis-server', '--include', $self->data_dir . '/redis.conf' ],
        on_finish => sub ($proc) {
            $cb->($proc);

            return;
        }
    );

    return;
}

sub store_config ( $self, $cfg ) {
    my $config;

    my $add_key = sub ( $key, $val ) {
        my $cfg_key = $key =~ s/_/-/smgr;

        if ( ref $val eq 'ARRAY' ) {
            $config .= qq[$cfg_key ] . join( q[ ], $val->@* ) . $LF;
        }
        else {
            $config .= qq[$cfg_key $val\n];
        }

        return;
    };

    for my $key ( sort keys $cfg->%* ) {
        next if !defined $cfg->{$key};

        if ( ref $cfg->{$key} eq 'ARRAY' ) {
            for ( $cfg->{$key}->@* ) {
                $add_key->( $key, $_ );
            }
        }
        else {
            $add_key->( $key, $cfg->{$key} );
        }
    }

    P->file->write_bin( $self->data_dir . '/redis.conf', $config );

    return;
}

sub default_config ( $self ) {
    my $data_dir = $self->data_dir;

    return {
        appendfilename              => 'redis.aof',
        appendonly                  => 'yes',
        bind                        => ['0.0.0.0'],
        databases                   => 16,
        dbfilename                  => 'redis.rdb',
        dir                         => $data_dir,
        logfile                     => "$ENV->{DATA_DIR}redis.log",
        loglevel                    => 'notice',
        pidfile                     => "${data_dir}redis.pid",
        port                        => 6379,                                           # use 0 to stop TCP interface
        rdbchecksum                 => 'yes',
        rdbcompression              => 'yes',
        repl_disable_tcp_nodelay    => 'no',
        requirepass                 => undef,
        save                        => [ [ 900, 1 ], [ 300, 10 ], [ 60, 10_000 ], ],
        slave_priority              => 100,
        slave_read_only             => 'yes',
        slave_serve_stale_data      => 'yes',
        stop_writes_on_bgsave_error => 'yes',
        tcp_backlog                 => 511,
        tcp_keepalive               => 0,
        timeout                     => 0,
        unixsocket                  => "/tmp/redis.sock/redis-6379.sock",
        unixsocketperm              => 755,
    };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 98                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Redis

=head1 SYNOPSIS

    docker create --name redis -v redis:/var/local/pcore-redis/data/ -p 6379:6379/tcp softvisio/pcore-redis

    docker create --name redis -v redis:/var/local/pcore-redis/data/ -v /tmp/redis.sock/:/tmp/redis.sock/ -p 6379:6379/tcp softvisio/pcore-redis

    # connect via TCP
    my $h = P->handle('redis://password@host:port?db=dbindex');

    # connect via unix socket
    my $h = P->handle('redis://password@/tmp/redis.sock/redis-6379.sock?db=dbindex');

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@cpan.org>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.

=cut
