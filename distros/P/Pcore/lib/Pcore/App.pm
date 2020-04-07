package Pcore::App;

use Pcore -role, -const;
use Pcore::API::Nginx;
use Pcore::HTTP::Server;
use Pcore::App::Router;
use Pcore::CDN;
use Pcore::Util::Scalar qw[is_plain_arrayref];

has devel => 0;    # Bool

has env    => ( init_arg => undef );    # HashRef
has name   => ( init_arg => undef );
has server => ( init_arg => undef );    # InstanceOf ['Pcore::HTTP::Server']
has router => ( init_arg => undef );    # HashRef [ InstanceOf ['Pcore::App::Router'] ]
has api    => ( init_arg => undef );    # Maybe [ InstanceOf ['Pcore::App::API'] ]
has node   => ( init_arg => undef );    # InstanceOf ['Pcore::Node']
has cdn    => ( init_arg => undef );    # InstanceOf['Pcore::CDN']

const our $PERMS_ADMIN => 'admin';
const our $PERMS_USER  => 'user';
const our $PERMS       => [ $PERMS_ADMIN, $PERMS_USER ];

const our $LOCALES => {
    en => 'English',

    # ru => 'Русский',
    # de => 'Deutsche',

};

around new => sub ( $orig, $self, $devel = undef, $env = undef ) {
    $devel //= $ENV{PCORE_DEVEL};

    $ENV{PCORE_DEVEL} = $devel;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    $self = $self->$orig( devel => $devel );

    $env = $self->_load_env($env);

    $self->{env} = $env;

    $self->{name} = lc( ref $self ) =~ s/::/-/smgr;

    # create CDN object
    $self->{cdn} = Pcore::CDN->new( $self->{env}->{cdn} ) if $self->{env}->{cdn};

    return $self;
};

# ENVIRONMENT CONFIG
sub _load_env ( $self, $env = undef ) {
    my $effective_env = $self->default_env;

    my $merge = sub (@filename) {
        for my $filename (@filename) {
            return if !-f "$ENV->{DATA_DIR}/$filename";

            $self->_merge_env( $effective_env, P->cfg->read( "$ENV->{DATA_DIR}/$filename", params => { DATA_DIR => $ENV->{DATA_DIR} } ) );
        }

        return;
    };

    $merge->( '.env.yaml', '.env.local.yaml' );

    if ( $self->{devel} ) {
        $merge->( '.env.devel.yaml', '.env.devel.local.yaml' );
    }
    else {
        $merge->( '.env.prod.yaml', '.env.prod.local.yaml' );
    }

    $self->_merge_env( $effective_env, $env ) if $env;

    return $effective_env;
}

sub _merge_env ( $self, $env1, $env2 ) {
    P->hash->merge( $env1, $env2 );

    return;
}

sub default_env ($self) {
    my $env = {

        # server
        server => {
            default => {
                namespace   => undef,
                listen      => undef,
                server_name => [],
            },
        },

        # api
        api => {
            backend            => undef,
            auth_workers       => undef,
            argon2_time        => 3,
            argon2_memory      => '64M',
            argon2_parallelism => 1,
        },
    };

    return $env;
}

# PERMISSIONS
sub get_permissions ($self) {
    return $PERMS;
}

# LOCALES
sub get_locales ($self) {
    return $LOCALES;
}

sub get_default_locale ( $self, $req ) {
    return 'en';
}

