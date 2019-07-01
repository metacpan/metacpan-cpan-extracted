package Pcore::App::API;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_arrayref];
use Package::Stash::XS qw[];

has app => ( required => 1 );    # ConsumerOf ['Pcore::App']

has method => ( init_arg => undef );    # HashRef
has obj    => ( init_arg => undef );    # HashRef

# TODO https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md

sub init ($self) {
    print 'Scanning API classes ... ';

    my $method = {};

    # index permissions
    my $permissions = { map { $_ => 1 } $self->{app}->get_permissions->@* };

    my $ns_path = ( ref( $self->{app} ) =~ s[::][/]smgr ) . '/API';

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
        for my $file ( ( P->path("$inc/$ns_path")->read_dir( max_depth => 0, is_dir => 0 ) // [] )->@* ) {

            # .pm file
            if ( $file =~ s/[.]pm\z//sm ) {

                # API class must be located in V\d+ directory
                return if $file !~ m[\Av\d+/]sm;

                $class->{$file} = "$ns_path/$file" =~ s[/][::]smgr;
            }
        }
    }

    my $MODIFY_CODE_ATTRIBUTES = sub ( $pkg, $ref, @attrs ) {
        my @bad;

        for my $attr (@attrs) {
            if ( $attr =~ /(Permissions) [(] ([^)]*) [)]/smxx ) {
                my ( $attr, $val ) = ( $1, $2 );

                if ( $attr eq 'Permissions' ) {

                    # parse args
                    my @val = split /\s*,\s*/sm, $val;

                    # dequote
                    for (@val) {s/['"]//smg}

                    $val = \@val;
                }

                ${"$pkg\::_API_MAP"}->{$ref}->{ lc $attr } = $val;
            }
            else {
                push @bad, $attr;
            }
        }

        return @bad;
    };

    for my $class_path ( sort keys $class->%* ) {
        my $class_name = $class->{$class_path};

        my $attrs = do {
            local *{"$class_name\::MODIFY_CODE_ATTRIBUTES"} = $MODIFY_CODE_ATTRIBUTES;

            eval { P->class->load($class_name) };

            if ($@) {
                say qq[Can't load API class "$class_name": $@];

                exit 3;
            }

            ${"$class_name\::_API_MAP"};
        };

        die qq["$class_name" must be an instance of "Pcore::App::API::Base"] if !$class_name->isa('Pcore::App::API::Base');

        # prepare API object route
        $class_path =~ s/\AV/v/sm;

        # create API object and store in cache
        my $obj = $self->{obj}->{$class_name} = $class_name->new( { app => $self->{app} } );

        # parse API version
        my ($version) = $class_path =~ /\Av(\d+)/sm;

        # scan api methods
        for my $method_name ( grep {/\AAPI_/sm} Package::Stash::XS->new($class_name)->list_all_symbols('CODE') ) {

            # get method permissions
            my $perms = do {
                my $ref = *{"$class_name\::$method_name"}{CODE};

                $attrs->{$ref}->{permissions} // ${"$class_name\::API_NAMESPACE_PERMISSIONS"};
            };

            my $local_method_name = $method_name;

            $method_name =~ s/\AAPI_//sm;

            my $method_id = qq[/$class_path/$method_name];

            $method->{$method_id} = {
                id                => $method_id,
                version           => "v$version",
                class_name        => $class_name,
                class_path        => "/$class_path",
                method_name       => $method_name,
                local_method_name => $local_method_name,
                permissions       => $perms,
            };

            # check method permissions
            if ( $method->{$method_id}->{permissions} ) {

                # convert to ArrayRef
                $method->{$method_id}->{permissions} = [ $method->{$method_id}->{permissions} ] if !is_plain_arrayref $method->{$method_id}->{permissions};

                # methods permissions are empty
                if ( !$method->{$method_id}->{permissions}->@* ) {
                    $method->{$method_id}->{permissions} = undef;
                }

                # check permissions
                else {
                    for my $permission ( $method->{$method_id}->{permissions}->@* ) {

                        # expand "*"
                        if ( $permission eq q[*] ) {
                            $method->{$method_id}->{permissions} = [ keys $permissions->%* ];

                            last;
                        }

                        if ( !exists $permissions->{$permission} ) {
                            die qq[Invalid API method permission "$permission" for method "$method_id"];
                        }
                    }
                }
            }
        }
    }

    $self->{method} = $method;

    say 'done';

    return res 200;
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
## |    3 | 14                   | Subroutines::ProhibitExcessComplexity - Subroutine "init" with high complexity score (23)                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 89                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 153, 159             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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
