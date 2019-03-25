package Pcore::Ext v0.21.1;

use Pcore -dist, -class, -const;
use Pcore::Util::Scalar qw[is_ref];
use Package::Stash::XS qw[];
use Pcore::Ext::App::Class;

has namespace => ( required => 1 );

has app           => ();       # maybe InstanceOf['Pcore::App']
has cdn           => ();       # maybe InstanceOf['Pcore::CDN']
has api_namespace => ();
has prefixes      => ();
has api_url       => '/api';

has classes   => ( init_arg => undef );    # HashRef
has requires  => ( init_arg => undef );    # HashRef
has api       => ( init_arg => undef );    # HashRef, used API methods
has l10n      => ( init_arg => undef );    # HashRef, used l10n msgid's
has build     => ( init_arg => undef );
has overrides => ( init_arg => undef );
has locales   => ( init_arg => undef );

has ext_type    => ( init_arg => undef );
has ext_ver     => ( init_arg => undef );
has ext_theme   => ( init_arg => undef );
has ext_api_ver => ( init_arg => undef );
has viewport    => ( init_arg => undef );    # viewport class name

const our $EXT_TYPE          => 'modern';    # modern, classic
const our $EXT_VER           => v6.7.0;
const our $EXT_THEME_CLASSIC => 'aria';
const our $EXT_THEME_MODERN  => 'material';
const our $EXT_API_VER       => 'v1';

our $FRAMEWORK;
our $MODULES;

sub BUILD ( $self, $args ) {
    $self->{api_namespace} //= $self->{namespace} =~ s/:://smgr;

    if ( defined $self->{app} ) {
        $self->{cdn} //= $self->{app}->{cdn};

        $self->{prefixes}->{pcore} //= 'Pcore/Ext/Lib';
        $self->{prefixes}->{dist}  //= ref( $self->{app} ) . '::Ext' =~ s[::][/]smgr;
        $self->{prefixes}->{app}   //= $self->{namespace} =~ s[::][/]smgr;
    }

    return;
}

