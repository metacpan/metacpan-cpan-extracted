package Pcore::Ext v0.19.1;

use Pcore -dist, -const;
use Pcore::Ext::Base;
use Pcore::Ext::Context;
use Pcore::Util::Scalar qw[is_ref];
use Package::Stash::XS qw[];

our ( $APP, $EXT );
our $SCANNED;

sub load_class ( $self, $module_path, $full_path, $reload ) {
    my $namespace = ( $module_path =~ s/[.]pm\z//smr ) =~ s[/][::]smgr;

    # reload
    if ( exists $INC{$module_path} ) {
        return if !$reload;

        my $code = P->file->read_bin($full_path);

        $code =~ s/^use Pcore.+?$//smg;

        no warnings qw[redefine];

        *{"$namespace\::const"} = sub : prototype(\[$@%]@) { };

        eval $code;    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
    }

    # load
    else {

        # configure namespace
        push @{"$namespace\::ISA"}, 'Pcore::Ext::Base';
        *{"$namespace\::raw"}  = sub : prototype($) {die};
        *{"$namespace\::func"} = sub                {die};
        *{"$namespace\::cdn"}  = \undef;
        *{"$namespace\::api"}  = \undef;
        *{"$namespace\::class"} = \undef;
        *{"$namespace\::type"}  = \undef;

        do $full_path;
    }

    die $@ if $@;

    $INC{$module_path} = $full_path;    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    return;
}

sub scan ( $self, $app, @namespaces ) {
    return if $SCANNED;

    $SCANNED = 1;

    my $tree;

    # scan namespaces
    for my $root_namespace ( @namespaces, 'Pcore::Ext::Lib' ) {
        my $root_namespace_path = $root_namespace =~ s[::][/]smgr;

        for my $inc_path ( grep { !is_ref $_ } @INC ) {
            my $modules = P->path("$inc_path/$root_namespace_path")->read_dir( abs => 0, is_dir => 0, max_depth => 0 );

            next if !$modules;

            for my $module ( $modules->@* ) {
                next if $module !~ s/[.]pm\z//sm;

                my $namespace = "$root_namespace_path/$module" =~ s[/][::]smgr;

                # load class
                my $context_cfg = do {
                    $self->load_class( "$root_namespace_path/$module.pm", "$inc_path/$root_namespace_path/$module.pm", 0 );

                    {   ext_type    => ${"$namespace\::EXT_TYPE"},
                        ext_ver     => ${"$namespace\::EXT_VER"},
                        ext_api_ver => ${"$namespace\::EXT_API_VER"},
                        ext_map     => ${"$namespace\::_EXT_MAP"},
                    };
                };

                my $context_path = "$root_namespace_path/$module";

                for my $name ( grep {/\AEXT_/sm} Package::Stash::XS->new($namespace)->list_all_symbols('CODE') ) {
                    my $ref = *{"$namespace\::$name"}{CODE};

                    $name =~ s/\AEXT_//sm;

                    $tree->{"/$context_path/$name"} = {
                        namespace       => $namespace,
                        generator       => $name,
                        class_path      => "/$context_path/$name",
                        context_path    => "/$context_path/",
                        extend          => $context_cfg->{ext_map}->{$ref}->{extend},
                        override        => $context_cfg->{ext_map}->{$ref}->{override},
                        api_ver         => $context_cfg->{ext_api_ver},
                        ext_class_name  => $context_cfg->{ext_map}->{$ref}->{define} // "$context_path/$name" =~ s[/][.]smgr,
                        alias_namespace => $context_cfg->{ext_map}->{$ref}->{type},
                        ext_framework   => $context_cfg->{ext_map}->{$ref}->{ext},
                    };
                }

                # detect application
                if ( ( my $app_name ) = $context_path =~ m[\A$root_namespace_path/([^/]+)\z]sm ) {
                    die qq[Ext app "/$context_path" requires \$EXT_TYPE to be defined] if !$context_cfg->{ext_type};
                    die qq[Ext app "/$context_path" requires \$EXT_VER to be defined]  if !$context_cfg->{ext_ver};
                    die qq[Viewport is not defined]                                    if !$tree->{"/$context_path/viewport"};

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
    $self->_resolve_extend( $app, $tree );

    $self->_build_classes( $app, $tree );

    $self->_build_apps($tree);

    $self->_build_ext($tree);

    return;
}

sub _resolve_extend ( $self, $app, $tree ) {
    my ( $extjs, $processed_classes );

    my $resolve_extend = sub ($class) {
        return if $processed_classes->{ $class->{class_path} };

        $processed_classes->{ $class->{class_path} } = 1;

        # extend is defined
        if ( $class->{extend} ) {

            # extend is ExtJS class name
            if ( $class->{extend} =~ /[.]/sm ) {

                # alias namespace is not defined, try to inherit from the base class
                # only for app classes, because lib classes doesn't contains framework information
                if ( !$class->{alias_namespace} && $class->{app_name} ) {
                    my $ext_ver  = $APP->{ $class->{app_name} }->{ext_ver};
                    my $ext_type = $APP->{ $class->{app_name} }->{ext_type};

                    # load extjs config, if not loaded
                    $extjs->{$ext_ver}->{$ext_type} = $ENV->{share}->read_cfg("/Pcore-Ext/data/ext/$ext_ver/$ext_type.json") if !exists $extjs->{$ext_ver}->{$ext_type};

                    # base class is not exists
                    die qq[Invalid ExtJS class name "$class->{extend}"] if !exists $extjs->{$ext_ver}->{$ext_type}->{ $class->{extend} };

                    # inherit alias namespace from the base class
                    $class->{alias_namespace} = $extjs->{$ext_ver}->{$ext_type}->{ $class->{extend} };
                }
            }

            # extend is internal class path
            else {
                my $ctx = Pcore::Ext::Context->new(
                    app  => $app,
                    tree => $tree,
                    ctx  => $class,
                );

                my $base_class = $ctx->_resolve_class_path( $class->{extend} );

                # register requires
                $class->{requires}->{ $base_class->{class_path} } = undef;
                $class->{extend} = $base_class->{ext_class_name};

                # alias namespace is not defined, try to inherit from the base class
                if ( !$class->{alias_namespace} ) {
                    __SUB__->($base_class);

                    $class->{alias_namespace} = $base_class->{alias_namespace};
                }
            }
        }

        # generate alias, if alias namespace is defined
        $class->{alias} = $class->{class_path} =~ s[/][_]smgr if $class->{alias_namespace};

        return;
    };

    for my $class ( values $tree->%* ) {
        $resolve_extend->($class);
    }

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

            for my $require ( sort keys $class->{requires}->%* ) {

                # skip external deps
                next if !exists $tree->{$require};

                __SUB__->( $tree->{$require} );
            }

            # all deps processed, mark node as "black"
            $processed_class{ $class->{class_path} } = 2;

            # add content
            $app->{content} .= "$class->{content}->$*;\n";

            # add app l10n msgid
            $app->{l10n}->@{ keys $class->{l10n}->%* } = ();

            # add api map
            for my $method_id ( sort keys $class->{api}->%* ) {
                next if exists $added_methods->{$method_id};

                $added_methods->{$method_id} = undef;

                push $app->{api}->{ delete $class->{api}->{$method_id}->{action} }->@*, $class->{api}->{$method_id};
            }

            return;
        };

        # sort deps
        for my $class ( sort { $a->{ext_class_name} cmp $b->{ext_class_name} } grep { defined $_->{app_name} && $_->{app_name} eq $app->{name} } values $tree->%* ) {
            $add_deps->($class);
        }
    }

    return;
}

sub _build_ext ( $self, $tree ) {
    for my $class ( sort { $a->{ext_class_name} cmp $b->{ext_class_name} } grep { $_->{ext_framework} } values $tree->%* ) {
        if ( $class->{ext_framework} eq 'core' ) {
            $EXT->{modern} .= "$class->{content}->$*;\n";

            $EXT->{classic} .= "$class->{content}->$*;\n";
        }
        elsif ( $class->{ext_framework} eq 'modern' ) {
            $EXT->{modern} .= "$class->{content}->$*;\n";
        }
        elsif ( $class->{ext_framework} eq 'classic' ) {
            $EXT->{classic} .= "$class->{content}->$*;\n";
        }
        else {
            die q[Invalid value for "Ext" attribute];
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
## |    3 | 12                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 27                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 109                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 25                   | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
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
