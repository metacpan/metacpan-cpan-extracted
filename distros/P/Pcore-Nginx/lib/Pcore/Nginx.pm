package Pcore::Nginx v1.7.1;

use Pcore -dist, -class;

has data_dir     => ( is => 'ro',   isa => Str, default => "$ENV->{DATA_DIR}" );
has nginx_bin    => ( is => 'lazy', isa => Str, default => 'nginx' );
has nginx_prefix => ( is => 'lazy', isa => Str, default => '/etc/nginx/' );

has user => ( is => 'ro', isa => Maybe [Str] );    # nginx workers user

has conf_dir  => ( is => 'lazy', isa => Str,    init_arg => undef );
has vhost_dir => ( is => 'lazy', isa => Str,    init_arg => undef );
has proc      => ( is => 'ro',   isa => Object, init_arg => undef );

eval {
    require Pcore::GeoIP;
    Pcore::GeoIP->import;
};

sub _build_conf_dir ($self) {
    my $conf_dir = $self->data_dir . 'nginx/';

    P->file->mkpath($conf_dir);

    return $conf_dir;
}

sub _build_vhost_dir ($self) {
    my $vhost_dir = $self->conf_dir . 'vhost/';

    P->file->mkpath($vhost_dir);

    return $vhost_dir;
}

sub run ($self) {

    # generate mime types
    my $mime_types = P->cfg->read( $ENV->{share}->get('data/mime.json') )->{suffix};

    my $nginx_mime_types;

    for my $suffix ( keys $mime_types->%* ) {
        $nginx_mime_types->{ lc $suffix } = ref $mime_types->{ lc $suffix } eq 'ARRAY' ? $mime_types->{ lc $suffix }->[0] : $mime_types->{ lc $suffix };
    }

    my $params = {
        user               => $self->user,
        pid                => $self->conf_dir . 'nginx.pid',
        mime_types         => $self->conf_dir . 'mime.types',
        error_log          => $self->data_dir . 'nginx-error.log',
        geoip_country_path => $ENV->{share}->get('data/geoip_country.dat') || undef,
        geoip_city_path    => $ENV->{share}->get('data/geoip_city.dat') || undef,
        vhost_dir          => $self->vhost_dir,
        ssl_dhparam        => $ENV->{share}->get('data/nginx/dhparam-4096.pem'),
        mime_types         => $nginx_mime_types,
    };

    # generate conf.nginx
    P->file->write_text( $self->conf_dir . 'conf.nginx', { mode => q[rw-r--r--] }, P->tmpl( type => 'text' )->render( 'nginx/conf.nginx', $params ) );

    $self->{proc} = P->sys->run_proc( [ $self->nginx_bin, '-c', $self->conf_dir . 'conf.nginx' ] );

    return;
}

sub add_vhost ( $self, $name, $cfg ) {
    P->file->write_bin( $self->vhost_dir . "$name.nginx", $cfg );

    return;
}

sub is_vhost_exists ( $self, $name ) {
    return -f $self->vhost_dir . "$name.nginx";
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 15                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Nginx - Pcore nginx application

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@cpan.org>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by zdm.

=cut
