package Silki::Build;

use strict;
use warnings;

use File::Path qw( mkpath );
use File::Spec;

use base 'Module::Build';

use lib 'lib';

sub new {
    my $class = shift;
    my %args  = @_;

    $args{get_options} = {
        'db-name'     => { type => '=s', default => 'Silki' },
        'db-username' => { type => '=s' },
        'db-password' => { type => '=s' },
        'db-host'     => { type => '=s' },
        'db-port'     => { type => '=s' },
        'db-ssl'      => {},
    };

    $args{auto_features} = {
        PSGI => {
            description => 'PSGI app (silki.psgi)',
            requires    => {
                'Catalyst::Engine::PSGI'          => '0',
                'Plack'                           => '0',
                'Plack::Builder'                  => '0',
                'Plack::Middleware::ReverseProxy' => '0',
            },
        },
    };

    my $self = $class->SUPER::new(%args);

    $self->_update_from_existing_config();

    return $self
}

sub _update_from_existing_config {
    my $self = shift;

    my $config = eval {
        local $ENV{SILKI_CONFIG}
            = File::Spec->catfile( $self->args('etc-dir'), 'silki.conf' )
            if $self->args('etc-dir');

        require Silki::Config;

        Silki::Config->new();
    };

    return unless $config;

    for my $mb_key (
        qw( db-name db-username db-password db-host db-port db-ssl share-dir )
        ) {
        ( my $meth = $mb_key ) =~ s/-/_/g;
        $meth =~ s/db/database/;

        my $value = $config->$meth();

        next unless defined $value && length $value;

        $self->args( $mb_key => $value );
    }

    return;
}

sub process_share_dir_files {
    my $self = shift;

    return if $self->args('share-dir');

    return $self->SUPER::process_share_dir_files(@_);
}

sub ACTION_install {
    my $self = shift;

    $self->SUPER::ACTION_install(@_);

    $self->dispatch('share');

    $self->dispatch('database');

    $self->dispatch('config');

    $self->dispatch('clean_mason_cache');
}

sub ACTION_share {
    my $self = shift;

    my $share_dir = $self->args('share-dir')
        or return;

    for my $file ( grep { -f } @{ $self->rscan_dir('share') } ) {
        ( my $shareless = $file ) =~ s{share[/\\]}{};

        $self->copy_if_modified(
            from => $file,
            to   => File::Spec->catfile( $share_dir, $shareless ),
        );
    }

    return;
}

sub ACTION_database {
    my $self = shift;

    require Silki::DatabaseManager;

    my %db_config;

    my %args = $self->args();

    for my $key ( grep { defined $args{$_} } grep { /^db-/ } keys %args ) {
        ( my $no_prefix = $key ) =~ s/^db-//;
        $db_config{$no_prefix} = $args{$key};
    }

    my $hostname = $self->args('hostname');

    local $ENV{SILKI_HOSTNAME} = $hostname
        if defined $hostname && $hostname ne q{};

    $db_config{db_name} = delete $db_config{name};

    Silki::DatabaseManager->new(
        %db_config,
        production => 1,
        quiet      => $self->quiet(),
    )->update_or_install_db();
}

sub ACTION_config {
    my $self = shift;

    my $config_file = File::Spec->catfile( $self->args('etc-dir')
            || ( '', 'etc', 'silki' ), 'silki.conf' );

    require Silki::Config;

    my $config = Silki::Config->instance();

    if ( -f $config_file ) {
        $self->log_info("  You already have a config file at $config_file.\n\n");
        return;
    }
    else {
        $self->log_info("  Generating a new config file at $config_file.\n\n");
    }

    require Digest::SHA;
    my $secret = Digest::SHA::sha1_hex( time . $$ . rand(1_000_000_000) );

    my %values = (
        'is_production' => 1,
        'secret'        => $secret,
    );

    my %args = $self->args();

    $values{share_dir} = $args{'share-dir'}
        if $args{'share-dir'};

    $values{cache_dir} = $args{'cache-dir'}
        if $args{'cache-dir'};

    for my $key ( grep { defined $args{$_} } grep {/^db-/} keys %args ) {
        ( my $conf_key = $key ) =~ s/^db-//;
        $values{ 'database_' . $conf_key } = $args{$key};
    }

    delete $values{database_name}
        if $values{database_name} eq 'Silki';

    delete $values{database_ssl}
        unless $values{database_ssl};

    Silki::Config->new()
        ->write_config_file( file => $config_file, values => \%values );
}

sub ACTION_clean_mason_cache {
    my $self = shift;

    require Silki::Config;

    my $config = Silki::Config->instance();

    my $cache_dir = $config->cache_dir();

    if ( -w $cache_dir ) {
        require File::Path;

        $self->log_info("  Deleting your mason cache dir at $cache_dir\n\n");

        File::Path::rmtree( $cache_dir->subdir('mason'), 0, 0 );
    }
    else {
        $self->log_warning("  Cannot delete your mason cache dir at $cache_dir\n  You may want to do this manually\n\n");
    }
}

1;
