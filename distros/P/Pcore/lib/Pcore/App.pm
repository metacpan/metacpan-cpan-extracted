package Pcore::App;

use Pcore -role;
use Pcore::HTTP::Server;
use Pcore::App::Router;
use Pcore::App::API;

has app_cfg => ( is => 'ro', isa => HashRef, required => 1 );
has devel   => ( is => 'ro', isa => Bool,    default  => 0 );

has server => ( is => 'ro', isa => InstanceOf ['Pcore::HTTP::Server'], init_arg => undef );
has router => ( is => 'ro', isa => InstanceOf ['Pcore::App::Router'],  init_arg => undef );
has api => ( is => 'ro', isa => Maybe [ ConsumerOf ['Pcore::App::API'] ], init_arg => undef );

sub BUILD ( $self, $args ) {

    # create HTTP router
    $self->{app_cfg}->{router} //= { '*' => ref $self };

    $self->{router} = Pcore::App::Router->new( {
        app   => $self,
        hosts => $self->{app_cfg}->{router},
    } );

    # init api
    $self->{api} = Pcore::App::API->new($self) if $self->{app_cfg}->{api}->{connect};

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
            $self->{server} = Pcore::HTTP::Server->new( {
                $self->{app_cfg}->{server}->%*,    ## no critic qw[ValuesAndExpressions::ProhibitCommaSeparatedStatements]
                app => $self->{router}
            } );

            $self->{server}->run;

            say qq[Listen: $self->{app_cfg}->{server}->{listen}];
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