# RUN
around run => sub ( $orig, $self ) {

    # create API object
    $self->{api} = P->class->load( 'API', ns => ref $self )->new( {
        $self->{env}->{api}->%*,
        app => $self,
        db  => $self->{env}->{db},
    } );

    # create node
    # TODO when to use node???
    if (1) {
        require Pcore::Node;

        my $node_req = ${ ref($self) . '::NODE_REQUIRES' };

        my $requires = defined $node_req ? { $node_req->%* } : {};

        # TODO fix condition for all backend types, should be true for local backends
        $requires->{'Pcore::App::API::Node'} = undef if $self->{api}->{db} && !defined $self->{api}->{backend};

        $self->{node} = Pcore::Node->new( {
            type     => ref $self,
            requires => $requires,
            server   => $self->{env}->{node}->{server},
            listen   => $self->{env}->{node}->{listen},
            on_event => do {
                if ( $self->can('NODE_ON_EVENT') ) {
                    sub ( $node, $ev ) {
                        $self->NODE_ON_EVENT($ev);

                        return;
                    };
                }
            },
            on_rpc => do {
                if ( $self->can('NODE_ON_RPC') ) {
                    sub ( $node, $req, $tx ) {
                        $self->NODE_ON_RPC( $req, $tx );

                        return;
                    };
                }
            },
        } );
    }

    # init api
    my $res = $self->{api}->init;
    say 'API initialization ... ' . $res;
    exit 3 if !$res;

    # create HTTP routers
    for my $name ( sort keys $self->{env}->{server}->%* ) {
        print qq[Scanning HTTP controllers "$name" ... ];

        $self->{router}->{$name} = Pcore::App::Router->new( {
            app       => $self,
            namespace => $self->{env}->{server}->{$name}->{namespace},
        } );

        $self->{router}->{$name}->init;

        say 'done';
    }

    $res = $self->$orig;
    exit 3 if !$res;

    # start HTTP servers
    for my $name ( sort keys $self->{env}->{server}->%* ) {
        $self->{env}->{server}->{$name}->{listen} ||= "/var/run/$self->{name}-$name.sock";

        my $http_server = Pcore::HTTP::Server->new( {
            listen     => $self->{env}->{server}->{$name}->{listen},
            on_request => $self->{router}->{$name},
        } );

        $self->{server}->{$name} = $http_server;

        say qq[Listen "$name": $http_server->{listen}];
    }

    say qq[App "$self->{name}" started];

    return;
};

# NGINX
sub run_nginx ($self) {
    my $nginx = $self->{nginx} = Pcore::API::Nginx->new;

    $nginx->remove_vhosts;

    my $has_server_name;

    for my $vhost_name ( sort keys $self->{env}->{server}->%* ) {
        my $vhost_params = $self->get_nginx_vhost_params($vhost_name);

        $nginx->add_vhost( $vhost_name, $vhost_params );    # if !$nginx->is_vhost_exists($vhost_name);

        if ( $self->{env}->{server}->{$vhost_name}->{server_name} && $self->{env}->{server}->{$vhost_name}->{server_name}->@* ) {
            $has_server_name = 1;

            $nginx->add_load_balancer_vhost( "$self->{name}-$vhost_name", $vhost_params );
        }
    }

    $nginx->add_default_vhost if $has_server_name;

    # SIGNUP -> nginx reload
    $SIG->{HUP} = AE::signal HUP => sub {
        Coro::async {
            $self->{nginx}->reload;

            return;
        };

        return;
    };

    $nginx->run;

    return;
}

sub get_nginx_vhost_params ( $self, $vhost_name ) {
    my $params = {
        app_name    => $self->{name},
        vhost_name  => $vhost_name,
        server_name => $self->{env}->{server}->{$vhost_name}->{server_name},
        data_dir    => $ENV->{DATA_DIR},
        upstream    => $self->{server}->{$vhost_name}->{listen}->to_nginx_upstream_server,
    };

    for my $path ( sort keys $self->{router}->{$vhost_name}->{path_ctrl}->%* ) {
        my $ctrl = $self->{router}->{$vhost_name}->{path_ctrl}->{$path};

        push $params->{locations}->@*, $ctrl->get_nginx_cfg;
    }

    push $params->{locations}->@*, $self->{cdn}->get_nginx_cfg if defined $self->{cdn};

    return $params;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App

=head1 SYNOPSIS

    my $app = Test::App->new( {    #
        cfg => {
            server => {            # passed directly to the Pcore::HTTP::Server constructor
                listen            => '*:80',    # 'unix:/var/run/test.sock'
                keepalive_timeout => 180,
            },
            router => {                         # passed directly to the Pcore::App::Router
                '*'         => undef,
                'host1.com' => 'Test::App::App1',
                'host2.com' => 'Test::App::App2',
            },
            api => {
                connect => "sqlite:$ENV->{DATA_DIR}/auth.sqlite",
                rpc => {
                    workers => undef,           # Maybe[Int]
                    argon   => {
                        argon2_time        => 3,
                        argon2_memory      => '64M',
                        argon2_parallelism => 1,
                    },
                },
            }
        },
        devel => $ENV->{cli}->{opt}->{devel},
    } );

    $app->run( sub ($res) {
        return;
    } );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 API METHOD PERMISSSIONS

=over

=item undef

allows to call API method without authentication.

=item "*"

allows any authenticated user.

=item ArrayRef[Str]

array of permissions names, that are allowed to run this method.

=back

=head1 SEE ALSO

=cut
