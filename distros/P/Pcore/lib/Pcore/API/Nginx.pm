package Pcore::API::Nginx;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_arrayref is_plain_hashref];

has nginx_bin               => 'nginx';
has conf_dir                => "$ENV->{DATA_DIR}/nginx";
has vhost_dir               => "$ENV->{DATA_DIR}/nginx/vhost";
has load_balancer_vhost_dir => '/var/run/nginx/vhost';
has load_balancer_sock_dir  => '/var/run/nginx/sock';
has user                    => ();                               # nginx workers user

has proc  => ( init_arg => undef );
has _poll => ( init_arg => undef );

sub run ($self) {
    $self->generate_conf;

    $self->{proc} = P->sys->run_proc( [ $self->{nginx_bin}, '-c', "$self->{conf_dir}/conf.nginx" ] );

    say 'Nginx started';

    return;
}

sub generate_conf ( $self ) {

    # generate mime types
    my $mime_types = $ENV->{share}->read_cfg('data/mime.yaml')->{suffix};

    my $nginx_mime_types;

    for my $suffix ( keys $mime_types->%* ) { $nginx_mime_types->{$suffix} = $mime_types->{$suffix}->[0] }

    my $geoip2_country_db_path = P->geoip->get_country_db_path;
    my $geoip2_city_db_path    = P->geoip->get_city_db_path;
    my $has_geoip              = $geoip2_country_db_path || $geoip2_city_db_path;

    my $params = {
        user      => $self->{user},
        pid       => "$self->{conf_dir}/nginx.pid",
        error_log => "$ENV->{DATA_DIR}/nginx-error.log",

        # geoip
        use_geoip2          => 0,                         # $has_geoip
        geoip2_country_path => $geoip2_country_db_path,
        geoip2_city_path    => $geoip2_city_db_path,

        vhost_dir   => $self->{vhost_dir},
        ssl_dhparam => $ENV->{share}->get('data/dhparam-4096.pem'),
        mime_types  => $nginx_mime_types,
    };

    my $cfg = P->tmpl( type => 'text' )->render( 'nginx/conf.nginx', $params );

    P->file->mkpath( $self->{conf_dir}, mode => 'rwxr-xr-x' ) if !-d $self->{conf_dir};

    P->file->write_text( "$self->{conf_dir}/conf.nginx", { mode => q[rw-r--r--] }, $cfg );

    return;
}

sub poll ($self) {
    $self->{_poll} = P->path( $self->{vhost_dir} )->poll_tree(
        interval  => 60,
        abs       => 0,
        is_dir    => 0,
        max_depth => 0,
        sub ( $root, $changes ) {
            Coro::async_pool {
                $self->reload;

                return;
            };

            return;
        }
    );

    return;
}

sub test ($self) {
    my $res = P->sys->run_proc( [ $self->{nginx_bin}, '-c', "$self->{conf_dir}/conf.nginx", '-t' ] )->wait;

    return res $res;
}

sub reload ($self) {
    if ( defined $self->{proc} && $self->{proc}->is_active ) {
        my $test = $self->test;

        if ($test) {
            kill 'HUP', $self->{proc}->{pid} || 0;

            say 'nginx: configuration reloaded';
        }
    }

    return;
}

# vhost
sub remove_vhosts ($self) {
    P->file->rmtree( $self->{vhost_dir} );

    return;
}

sub generate_vhost ( $self, $name, $params ) {

    # listen load balancer only if vhost has server names
    if ( $params->{server_name} && $params->{server_name}->@* ) {
        my $load_balancer_sock = "$self->{load_balancer_sock_dir}/$params->{app_name}-$name.sock";

        $self->_create_load_balancer_path;

        unlink $load_balancer_sock || 0;

        $params->{load_balancer_sock} = $load_balancer_sock;
    }

    my $cfg = P->tmpl( type => 'text' )->render( 'nginx/vhost.nginx', $params );

    return $cfg;
}

sub add_vhost ( $self, $name, $cfg ) {
    $cfg = $self->generate_vhost( $name, $cfg ) if is_plain_hashref $cfg;

    P->file->mkpath( $self->{vhost_dir}, mode => 'rwxr-xr-x' ) if !-d $self->{vhost_dir};

    P->file->write_text( "$self->{vhost_dir}/$name.nginx", { mode => 'rw-r--r--' }, $cfg );

    return;
}

sub add_default_vhost ($self) {
    my $cfg = P->tmpl( type => 'text' )->render( 'nginx/vhost-default.nginx', {} );

    $self->add_vhost( '_default', $cfg );

    return;
}

sub remove_vhost ( $self, $name ) {
    if ( $self->is_vhost_exists($name) ) {
        unlink "$self->{vhost_dir}/$name.nginx" or die;
    }

    return;
}

sub is_vhost_exists ( $self, $name ) {
    return -f "$self->{vhost_dir}/$name.nginx";
}

# load balancer
sub generate_load_balancer_vhost ( $self, $name, $params ) {
    $params = {
        $params->%*,
        vhost_name              => $name,
        load_balancer_vhost_dir => $self->{load_balancer_vhost_dir},
        load_balancer_sock_dir  => $self->{load_balancer_sock_dir},
        load_balancer_sock      => "$self->{load_balancer_sock_dir}/$name.sock",
    };

    my $cfg = P->tmpl( type => 'text' )->render( 'nginx/vhost-load-balancer.nginx', $params );

    return $cfg;
}

sub add_load_balancer_vhost ( $self, $name, $cfg ) {
    $cfg = $self->generate_load_balancer_vhost( $name, $cfg ) if is_plain_hashref $cfg;

    $self->_create_load_balancer_path;

    P->file->write_text( "$self->{load_balancer_vhost_dir}/$name.nginx", { mode => 'rw-r--r--' }, $cfg );

    return;
}

sub remove_load_balancer_vhost ( $self, $name ) {
    if ( $self->is_load_balancer_vhost_exists($name) ) {
        unlink "$self->{load_balancer_vhost_dir}/$name.nginx" or die;
    }

    return;
}

sub is_load_balancer_vhost_exists ( $self, $name ) {
    return -f "$self->{load_balancer_vhost_dir}/$name.nginx";
}

sub _create_load_balancer_path ($self) {
    P->file->mkpath( $self->{load_balancer_vhost_dir}, mode => 'rwxr-xr-x' ) if !-d $self->{load_balancer_vhost_dir};

    P->file->mkpath( $self->{load_balancer_sock_dir}, mode => 'rwxr-xr-x' ) if !-d $self->{load_balancer_sock_dir};

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Nginx - Pcore nginx application

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@cpan.org>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.

=cut
