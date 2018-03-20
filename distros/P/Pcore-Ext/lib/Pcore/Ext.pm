package Pcore::Ext v0.13.3;

use Pcore -dist, -const;
use Pcore::Ext::Context;

our $SCANNED;

const our $NS => 'Pcore';

our $CFG = {
    app        => undef,
    class      => undef,
    perl_class => undef,
};

our $EXT;

sub SCAN ( $self, $app, $ext, $framework ) {
    return if $SCANNED;

    $SCANNED = 1;

    $EXT = $ext;

    my $namespaces;

    my $root_namespace  = ref($app) . '::Ext';
    my $root_path       = $root_namespace =~ s[::][/]smgr;
    my $l10n_class_name = 'L10n.' . ( ref($app) =~ s/:://smgr );

    for my $path ( grep { !ref } @INC ) {

        # scan Pcore::Ext::Class::
        if ( -d "$path/Pcore/Ext/Class/" ) {
            P->file->find(
                "$path/Pcore/Ext/Class/",
                abs => 0,
                dir => 0,
                sub ($path) {
                    if ( $path->suffix eq 'pm' ) {
                        my $class_name = $path =~ s/[.]pm\z//smgr =~ s[/][::]smrg;

                        $namespaces->{"Pcore::Ext::Class\::$class_name"} = {
                            is_app   => 0,
                            app_name => undef,
                        };
                    }

                    return;
                }
            );
        }

        # scan root namespace
        if ( -d "$path/$root_path/" ) {
            P->file->find(
                "$path/$root_path/",
                abs => 0,
                dir => 0,
                sub ($path) {
                    if ( $path->suffix eq 'pm' ) {
                        my $class_name = $path =~ s/[.]pm\z//smgr =~ s[/][::]smrg;

                        # register Ext app
                        if ( $class_name !~ /::/sm ) {
                            $namespaces->{"$root_namespace\::$class_name"} = {
                                is_app   => 1,
                                app_name => $class_name,
                            };

                            $CFG->{app}->{$class_name} = {
                                namespace       => "$root_namespace\::$class_name",
                                name            => $class_name,
                                l10n_class_name => $l10n_class_name,
                            };
                        }

                        # register Ext class
                        else {
                            my $ext_app_name = $class_name =~ s/::.*//smr;

                            $namespaces->{"$root_namespace\::$class_name"} = {
                                is_app   => 0,
                                app_name => $ext_app_name,
                            };
                        }
                    }

                    return;
                }
            );
        }
    }

    for my $namespace ( keys $namespaces->%* ) {
        P->class->load($namespace);

        # get EXT MAP
        my ( $ext_map, $ext_api_ver ) = do {
            no strict qw[refs];

            ( ${"$namespace\::EXT_MAP"}, ${"$namespace\::EXT_API_VER"} );
        };

        die qq[\$EXT_MAP is not definde in "$namespace"] if !defined $ext_map;

        # configure namespace
        my $namespace_cfg = $namespaces->{$namespace};

        # this is Ext app namespace
        if ( $namespace_cfg->{is_app} ) {

            # store api_ver in app cfg
            $CFG->{app}->{ $namespace_cfg->{app_name} }->{api_ver} = $ext_api_ver;

            # check, that viewport defined for Ext app
            die qq[Ext app "$namespace" requires viewport to be defined] if !$ext_map->{viewport};

            # store vireport class
            $CFG->{app}->{ $namespace_cfg->{app_name} }->{viewport} = "${NS}.${namespace}Viewport" =~ s/:://smgr;
        }
        else {

            # resolve app_namespace by app_name
            if ( $namespace_cfg->{app_name} ) {
                $namespace_cfg->{app_namespace} = $CFG->{app}->{ $namespace_cfg->{app_name} }->{namespace};

                undef $namespace_cfg->{app_name} if !$namespace_cfg->{app_namespace};
            }
        }

        for my $class ( keys $ext_map->%* ) {

            # check, that generator method is present
            my $method = 'EXT_' . $class;

            die qq[method "$method" is required but not defined in "$namespace"] if !$namespace->can($method);

            my $class_name = ucfirst $class;

            my $ext_class = "${NS}.${namespace}${class_name}" =~ s/:://smgr;

            $CFG->{class}->{$ext_class} = {
                class           => $ext_class,
                namespace       => $namespace,
                api_ver         => $ext_api_ver,
                root_namespace  => $root_namespace,
                app_namespace   => $namespace_cfg->{app_namespace},
                app_name        => $namespace_cfg->{app_name},
                generator       => $class,
                extend          => $ext_map->{$class},
                l10n_class_name => $l10n_class_name,
            };

            $CFG->{perl_class}->{"$namespace\::$class"} = $ext_class;
        }
    }

    # second pass, set app namespaces, set ext version, create aliases
    for my $class ( values $CFG->{class}->%* ) {

        # try to inherit api_ver from app
        if ( !$class->{api_ver} && $class->{app_name} ) {
            $class->{api_ver} = $CFG->{app}->{ $class->{app_name} }->{api_ver};
        }

        next if !$class->{extend};

        my $ctx = $self->_get_ctx( $class->{class}, $app, $framework );

        my $extend = $ctx->get_class( $class->{extend} );

        die qq[Can't resolve Ext extend "$class->{extend}" in "$class->{namespace}::$class->{generator}"] if !$extend;

        next if !$extend->{alias};

        # extract type from alias, alias_namespace.type
        $class->{alias_namespace} = $extend->{alias_namespace};

        $class->{type} = lc "${NS}.$class->{namespace}.$class->{generator}" =~ s/([.]|::)/-/smgr;

        $class->{alias} = "$extend->{alias_namespace}.$class->{type}";
    }

    # generate JS content
    for my $class ( values $CFG->{class}->%* ) {
        my $ctx = $self->_get_ctx( $class->{class}, $app, $framework );

        $class->{js} = $ctx->to_js;
    }

    # build ext apps
    for my $ext_app ( values $CFG->{app}->%* ) {
        my $added_methods;

        # build app content
        my %processed_class;

        # topologically sort deps tree
        my $add_deps = sub ($class_name) {
            if ( !exists $processed_class{$class_name} ) {

                # mark node as "gray"
                $processed_class{$class_name} = 1;
            }
            elsif ( $processed_class{$class_name} == 1 ) {

                # entered to the "gray" node, this is cyclic deps
                die q[Cyclic dependency found];
            }
            else {

                # entered to the "black" node
                return;
            }

            my $class_cfg = $CFG->{class}->{$class_name};

            for my $require ( keys $class_cfg->{requires}->%* ) {

                # skip external deps
                next if !exists $CFG->{class}->{$require};

                __SUB__->($require);
            }

            # all deps processed, mark node as "black"
            $processed_class{$class_name} = 2;

            # add content
            push $ext_app->{classes}->@*, $class_name;

            # add api map
            for my $method_id ( keys $class_cfg->{api}->%* ) {
                next if exists $added_methods->{$method_id};

                $added_methods->{$method_id} = undef;

                push $ext_app->{api}->{ delete $class_cfg->{api}->{$method_id}->{action} }->@*, $class_cfg->{api}->{$method_id};
            }

            # add locale domains
            $ext_app->{l10n_domain}->@{ keys $class_cfg->{l10n_domain}->%* } = ();

            return;
        };

        # sort deps
        for my $class ( sort { $b->{class} cmp $a->{class} } values $CFG->{class}->%* ) {
            next if ( $class->{app_namespace} // $class->{namespace} ) ne $ext_app->{namespace};

            $add_deps->( $class->{class} );
        }
    }

    return;
}

sub _get_ctx ( $self, $class, $app, $framework ) {
    my $ctx = $CFG->{class}->{$class};

    return if !$ctx;

    return Pcore::Ext::Context->new( { ctx => $ctx, framework => $framework, app => $app } );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 18                   | Subroutines::ProhibitExcessComplexity - Subroutine "SCAN" with high complexity score (35)                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 249                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
