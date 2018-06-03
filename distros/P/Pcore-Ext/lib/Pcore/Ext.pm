package Pcore::Ext v0.16.0;

use Pcore -dist, -const;
use Pcore::Ext::Base;
use Pcore::Ext::Context;
use Pcore::Resources;
use Pcore::Util::Scalar qw[is_ref];

our $APP;
my $SCANNED;

# TODO split by steps
sub scan ( $self, $app, @namespaces ) {
    return if $SCANNED;

    $SCANNED = 1;

    my $tree;

    # scan namespaces
    for my $root_namespace (@namespaces) {
        my $root_namespace_path = $root_namespace =~ s[::][/]smgr;

        for my $inc_path ( grep { !is_ref $_ } @INC ) {
            P->file->find(
                "$inc_path/$root_namespace_path/",
                abs => 0,
                dir => 0,
                sub ($path) {
                    if ( $path->suffix eq 'pm' ) {

                        my $namespace = ( "$root_namespace_path/" . $path =~ s/[.]pm\z//smr ) =~ s[/][::]smgr;

                        # load class
                        my $context_cfg = do {
                            no strict qw[refs];

                            push @{"$namespace\::ISA"}, 'Pcore::Ext::Base';

                            P->class->load($namespace);

                            {   ext_type    => ${"$namespace\::EXT_TYPE"},
                                ext_ver     => ${"$namespace\::EXT_VER"},
                                ext_api_ver => ${"$namespace\::EXT_API_VER"},
                                ext_map     => ${"$namespace\::_EXT_MAP"},
                            };
                        };

                        die qq[\$EXT_MAP is not defined for "$namespace"] if !$context_cfg->{ext_map};

                        my $context_path = "$root_namespace_path/" . $path =~ s/[.]pm\z//smr;

                        while ( my ( $name, $extend ) = each $context_cfg->{ext_map}->%* ) {
                            $tree->{"/$context_path/$name"} = {
                                namespace      => $namespace,
                                generator      => $name,
                                class_path     => "/$context_path/$name",
                                context_path   => "/$context_path/",
                                extend         => $extend,
                                api_ver        => $context_cfg->{ext_api_ver},
                                ext_class_name => "$context_path/$name" =~ s[/][.]smgr,
                            };
                        }

                        # detect application
                        if ( ( my $app_name ) = $context_path =~ m[\A$root_namespace_path/([^/]+)\z]sm ) {
                            die qq[Ext app "/$context_path" requires \$EXT_TYPE to be defined] if !$context_cfg->{ext_type};
                            die qq[Ext app "/$context_path" requires \$EXT_VER to be defined]  if !$context_cfg->{ext_ver};
                            die qq[Viewport is not defined]                                    if !$context_cfg->{ext_map}->{viewport};

                            $APP->{$app_name} = {
                                name         => $app_name,
                                context_path => "/$context_path/",
                                ext_type     => $context_cfg->{ext_type},
                                ext_ver      => $context_cfg->{ext_ver},
                                api_ver      => $context_cfg->{ext_api_ver},
                                viewport     => "$context_path/viewport" =~ s[/][.]smgr,
                            };
                        }
                    }

                    return;
                }
            );

        }
    }

    # distribute classes between apps
    for my $app_name ( keys $APP->%* ) {
        my $app_context_path_re = qr[\A$APP->{$app_name}->{context_path}]sm;

        for my $class ( grep { $_->{class_path} =~ $app_context_path_re } values $tree->%* ) {
            $class->{app_name} = $app_name;
            $class->{app_path} = $APP->{$app_name}->{context_path};
            $class->{api_ver} //= $APP->{$app_name}->{api_ver};
        }
    }

    # resolve extend, set alias namespace, alias
    my ( $extjs, $resolved_extend );

    my $resolve_extend = sub ($class) {
        return if $resolved_extend->{ $class->{class_path} };

        $resolved_extend->{ $class->{class_path} } = 1;

        return if !$class->{extend};

        # this is ExtJS class name
        if ( $class->{extend} =~ /[.]/sm ) {

            my $ext_ver  = $APP->{ $class->{app_name} }->{ext_ver};
            my $ext_type = $APP->{ $class->{app_name} }->{ext_type};

            # load extjs config, if not loaded
            $extjs->{$ext_ver}->{$ext_type} = $ENV->{share}->read_cfg( 'Pcore-Resources', 'data', "ext-$ext_ver/$ext_type.json" ) if !exists $extjs->{$ext_ver}->{$ext_type};

            die qq[Invalid ExtJS class name "$class->{extend}"] if !exists $extjs->{$ext_ver}->{$ext_type}->{ $class->{extend} };

            $class->{alias_namespace} = $extjs->{$ext_ver}->{$ext_type}->{ $class->{extend} };
        }

        # this is internal class path
        else {
            my $extend_class = $self->_resolve_class_path( $class, $class->{extend} );

            die qq[Class path "$class->{extend}" can't be resolved] if !exists $tree->{$extend_class};

            __SUB__->( $tree->{$extend_class} );

            $class->{extend} = $tree->{$extend_class}->{ext_class_name};

            $class->{alias_namespace} = $tree->{$extend_class}->{alias_namespace} if $tree->{$extend_class}->{alias_namespace};
        }

        # set alias, if alias namespace is exists
        $class->{alias} = $class->{class_path} =~ s[/][_]smgr if $class->{alias_namespace};

        return;
    };

    for my $class ( values $tree->%* ) {
        $resolve_extend->($class);
    }

    $self->_build_classes( $app, $tree );

    $self->_build_apps($tree);

    return;
}

sub _build_classes ( $self, $app, $tree ) {
    for my $class ( values $tree->%* ) {
        Pcore::Ext::Context->new(
            app  => $app,
            tree => $tree,
            ctx  => $class,
        )->to_js;
    }

    return;
}

sub _build_apps ( $self, $tree ) {
    for my $app ( values $APP->%* ) {
        my ( %processed_class, $added_methods );

        # topologically sort deps tree
        my $add_deps = sub ($class) {
            if ( !exists $processed_class{ $class->{class_path} } ) {

                # mark node as "gray"
                $processed_class{ $class->{class_path} } = 1;
            }
            elsif ( $processed_class{ $class->{class_path} } == 1 ) {

                # entered to the "gray" node, this is cyclic deps
                die q[Cyclic dependency found];
            }
            else {

                # entered to the "black" node
                return;
            }

            for my $require ( keys $class->{requires}->%* ) {

                # skip external deps
                next if !exists $tree->{$require};

                __SUB__->( $tree->{$require} );
            }

            # all deps processed, mark node as "black"
            $processed_class{ $class->{class_path} } = 2;

            # add content
            $app->{content} .= "$class->{content}->$*;\n";

            # add api map
            for my $method_id ( keys $class->{api}->%* ) {
                next if exists $added_methods->{$method_id};

                $added_methods->{$method_id} = undef;

                push $app->{api}->{ delete $class->{api}->{$method_id}->{action} }->@*, $class->{api}->{$method_id};
            }

            # add locale domains
            $app->{l10n_domain}->@{ keys $class->{l10n_domain}->%* } = ();

            return;
        };

        # sort deps
        for my $class ( sort { $b->{ext_class_name} cmp $a->{ext_class_name} } grep { $_->{app_name} eq $app->{name} } values $tree->%* ) {
            $add_deps->($class);
        }
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 13                   | Subroutines::ProhibitExcessComplexity - Subroutine "scan" with high complexity score (23)                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 69                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 218                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
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
