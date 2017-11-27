package Pcore::App;

use Pcore -role;
use Pcore::HTTP::Server;
use Pcore::App::Router;

has name => ( is => 'lazy', isa => Str );
has desc => ( is => 'lazy', isa => Str );

# API settings
has auth => ( is => 'ro', isa => Maybe [Str] );    # db, http or wss uri

has devel => ( is => 'ro', isa => Bool, default => 0 );

# HTTP server settings
has listen => ( is => 'ro', isa => Str, required => 1 );
has keepalive_timeout => ( is => 'ro', isa => PositiveOrZeroInt, default => 60 );

has instance_auth_path => ( is => 'lazy', isa => Str,     init_arg => undef );    # app instance local config path
has instance_auth      => ( is => 'lazy', isa => HashRef, init_arg => undef );    # app instance local config

has id             => ( is => 'ro', isa => Str, init_arg => undef );              # app id
has instance_id    => ( is => 'ro', isa => Str, init_arg => undef );              # app instance id
has instance_token => ( is => 'ro', isa => Str, init_arg => undef );              # app instance token

has version => ( is => 'lazy', isa => InstanceOf ['version'],            init_arg => undef );    # app instance version
has router  => ( is => 'ro',   isa => InstanceOf ['Pcore::App::Router'], init_arg => undef );
has api => ( is => 'lazy', isa => Maybe [ ConsumerOf ['Pcore::App::API'] ], init_arg => undef );
has http_server => ( is => 'lazy', isa => InstanceOf ['Pcore::HTTP::Server'], init_arg => undef );

sub BUILD ( $self, $args ) {

    # create HTTP router
    $self->{router} = Pcore::App::Router->new( { hosts => $args->{hosts} // { '*' => ref $self }, app => $self } );

    return;
}

sub _build_name ($self) {
    return ref($self) =~ s[::][-]smgr;
}

# TODO get description from POD abstract or die
sub _build_desc ($self) {
    return 'test application';
}

sub _build_instance_auth_path ($self) {
    return ( $ENV->{DATA_DIR} // q[] ) . ( $self->name =~ s/::/-/smgr ) . '.json';
}

sub _build_instance_auth ($self) {
    if ( -f $self->instance_auth_path ) {
        return P->cfg->load( $self->instance_auth_path );
    }
    else {
        return {};
    }
}

sub _build_version ($self) {
    no strict qw[refs];

    return ${ ref($self) . '::VERSION' };
}

sub _build_api ($self) {
    my $api_class = ref($self) . '::API';

    if ( !exists $INC{ $api_class =~ s[::][/]smgr . '.pm' } ) {
        return if !P->class->find($api_class);

        P->class->load($api_class);
    }

    die qq[API class "$api_class" is not consumer of "Pcore::App::API"] if !$api_class->does('Pcore::App::API');

    return $api_class->new( { app => $self } );
}

sub _build_http_server ($self) {
    return Pcore::HTTP::Server->new(
        {   listen            => $self->listen,
            keepalive_timeout => $self->keepalive_timeout,
            app               => $self->router,
        }
    );
}

# TODO init appliacation
around run => sub ( $orig, $self, $cb = undef ) {
    my $cv = AE::cv sub {
        $self->$orig(
            sub {

                # start HTTP server
                $self->http_server->run;

                say qq[Listen: @{[$self->listen]}] if $self->listen;
                say qq[App "@{[$self->name]}" started];

                $cb->($self) if $cb;

                return;
            }
        );

        return;
    };

    # init api
    $self->api->init_api if $self->api;

    # scan router classes
    print 'Scanning HTTP controllers ... ';
    $self->router->map;
    say 'done';

    if ( $self->api ) {

        # connect api
        $self->api->connect_api(
            sub ($status) {
                exit if !$status;

                $cv->send;

                return;
            }
        );
    }
    else {

        # die if API controller found, but no API server provided
        die q[API is required] if $self->{router}->{host_api_path} && !$self->api;

        $cv->send;
    }

    return $self;
};

# this method can be overloaded in subclasses
sub run ($self) {
    return;
}

sub store_instance_auth ($self) {
    P->cfg->store( $self->instance_auth_path, $self->instance_auth );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
