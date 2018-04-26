package Pcore::Sphinx v0.9.2;

use Pcore -dist, -class;

extends qw[Pcore::App::Alien];

with qw[Pcore::Core::CLI::Opt::Perms];

has '+name' => ( default => 'sphinx' );
has '+ns'   => ( default => 'Pcore::Sphinx' );

has alien_cfg_dir          => ( is => 'lazy', isa => Str, init_arg => undef );
has alien_indexer_bin_path => ( is => 'lazy', isa => Str, init_arg => undef );

has sphinx_ver => ( is => 'lazy', isa => Str, init_arg => undef );

our $CFG = { sphinx_ver => undef, };

# CLI
around CLI => sub ( $orig, $self ) {
    my $cli = $self->$orig;

    $cli->{name} = 'sphinx';

    $cli->{opt}->{indexer} = {
        short => undef,
        desc  => q[],
    };

    return $cli;
};

sub _build_sphinx_ver ($self) {
    return $self->cfg->{sphinx_ver} || $ENV->dist('Pcore-Sphinx')->cfg->{sphinx_ver};
}

# APP
around run => sub ( $orig, $self ) {
    if ( $ENV->cli->{opt}->{indexer} ) {
        say q[start indexer];

        $self->generate_alien_cfg;

        P->pm->run_proc( [ $self->alien_indexer_bin_path, q[--config], $self->alien_cfg_path, '--all' ] ) or die;

        exit 0;
    }

    $self->$orig;

    return;
};

around _build_cfg => sub ( $orig, $self ) {
    return P->hash->merge(
        $self->$orig,
        $CFG,
        {   server => {
                searchd => {
                    listen                       => q[9306:mysql41],
                    log                          => $ENV->{DATA_DIR} . $self->name . '-searchd.log',
                    query_log                    => $ENV->{DATA_DIR} . $self->name . '-searchd-query.log',
                    read_timeout                 => 5,
                    client_timeout               => 300,
                    max_children                 => 30,
                    persistent_connections_limit => 30,
                    pid_file                     => $self->app_dir . 'searchd.pid',
                    max_matches                  => 1000,
                    seamless_rotate              => 1,
                    preopen_indexes              => 1,
                    unlink_old                   => 1,
                    attr_flush_period            => 0,
                    ondisk_dict_default          => 0,
                    mva_updates_pool             => '1M',
                    max_packet_size              => '8M',
                    max_filters                  => 256,
                    max_filter_values            => 4096,
                    listen_backlog               => 5,
                    read_buffer                  => '256K',
                    read_unhinted                => '32K',
                    max_batch_queries            => '32',
                    subtree_docs_cache           => '4M',
                    subtree_hits_cache           => '8M',
                    workers                      => 'threads',
                    dist_threads                 => 4,
                    binlog_path                  => $self->alien_data_dir,
                    binlog_flush                 => 2,
                    binlog_max_log_size          => '128M',
                    thread_stack                 => '64K',
                    expansion_limit              => 0,
                    rt_flush_period              => 0,
                    query_log_format             => 'sphinxql',
                    mysql_version_string         => undef,
                    plugin_dir                   => q[],
                    collation_server             => 'utf8_general_ci',
                    collation_libc_locale        => 'C',
                    watchdog                     => 1,
                    compat_sphinxql_magics       => 0,
                    predicted_time_costs         => q[doc=64, hit=48, skip=2048, match=64],
                    sphinxql_state               => $self->alien_data_dir . 'sphinxvars.sql',
                    rt_merge_iops                => 0,
                    rt_merge_maxiosize           => 0,
                    ha_ping_interval             => 1000,
                    ha_period_karma              => 60,
                    prefork_rotation_throttle    => 0,
                    snippets_file_prefix         => q[],
                },
                indexer => {
                    mem_limit             => '32M',
                    max_iops              => 0,
                    max_iosize            => 0,
                    max_xmlpipe2_field    => '2M',
                    write_buffer          => '1M',
                    max_file_field_buffer => '8M',
                    on_file_field_error   => 'ignore_field',
                    on_json_attr_error    => 'ignore_attr',
                    json_autoconv_numbers => 0,

                    # json_autoconv_keynames => 'lowercase',
                    # lemmatizer_base  => $self->app_dir . q[],
                    lemmatizer_cache => '256K',
                },
            }
        }
    );
};