# TODO reload
sub _load_module ( $self, $module ) {
    my $classes;

    if ( exists $MODULES->{$module} ) {
        for my $class ( keys $MODULES->{$module}->%* ) {
            $self->{classes}->{$class} = Pcore::Ext::App::Class->new( $MODULES->{$module}->{$class}->%*, app => $self );

            $classes->{$class} = 1;
        }
    }
    else {
        my $prefix = $module =~ s/[.]pm\z//smr;

        my $package = $prefix =~ s[/][::]smgr;

        my $package_ref_attrs;

        # add MODIFY_CODE_ATTRIBUTES method
        *{"$package\::MODIFY_CODE_ATTRIBUTES"} = sub ( $pkg, $ref, @attrs ) {
            my @bad;

            for my $attr (@attrs) {
                if ( $attr =~ /(Name|Extend|Override|Type|Alias) [(] (?:'(.+?)')? [)]/smxx ) {
                    my ( $attr, $val ) = ( $1, $2 );

                    $package_ref_attrs->{$ref}->{ lc $attr } = $val;
                }
                else {
                    push @bad, $attr;
                }
            }

            return @bad;
        };

        # configure package
        *{"$package\::raw"}  = sub {...};
        *{"$package\::func"} = sub {...};
        *{"$package\::cdn"}  = \undef;
        *{"$package\::api"}  = {};
        *{"$package\::class"} = {};
        *{"$package\::type"}  = {};

        eval { require $module };

        my $stash = Package::Stash::XS->new($package);

        # cleanup
        $stash->remove_symbol('&MODIFY_CODE_ATTRIBUTES');

        die $@ if $@;

        for my $method_name ( grep {/\AEXT_/sm} $stash->list_all_symbols('CODE') ) {
            my $name = $method_name =~ s/\AEXT_//smr;

            my $path = "/$prefix/$name";

            $MODULES->{$module}->{$path} = {
                path    => $path,
                package => $package,
                method  => $method_name,
                ( $package_ref_attrs->{ *{"$package\::$method_name"}{CODE} } // {} )->%*,
            };

            # set ExtJS class name
            $MODULES->{$module}->{$path}->{name} //= "$prefix/$name" =~ s[/][.]smgr;

            my $class = $self->{classes}->{$path} = Pcore::Ext::App::Class->new( $MODULES->{$module}->{$path}->%*, app => $self );

            $classes->{$path} = 1;
        }
    }

    return [ keys $classes->%* ];
}

sub _scan_app_tree ($self) {
    my $tree;

    my $namespace_path = $self->{namespace} =~ s[::][/]smgr;

    for my $inc (@INC) {
        next if is_ref $inc;

        my $path = P->path($inc)->to_abs->{path};

        my $packages = P->path("$path/$namespace_path")->read_dir( abs => 0, is_dir => 0, max_depth => 0 );

        for my $package ( $packages->@* ) {
            $tree->{"$namespace_path/$package"} = 1;
        }
    }

    return $tree;
}

sub _get_framework ($self) {
    return $FRAMEWORK->{ $self->{ext_type} }->{ $self->{ext_ver} } //= $ENV->{share}->read_cfg("/Pcore-Ext/data/ext/$self->{ext_ver}/$self->{ext_type}.json");
}

# TODO cleanup
sub build ($self) {
    my $app_module = $self->{namespace} =~ s[::][/]smgr . '.pm';

    my @app_classes;

    # load main app module
    push @app_classes, $self->_load_module($app_module)->@*;

    # check, that app has EXT_viewport method
    my $viewport = $self->{classes}->{ '/' . $self->{namespace} =~ s[::][/]smgr . '/viewport' };
    die q[Viewport class is not defined] if !defined $viewport;
    $self->{viewport} = $viewport->{name};

    # read app config
    $self->{ext_type}    = ${"$self->{namespace}\::EXT_TYPE"} // $EXT_TYPE;
    $self->{ext_ver}     = version->parse( ${"$self->{namespace}\::EXT_VER"} // $EXT_VER )->normal;
    $self->{ext_theme}   = ${"$self->{namespace}\::EXT_THEME"} // ( $self->{ext_type} eq 'classic' ? $EXT_THEME_CLASSIC : $EXT_THEME_MODERN );
    $self->{ext_api_ver} = ${"$self->{namespace}\::EXT_API_VER"} // $EXT_API_VER;

    # get app modules
    my $tree = $self->_scan_app_tree;

    # load app modules
    for my $module ( keys $tree->%* ) { push @app_classes, $self->_load_module($module)->@* }

    for my $class (@app_classes) { $self->_build_class( $self->{classes}->{$class}, $self->{requires} //= {} ) }

    $self->_generate;

    $self->_build_overrides;

    # cleanup build
    delete $self->{classes};
    delete $self->{requires};
    undef $FRAMEWORK;    # TODO if not --devel

    # delete $self->{api};
    # delete $self->{l10n};
    # delete $self->{overrides};
    # delete $self->{build};

    return;
}

sub _build_class ( $self, $class, $requires ) {

    # class is already processed
    return if defined $class->{build};

    $class->build;

    # add class to the app requires
    $requires->{ $class->{path} } = 1;

    die qq["extend" and "override" defined for class "$class->{path}"] if $class->{extend} && $class->{override};

    # resolve class "extend"
    if ( $class->{extend} ) {
        $class->{extend} = $class->resolve_class_name( $class->{extend} );
        $class->{requires}->{ $class->{extend} } = 1;
    }

    # resolve class "override"
    if ( $class->{override} ) {
        $class->{override} = $class->resolve_class_name( $class->{override} );
        $class->{requires}->{ $class->{override} } = 1;
    }

    # check and load missed requirements
    for my $require ( keys $class->{requires}->%* ) {

        # require is NOT ExtJS class name
        if ( index( $require, '.' ) == -1 ) {

            # add class to the app requires
            $requires->{$require} = 1;

            # class is not loaded
            if ( !exists $self->{classes}->{$require} ) {
                my $module = $require =~ s[\A/][]smr;
                $module =~ s[/[^/]+\z][]sm;
                $module .= '.pm';

                # load module
                $self->_load_module($module);

                # check, that class is present
                die if !exists $self->{classes}->{$require};
            }

            # build class
            $self->_build_class( $self->{classes}->{$require}, $requires );

        }
    }

    # find and set class type
    if ( !$class->{type} ) {
        if ( $class->{extend} ) {

            # extend ExtJS class
            if ( index( $class->{extend}, '.' ) != -1 ) {
                my $framework = $self->_get_framework;

                # base class is not exists
                die qq[Invalid ExtJS class name "$class->{extend}"] if !exists $framework->{ $class->{extend} };

                # inherit alias namespace from the base class
                $class->{type} = $framework->{ $class->{extend} };
            }

            # extend perl class
            else {
                $class->{type} = $self->{classes}->{ $class->{extend} }->{type};
            }
        }
    }

    # generate class alias
    if ( $class->{alias} ) {
        die qq[Class type is not defined for class "$class->{path}"] if !$class->{type};
    }
    elsif ( $class->{type} ) {
        $class->{alias} = substr $class->{path} =~ s/\//-/smgr, 1;
    }

    # check build data
    die qq[Do not use "extend" for class "$class->{path}"]   if exists $class->{build}->{extend};
    die qq[Do not use "override" for class "$class->{path}"] if exists $class->{build}->{override};
    die qq[Do not use "alias" for class "$class->{path}"]    if exists $class->{build}->{alias};
    die qq[Do not use "requires" for class "$class->{path}"] if exists $class->{build}->{requires};

    # set build data
    $class->{build}->{extend}   = Pcore::Ext::App::Class::Ctx::Class->new( class => $class, name => $class->{extend} )   if $class->{extend};
    $class->{build}->{override} = Pcore::Ext::App::Class::Ctx::Class->new( class => $class, name => $class->{override} ) if $class->{override};
    $class->{build}->{alias} = "$class->{type}.$class->{alias}" if $class->{alias};

    # generate
    $class->generate;

    return;
}

sub _generate ($self) {
    my ( %processed_class, $js );

    # topologically sort deps tree
    my $add_deps = sub ($class_name) {

        # node is "white"
        if ( !exists $processed_class{$class_name} ) {

            # mark node as "gray"
            $processed_class{$class_name} = 1;
        }

        # node is "gray", this is cyclic deps
        elsif ( $processed_class{$class_name} == 1 ) {
            die q[Cyclic dependency found];
        }

        # node is "black"
        else {
            return;
        }

        my $class = $self->{classes}->{$class_name};

        for my $require ( sort keys $class->{requires}->%* ) {

            # skip external deps
            next if !exists $self->{classes}->{$require};

            __SUB__->($require);
        }

        # all deps processed, mark node as "black"
        $processed_class{$class_name} = 2;

        # add content
        $js .= "$class->{build}\n\n";

        # add app l10n msgid
        $self->{l10n}->@{ keys $class->{l10n}->%* } = ();

        # add api map
        for my $method ( values $class->{api}->%* ) {
            push $self->{api}->{ $method->{action} }->@*,
              { name     => $method->{name},
                len      => 1,
                params   => [],
                strict   => \0,
                metadata => {
                    len    => 1,
                    params => [],
                    strict => \0,
                },
                formHandler => \0,
              };
        }

        return;
    };

    # sort deps
    for my $class_name ( sort keys $self->{requires}->%* ) {
        $add_deps->($class_name);
    }

    # my $res = P->src->decompress(
    #     path => 'app.js',    # mark file as javascript
    #     data => $js,
    # );

    # $self->{build} = $res->{data};

    $self->{build}->{raw} = $js;

    # sort api methods
    for my $action ( keys $self->{api}->%* ) {
        $self->{api}->{$action} = [ sort { $a->{name} cmp $b->{name} } $self->{api}->{$action}->@* ];
    }

    return;
}

# BOOTSTRAP
sub build_resources ($self) {
    return;
}

sub get_resources ( $self, $devel = undef ) {
    my $cdn = $self->{cdn};

    my @resources = ( $self->build_resources // [] )->@*;

    # CDN resources
    push @resources, $cdn->get_resources(
        'pcore_api',
        [   'extjs6',
            ver   => $self->{ext_ver},
            type  => $self->{ext_type},
            theme => $self->{ext_theme},
            devel => $devel,
        ],
        'fa5',    # NOTE FontAwesme must be after ExtJS in resources or icons will not be displayed
    )->@*;

    return \@resources;
}

# APP
sub get_app ( $self, $devel = undef ) {
    if ($devel) {
        if ( !$self->{build}->{devel} ) {
            $self->{build}->{devel} = $self->_prepare_js( $self->_build_app, 1 );

            delete $self->{build}->{devel_md5};
        }

        return $self->{build}->{devel};
    }
    else {
        if ( !$self->{build}->{min} ) {
            $self->{build}->{min} = $self->_prepare_js( $self->_build_app, 0 );

            delete $self->{build}->{min_md5};
        }

        return $self->{build}->{min};
    }
}

sub _build_app ($self) {
    my $api_url = $self->{api_url};

    my $data = {
        api_url => $api_url,
        api_map => P->data->to_json(
            {   type    => 'websocket',    # remoting
                url     => $api_url,
                actions => $self->{api},

                # not mandatory options
                # id              => 'api',
                namespace       => "EXTDIRECT.$self->{api_namespace}",
                timeout         => 0,                                    # milliseconds, 0 - no timeout
                version         => undef,
                maxRetries      => 0,                                    # number of times to re-attempt delivery on failure of a call
                headers         => {},
                enableBuffer    => 10,                                   # \1, \0, milliseconds
                enableUrlEncode => undef,
            },
            canonical => 1
        ),
    };

    my $js = <<"JS";
        Ext.Loader.setConfig({
            enabled: false,
            disableCaching: false
        });

        // app classes
        $self->{build}->{raw}

        Ext.ariaWarn = Ext.emptyFn;

        // ExtDirect api
        Ext.direct.Manager.addProvider($data->{api_map});

        Ext.application({
            name: 'APP',
            api: new PCORE({
                url: '$data->{api_url}',
                version: '$self->{ext_api_ver}',
                listenEvents: null,
                onConnect: function(api) {},
                onDisconnect: function(api, status, reason) {},
                onEvent: function(api, ev) { Ext.fireEvent('remoteEvent', ev); },
                onListen: function(api, events) {},
                onRpc: null
            }),
            mainView: '$self->{viewport}',
        });
JS

    return $js;
}

sub get_app_md5 ( $self, $devel = undef ) {
    if ($devel) {
        return $self->{build}->{devel_md5} //= P->digest->md5_hex( $self->get_app(1) );
    }
    else {
        return $self->{build}->{min_md5} //= P->digest->md5_hex( $self->get_app(0) );
    }
}

# OVERRIDES
sub _build_overrides ($self) {
    my @classes;

    push @classes, $self->_load_module('Pcore/Ext/Overrides/core.pm')->@*;

    push @classes, $self->_load_module("Pcore/Ext/Overrides/$self->{ext_type}.pm")->@*;

    my $requires = {};

    for my $class (@classes) {
        $self->_build_class( $self->{classes}->{$class}, $requires );
    }

    my $build;

    for my $class ( sort keys $requires->%* ) {
        $build .= "$self->{classes}->{$class}->{build}\n\n";
    }

    $self->{overrides} = { raw => $build };

    return $EMPTY;
}

sub get_overrides ( $self, $devel = undef ) {
    if ($devel) {
        if ( !$self->{overrides}->{devel} ) {
            $self->{overrides}->{devel} = $self->_prepare_js( $self->{overrides}->{raw}, 1 );

            delete $self->{overrides}->{devel_md5};
        }

        return $self->{overrides}->{devel};
    }
    else {
        if ( !$self->{overrides}->{min} ) {
            $self->{overrides}->{min} = $self->_prepare_js( $self->{overrides}->{raw}, 0 );

            delete $self->{overrides}->{min_md5};
        }

        return $self->{overrides}->{min};
    }
}

sub get_overrides_md5 ( $self, $devel = undef ) {
    if ($devel) {
        return $self->{overrides}->{devel_md5} //= P->digest->md5_hex( $self->get_overrides(1) );
    }
    else {
        return $self->{overrides}->{min_md5} //= P->digest->md5_hex( $self->get_overrides(0) );
    }
}

# LOCALE
# TODO
sub get_locale ( $self, $locale, $req, $devel = undef ) {
    state $locale_settings = {};

    $locale_settings->{$locale} //= $ENV->{share}->read_cfg("data/ext/locale/$locale.perl");

    # load locale
    Pcore::Core::L10N::load_locale($locale) if !exists $Pcore::Core::L10N::MESSAGES->{$locale};

    # get messages, used by app classes
    my $locale_messages = $Pcore::Core::L10N::MESSAGES->{$locale};

    # grep app messages, that have translation
    my $messages = { $locale_messages->%{ grep { $locale_messages->{$_} } keys $self->{l10n}->%* } };

    my $plural_form_exp = $Pcore::Core::L10N::LOCALE_PLURAL_FORM->{$locale}->{exp} // 0;

    my $js = <<"JS";
            Ext.L10N.addLocale(
                '$locale',
                {   messages: @{[ to_json $messages, canonical => 1 ]},
                    pluralFormExp: function (n) { return $plural_form_exp; },
                    settings: @{[ to_json $locale_settings->{$locale}, canonical => 1 ]}
                }
            );
JS

    $self->{_cache}->{locale}->{$locale}->{js} = $self->_prepare_js($js);

    $self->{_cache}->{locale}->{$locale}->{etag} = 'W/' . P->digest->md5_hex( $self->{_cache}->{locale}->{$locale}->{js}->$* );

    return;
}

sub get_locale_md5 ( $self, $locale, $devel = undef ) {
    if ($devel) {
        return $self->{locales}->{devel_md5} //= P->digest->md5_hex( $self->get_locale( $locale, 1 ) );
    }
    else {
        return $self->{locales}->{min_md5} //= P->digest->md5_hex( $self->get_overrides( $locale, 0 ) );
    }
}

sub _prepare_js ( $self, $js, $devel = undef ) {
    P->text->encode_utf8($js);

    if ($devel) {
        $js = P->src->decompress(
            path => '1.js',
            data => $js,
        )->{data};
    }
    else {
        $js = P->src->compress(
            path => '1.js',
            data => $js,
        )->{data};
    }

    return $js;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 90, 91               | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 97                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 199                  | Subroutines::ProhibitExcessComplexity - Subroutine "_build_class" with high complexity score (25)              |
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
