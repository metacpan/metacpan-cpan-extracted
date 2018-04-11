package Pcore::App;

use Pcore -role;
use Pcore::Nginx;
use Pcore::HTTP::Server;
use Pcore::App::Router;
use Pcore::App::API;

has app_cfg => ( is => 'ro', isa => HashRef, required => 1 );
has devel   => ( is => 'ro', isa => Bool,    default  => 0 );

has server => ( is => 'ro', isa => InstanceOf ['Pcore::HTTP::Server'], init_arg => undef );
has router => ( is => 'ro', isa => InstanceOf ['Pcore::App::Router'],  init_arg => undef );
has api => ( is => 'ro', isa => Maybe [ ConsumerOf ['Pcore::App::API'] ], init_arg => undef );

sub BUILD ( $self, $args ) {

    # apply default HTTP router settings
    $self->{app_cfg}->{router} //= { '*' => ref $self };

    # create HTTP router
    $self->{router} = Pcore::App::Router->new( {
        app   => $self,
        hosts => $self->{app_cfg}->{router},
    } );

    # create API object
    $self->{api} = Pcore::App::API->new($self);

    return;
}

around run => sub ( $orig, $self, $cb = undef ) {
    my $cv = AE::cv sub {

        # scan HTTP controllers
        print 'Scanning HTTP controllers ... ';
        $self->{router}->init;
        say 'done';

        $self->$orig( sub {

            # start HTTP server
            if ( defined $self->{app_cfg}->{server}->{listen} ) {
                $self->{server} = Pcore::HTTP::Server->new( {
                    $self->{app_cfg}->{server}->%*,    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]
                    app => $self->{router}
                } );

                $self->{server}->run;

                say qq[Listen: $self->{app_cfg}->{server}->{listen}];
            }

            say qq[App "@{[ref $self]}" started];

            $cb->($self) if $cb;

            return;
        } );

        return;
    };

    if ( $self->{api} ) {

        # connect api
        $self->{api}->init( sub ($res) {
            say 'API initialization ... ' . $res;

            exit 3 if !$res;

            $cv->send;

            return;
        } );
    }
    else {

        # die if API controller found, but no API server provided
        die q[API is required] if $self->{router}->{host_api_path} && !$self->{api};

        $cv->send;
    }

    return $self;
};

sub api_call ( $self, @args ) {
    my $auth = bless { app => $self }, 'Pcore::App::API::Auth';

    $auth->api_call(@args);

    return;
}

sub nginx_cfg ($self) {
    my $www_storage = $ENV->share->get_storage('www');

    my $params = {
        name              => lc( ref $self ) =~ s/::/-/smgr,
        data_dir          => $ENV->{DATA_DIR},
        www_root_dir      => $www_storage ? $www_storage->[0] : undef,      # TODO
        default_server    => 1,                                             # generate default server config
        nginx_default_key => $ENV->share->get('/data/nginx/default.key'),
        nginx_default_pem => $ENV->share->get('/data/nginx/default.pem'),
        upstream          => $self->{app_cfg}->{server}->{listen},
    };

    for my $host ( keys $self->{router}->{_path_class_cache}->%* ) {
        my $host_name;

        if ( $host eq '*' ) {
            $params->{default_server} = 0;

            $host_name = q[""];
        }
        else {
            $host_name = $host;
        }

        for my $path ( keys $self->{router}->{_path_class_cache}->{$host}->%* ) {
            my $ctrl = $self->{router}->{_path_class_cache}->{$host}->{$path};

            push $params->{host}->{$host_name}->{location}->@*, $ctrl->get_nginx_cfg;
        }
    }

    return P->tmpl->new->render( $self->{app_cfg}->{server}->{ssl} ? 'nginx/host_conf.nginx' : 'nginx/host_conf_no_ssl.nginx', $params );
}

sub start_nginx ($self) {
    $self->{nginx} = Pcore::Nginx->new;

    $self->{nginx}->add_vhost( 'vhost', $self->nginx_cfg ) if !$self->{nginx}->is_vhost_exists('vhost');

    # SIGNUP -> nginx reload
    $SIG->{HUP} = AE::signal HUP => sub {
        kill 'HUP', $self->{nginx}->proc->pid || 0;

        return;
    };

    $self->{nginx}->run;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App

=head1 SYNOPSIS

    my $app = Test::App->new( {    #
        app_cfg => {
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
                connect => "sqlite:$ENV->{DATA_DIR}auth.sqlite",
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
        devel => $ENV->cli->{opt}->{devel},
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

array of roles names, that are allowed to run this method.

=back

=head1 SEE ALSO

=cut
