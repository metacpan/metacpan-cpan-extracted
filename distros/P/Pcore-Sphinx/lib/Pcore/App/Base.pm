package Pcore::App::Base;

use Pcore -class, -ansi;
use Pcore::Util::Text qw[to_camel_case];

has name            => ( is => 'ro',   isa => SnakeCaseStr, required => 1 );
has name_camel_case => ( is => 'lazy', isa => Str,          init_arg => undef );
has ns              => ( is => 'ro',   isa => ClassNameStr, required => 1 );
has cfg             => ( is => 'lazy', isa => HashRef,      init_arg => undef );
has app_dir         => ( is => 'lazy', isa => Str,          init_arg => undef );
has _local_cfg_path => ( is => 'lazy', isa => Str,          init_arg => undef );

# RUN-TIME ENVIRONMENT
has runtime_env => ( is => 'rwp', isa => Enum [qw[development test production]], default => 'production' );
has env_is_devel => ( is => 'lazy', isa => Bool, init_arg => undef );
has env_is_test  => ( is => 'lazy', isa => Bool, init_arg => undef );
has env_is_prod  => ( is => 'lazy', isa => Bool, init_arg => undef );

our $CFG = { SECRET => undef, };

# CLI
sub CLI ($self) {
    return {
        opt => {
            app => {
                short => undef,
                desc  => 'command (build|deploy|test)',
                isa   => [qw[build deploy test]],
            },
            env => {
                short => 'E',
                desc  => 'set run-time environment (development|test|production)',
                isa   => [qw[development test production]],
            },
        },
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    my $app = $self->new;

    # process -E option
    $app->_set_runtime_env( $opt->{env} ) if $opt->{env};

    if ( $opt->{app} ) {
        if ( $opt->{app} eq 'build' ) {
            $app->report_info(qq[Build application "@{[$app->name]}"]);
            $app->report_info(qq[Application data dir "@{[$app->app_dir]}"]);

            $app->app_build;

            $app->report_info(q[Build completed]);

            exit;
        }
        elsif ( $opt->{app} eq 'deploy' ) {
            $app->report_info(qq[Deploy application "@{[$app->name]}"]);
            $app->report_info(qq[Application data dir "@{[$app->app_dir]}"]);

            $app->app_deploy;

            $app->report_info(q[Deploy completed]);

            exit;
        }
        elsif ( $opt->{app} eq 'test' ) {
            $app->report_info(qq[Test application "@{[$app->name]}"]);
            $app->report_info(qq[Application data dir "@{[$app->app_dir]}"]);

            $app->app_test;

            $app->report_info(q[Test completed]);

            exit;
        }
    }
    else {
        $app->run;
    }

    return;
}

sub BUILD ( $self, $args ) {
    P->hash->merge( $self->cfg, $args->{cfg} ) if $args->{cfg};    # merge default cfg with inline cfg

    P->hash->merge( $self->cfg, $self->_read_local_cfg );          # merge with local cfg

    return;
}

# REPORT
sub report_fatal ( $self, $msg ) {
    say BOLD . RED . q[[ FATAL ] ] . RESET . $msg;

    exit 255;
}

sub report_warn ( $self, $msg ) {
    say BOLD . YELLOW . q[[ WARN ]  ] . RESET . $msg;

    return;
}

sub report_info ( $self, $msg ) {
    say $msg;

    return;
}

# CFG
sub _build_name_camel_case ($self) {
    return to_camel_case( $self->name, ucfirst => 1 );
}

sub _build_app_dir ($self) {
    my $dir = $ENV->{DATA_DIR} . $self->name . q[/];

    P->file->mkpath($dir);

    return $dir;
}

sub _build_cfg ($self) {
    return $CFG;    # return default cfg
}

sub _build__local_cfg_path ($self) {
    return $self->app_dir . $self->name . q[.perl];
}

sub _read_local_cfg ($self) {
    return -f $self->_local_cfg_path ? P->cfg->load( $self->_local_cfg_path ) : {};
}

sub _create_local_cfg ($self) {

    # create local cfg
    my $local_cfg = { SECRET => P->random->bytes_hex(16), };

    return $local_cfg;
}

# RUN-TIME ENVIRONMENT
sub _build_env_is_devel ($self) {
    return $self->runtime_env eq 'development' ? 1 : 0;
}

sub _build_env_is_test ($self) {
    return $self->runtime_env eq 'test' ? 1 : 0;
}

sub _build_env_is_prod ($self) {
    return $self->runtime_env eq 'production' ? 1 : 0;
}

# PHASES
sub run ($self) {
    return $self->app_run;
}

sub app_build ($self) {

    # create local cfg
    $self->report_info(q[Create local config]);

    my $local_cfg = $self->_create_local_cfg;

    P->hash->merge( $local_cfg, $self->_read_local_cfg );    # override local cfg with already configured values

    # store local config
    $self->report_info( q[Store local config to "] . $self->_local_cfg_path . q["] );

    P->cfg->store( $self->_local_cfg_path, $local_cfg, readable => 1 );

    return;
}

sub app_deploy ($self) {
    return;
}

sub app_test ($self) {
    return;
}

sub app_run ($self) {
    return;
}

sub app_reset ($self) {
    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Base

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