around _create_local_cfg => sub ( $orig, $self ) {
    my $local_cfg = {
        sphinx_ver => $self->cfg->{sphinx_ver},
        server     => $self->cfg->{server},
    };

    return P->hash->merge( $self->$orig, $local_cfg );
};

sub _build_alien_dir ($self) {
    return $self->app_dir . 'sphinx-' . $self->sphinx_ver . q[/];
}

sub _build_alien_data_dir ($self) {
    my $dir = $self->app_dir . 'sphinx-data/';

    P->file->mkpath($dir);

    return $dir;
}

sub _build_alien_cfg_dir ($self) {
    my $dir = $self->app_dir . 'indexes';

    P->file->mkpath($dir);

    return $dir;
}

sub _build_alien_bin_path ($self) {
    return $self->alien_dir . 'bin/searchd';
}

sub _build_alien_indexer_bin_path ($self) {
    return $self->alien_dir . 'bin/indexer';
}

sub _build_alien_cfg_path ($self) {
    return $self->app_dir . 'sphinx.conf';
}

# TODO postgres sphinx integration plugin https://github.com/andy128k/pg-sphinx
# http://sphinxsearch.com/forum/view.html?id=13001
# https://anadea.info/blog/postgresql-and-sphinx-search-seamless-integration
around app_build => sub ( $orig, $self ) {
    $self->$orig;

    if ( -d $self->alien_dir ) {
        $self->report_warn( q["] . $self->alien_dir . q[" already exists. Remove it manually to rebuild] );
    }
    else {
        eval {

            # sphinx
            P->pm->run_proc( q[wget -O - http://sphinxsearch.com/files/sphinx-] . $self->sphinx_ver . qq[-release.tar.gz | tar -C $ENV->{TEMP_DIR} -xzvf -] ) or die;

            # libstemmer
            P->pm->run_proc( qq[wget -O - http://snowball.tartarus.org/dist/libstemmer_c.tgz | tar -C $ENV->{TEMP_DIR}sphinx-] . $self->sphinx_ver . q[-release -xzvf -] ) or die;

            {
                my $chdir_guard = P->file->chdir( $ENV->{TEMP_DIR} . 'sphinx-' . $self->sphinx_ver . q[-release] ) or die;

                P->pm->run_proc( [ './configure', '--prefix=' . $self->alien_dir, '--without-mysql', '--with-pgsql', '--with-libstemmer', '--with-libexpat', '--with-iconv', '--enable-id64' ] ) or die;

                P->pm->run_proc( [ 'make', '-j' . P->sys->cpus_num ] ) or die;

                P->pm->run_proc( [ 'make', 'install' ] ) or die;
            }
        };

        if ($@) {
            P->file->rmtree( $self->alien_dir );

            $self->report_fatal(qq[Error building application. Maybe you need to manually install dependencies, try: "sudo yum -y install expat-devel re2"]);
        }
    }

    return;
};

around app_deploy => sub ( $orig, $self ) {
    $self->$orig;

    return;
};

sub generate_alien_cfg ($self) {
    my %cfg;

    for my $section ( sort keys %{ $self->cfg->{server} } ) {
        next if !$self->cfg->{server}->{$section};

        my $cfg;
        for my $key ( sort keys %{ $self->cfg->{server}->{$section} } ) {
            next if !defined $self->cfg->{server}->{$section}->{$key};

            if ( ref $self->cfg->{server}->{$section}->{$key} eq 'ARRAY' ) {
                for my $val ( @{ $self->cfg->{server}->{$section}->{$key} } ) {
                    $cfg .= qq[    $key = $val\n];
                }
            }
            else {
                $cfg .= qq[    $key = ] . $self->cfg->{server}->{$section}->{$key} . $LF;
            }
        }

        $cfg{$section} = $cfg;
    }

    my $conf = qq[#!/bin/sh\n\ncat <<EOF\n];
    $conf .= join $LF, map {"$_ {\n$cfg{$_}}"} sort keys %cfg;
    $conf .= qq[\nEOF\n\ncat ] . $self->alien_cfg_dir . q[/*.conf];

    $self->store_alien_cfg( \$conf );

    return;
}

sub master_proc ($self) {
    return;
}

sub alien_proc ($self) {
    $self->generate_alien_cfg;

    exec $self->alien_bin_path, q[--config], $self->alien_cfg_path, q[--nodetach] or die;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 179                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 201                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Sphinx

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@cpan.org>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.

=cut
