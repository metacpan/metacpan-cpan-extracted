package Pcore::App::API;

use Pcore -const, -class, -export, -res, -sql;
use Pcore::App::API::Const qw[:ROOT_USER];
use Pcore::Util::Scalar qw[looks_like_number looks_like_uuid];
use Pcore::App::API::Auth;
use Pcore::App::API::Router;

has app                => ( required => 1 );
has db                 => ();
has backend            => ();                  # undef - default, 0 - don't use, str - uri
has auth_workers       => undef;
has argon2_time        => 3;
has argon2_memory      => '64M';
has argon2_parallelism => 1;

has router   => ( init_arg => undef );
has dbh      => ( init_arg => undef );
has settings => ( init_arg => undef );

# INIT
sub init ($self) {

    # create dbh
    $self->{dbh} = P->handle( $self->{db}, max_dbh => 10 ) if $self->{db};

    # create router
    $self->{router} = Pcore::App::API::Router->new(
        ns  => ref $self,
        api => $self,
    );

    # init router
    my $res = $self->{router}->init( { map { $_ => 1 } $self->{app}->get_permissions->@* } );

    return $res if !$res;

    my $backend_class;

    # create / init backend
    if ( !defined $self->{backend} ) {
        if ( $self->{dbh}->{is_sqlite} ) {
            $backend_class = 'sqlite';
        }
        elsif ( $self->{dbh}->{is_pgsql} ) {
            $backend_class = 'pgsql';
        }
    }
    elsif ( $self->{backend} ) {
        my $uri = P->uri( $self->{backend} );

        state $scheme = {
            sqlite => 'sqlite',
            pgsql  => 'pgsql',
            http   => 'remote',
            https  => 'remote',
            ws     => 'remote',
            wss    => 'remote',
        };

        $backend_class = $scheme->{ $uri->{scheme} };
    }

    if ($backend_class) {
        $backend_class = eval { P->class->load( $backend_class, ns => 'Pcore::App::API::Backend' ) };

        die $@ if $@;

        $self->{backend} = $backend_class->new(
            app                => $self->{app},
            api                => $self,
            dbh                => $self->{dbh},
            auth_workers       => $self->{auth_workers},
            argon2_time        => $self->{argon2_time},
            argon2_memory      => $self->{argon2_memory},
            argon2_parallelism => $self->{argon2_parallelism},
        );

        $self->{backend}->init;
    }

    # upgrade shema
    if ( $self->{dbh} ) {
        print 'Upgrading DB schema ... ';

        $res = $self->upgrade_schema;

        say $res;

        return $res if !$res;

    }

    return res 200;
}

# template method
sub upgrade_schema ($self) {
    return res 200;
}

sub authenticate ( $self, $token = undef ) {
    if ( my $backend = $self->{backend} ) {
        return $backend->authenticate($token);
    }
    else {
        return bless {
            api              => $self,
            is_authenticated => 0,
          },
          'Pcore::App::API::Auth';
    }
}

# UTIL
sub user_is_root ( $self, $user_id ) {
    return $user_id eq $ROOT_USER_NAME || $user_id eq $ROOT_USER_ID;
}

# accepted characters: A-z (case-insensitive), 0-9, "_", "-", "@", ".", length: 3-32 characters, not number, not UUID
sub validate_user_name ( $self, $name ) {

    # name looks like UUID string
    return if looks_like_uuid $name;

    # name looks like number
    return if looks_like_number $name;

    # return if $name =~ /[^[:alnum:]_]/smi;

    return if $name =~ /[^[:alnum:]_@.-]/smi;

    return if length $name < 3 || length $name > 32;

    return 1;
}

# accepted characters: A-z (case-insensitive), 0-9 and underscores, length: 5-32 characters
sub validate_telegram_user_name ( $self, $name ) {
    return if $name =~ /[^[:alnum:]_]/smi;

    return if length $name < 5 || length $name > 32;

    return 1;
}

sub validate_email ( $self, $email ) {
    return $email =~ /^[[:alnum:]][[:alnum:]._-]+[[:alnum:]]\@[[:alnum:].-]+$/smi;
}

# SETTINGS
sub settings_load ( $self ) {
    state $q1 = $self->{dbh}->prepare(q[SELECT * FROM "settings" WHERE "id" = 1]);

    my $settings = $self->{dbh}->selectrow($q1);

    if ($settings) {
        delete $settings->{data}->{id};

        $self->{settings} = $settings->{data};

        P->fire_event( 'app.api.settings.updated', $settings->{data} );
    }

    return $settings;
}

# TODO check, if settings was updated
sub settings_update ( $self, $settings ) {
    $settings->{smtp_tls}                = TO_BOOL $settings->{smtp_tls}                if exists $settings->{smtp_tls};
    $settings->{telegram_bot_enabled}    = TO_BOOL $settings->{telegram_bot_enabled}    if exists $settings->{telegram_bot_enabled};
    $settings->{telegram_signin_enabled} = TO_BOOL $settings->{telegram_signin_enabled} if exists $settings->{telegram_signin_enabled};

    my $res = $self->{dbh}->do( [ q[UPDATE "settings"], SET [$settings], 'WHERE "id" = 1' ] );

    $self->settings_load if $res;

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
