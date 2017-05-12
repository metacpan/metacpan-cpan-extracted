package Pcore::App::API::Map;

use Pcore -class;

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has method => ( is => 'lazy', isa => HashRef, init_arg => undef );
has obj => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

# TODO https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md

sub _build_method ($self) {
    my $method = {};

    my $ns_path = ( ref( $self->app ) =~ s[::][/]smgr ) . '/API';

    my $class;

    # scan %INC
    for my $class_path ( keys %INC ) {

        # API class must be located in V\d+ directory
        next if $class_path !~ m[\A$ns_path/V\d+/]sm;

        # remove .pm suffix
        my $class_name = $class_path =~ s/[.]pm\z//smr;

        $class_name =~ s[/][::]smg;

        $class->{$class_path} = $class_name;
    }

    # scan filesystem namespace, find and preload controllers
    for my $inc ( grep { !ref } @INC ) {
        if ( -d "$inc/$ns_path" ) {
            my $guard = P->file->chdir("$inc/$ns_path");

            P->file->find(
                "$inc/$ns_path",
                abs => 0,
                dir => 0,
                sub ($path) {

                    # .pm file
                    if ( $path->suffix eq 'pm' ) {

                        # API class must be located in V\d+ directory
                        return if $path !~ m[\AV\d+/]sm;

                        my $route = $path->dirname . $path->filename_base;

                        $class->{$route} = "$ns_path/$route" =~ s[/][::]smgr;
                    }

                    return;
                }
            );
        }
    }

    for my $class_path ( sort keys $class->%* ) {
        my $class_name = $class->{$class_path};

        P->class->load($class_name);

        die qq["$class_name" must be a consumer of "Pcore::App::API::Role"] if !$class_name->does('Pcore::App::API::Role');

        # prepare API object route
        $class_path =~ s/\AV/v/sm;

        # create API object and store in cache
        my $obj = $self->{obj}->{$class_name} = $class_name->new( { app => $self->app } );

        my $obj_map = $obj->api_map;

        # parse API version
        my ($version) = $class_path =~ /\Av(\d+)/sm;

        # validate obj API map
        for my $method_name ( sort keys $obj_map->%* ) {
            my $method_id = qq[/$class_path/$method_name];

            my $local_method_name = "API_$method_name";

            $method->{$method_id} = {
                $obj_map->{$method_name}->%*,
                id                => $method_id,
                version           => "v$version",
                class_name        => $class_name,
                class_path        => "/$class_path",
                method_name       => $method_name,
                local_method_name => $local_method_name,
            };

            # method should exists
            die qq[API method "$local_method_name" is not exists. By convention api methods should be prefixed with "API_" prefix] if !$obj->can($local_method_name);

            # method description is required
            die qq[API method "$method_id" requires description] if !$method->{$method_id}->{desc};

            # check method permissions
            if ( $method->{$method_id}->{permissions} ) {

                # convert method permissions to ArrayRef
                $method->{$method_id}->{permissions} = [ $method->{$method_id}->{permissions} ] if !ref $method->{$method_id}->{permissions};

                # methods permissions are empty
                if ( !$method->{$method_id}->{permissions}->@* ) {
                    $method->{$method_id}->{permissions} = undef;
                }

                # check permissions
                else {
                    for my $role ( $method->{$method_id}->{permissions}->@* ) {

                        # expand "*"
                        if ( $role eq q[*] ) {
                            $method->{$method_id}->{permissions} = [ keys $self->app->api->roles->%* ];

                            last;
                        }

                        if ( !exists $self->app->api->roles->{$role} ) {
                            die qq[Invalid API method permission "$role" for method "$method_id"];
                        }
                    }
                }
            }
        }
    }

    return $method;
}

sub get_method ( $self, $method_id ) {
    return $self->{method}->{$method_id};
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 117, 123             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 118, 123             | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Map

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
