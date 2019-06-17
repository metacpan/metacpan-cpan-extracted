package Pcore::Ext::App;

use Pcore -class, -const;
use Pcore::Util::Scalar qw[is_ref];
use Pcore::Util::Data qw[to_json];
use Package::Stash::XS qw[];
use Pcore::Ext::App::Class;

has devel     => ();
has ext       => ( required => 1 );    # InstanceOf['Pcore::Ext']
has id        => ( required => 1 );
has namespace => ( required => 1 );

has cdn           => ();               # maybe InstanceOf['Pcore::CDN']
has api_namespace => ();
has prefixes      => ();
has api_url       => '/api';

has ext_ver     => ( init_arg => undef );
has ext_theme   => ( init_arg => undef );
has ext_api_ver => ( init_arg => undef );
has viewport    => ( init_arg => undef );    # viewport class name

# BUILD CACHE
has classes  => ( init_arg => undef );       # HashRef
has requires => ( init_arg => undef );       # HashRef
has api      => ( init_arg => undef );       # HashRef, used API methods
has locales  => ( init_arg => undef );       # HashRef, used l10n msgid's

const our $EXT_VER     => v6.7.0;
const our $EXT_THEME   => 'material';
const our $EXT_API_VER => 'v1';

our $MODULES;
our $FRAMEWORK;

sub _load_module ( $self, $module ) {
    my $classes;

    if ( exists $MODULES->{$module} ) {
        for my $class ( keys $MODULES->{$module}->%* ) {
            $self->{classes}->{$class} = Pcore::Ext::App::Class->new( $MODULES->{$module}->{$class}->%*, app => $self );

            $classes->{$class} = 1;
        }
    }
    else {
        my $package = P->class->module_to_package($module);

        my $prefix = $package =~ s[::][/]smgr;

        # remove all package symbols
        P->class->unload($package);

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

        # load module
        do P->class->find($module);

        # package compilation error
        die qq[Unable to load module "$module": $@] if $@;

        my $stash = Package::Stash::XS->new($package);

        # scan EXT_ methods
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

sub _get_app_modules ($self) {
    my $modules;

    my $namespace_path = $self->{namespace} =~ s[::][/]smgr;

    for my $inc (@INC) {
        next if is_ref $inc;

        my $path = P->path($inc)->to_abs->{path};

        my $packages = P->path("$path/$namespace_path")->read_dir( abs => 0, is_dir => 0, max_depth => 0 );

        for my $package ( $packages->@* ) {
            $modules->{"$namespace_path/$package"} = 1;
        }
    }

    return $modules;
}

sub _get_framework ($self) {
    return $FRAMEWORK->{ $self->{ext_ver} } //= $ENV->{share}->read_cfg("/Pcore-Ext/data/ext/$self->{ext_ver}/config.json");
}

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
    $self->{ext_ver}     = version->parse( ${"$self->{namespace}\::EXT_VER"} // $EXT_VER )->normal;
    $self->{ext_theme}   = ${"$self->{namespace}\::EXT_THEME"} // $EXT_THEME;
    $self->{ext_api_ver} = ${"$self->{namespace}\::EXT_API_VER"} // $EXT_API_VER;

    # get app modules
    my $modules = $self->_get_app_modules;

    # load app modules
    for my $module ( keys $modules->%* ) { push @app_classes, $self->_load_module($module)->@* }

    for my $class (@app_classes) { $self->_build_class( $self->{classes}->{$class}, $self->{requires} //= {} ) }

    # build and deploy app.js
    $self->_build_app;

    # build and deploy overrides.js
    $self->_build_overrides;

    # build and deploy locales
    $self->_build_locales;

    # cleanup build cache
    delete $self->{classes};
    delete $self->{requires};
    delete $self->{api};
    delete $self->{locales};

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
                die qq[Class "$require" is not exists] if !exists $self->{classes}->{$require};
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
            theme => $self->{ext_theme},
            devel => $devel,
        ],
        'fa5',    # NOTE FontAwesme must be after ExtJS in resources or icons will not be displayed
    )->@*;

    return \@resources;
}

# APP
sub _build_app ($self) {
    my $app_classes_js = $self->_generate_app_classes_js;

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
        $app_classes_js

        Ext.ariaWarn = Ext.emptyFn;

        // ExtDirect api
        Ext.direct.Manager.addProvider($data->{api_map});

        Ext.application({
            name: 'APP',
            appCdn: '@{[ $self->{cdn}->("/app/$self->{id}") ]}',
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

    $js = $self->_prepare_js($js);

    # CDN deploy
    $self->{cdn}->upload( "/app/$self->{id}/app.js", $js );

    return;
}

sub _generate_app_classes_js ($self) {
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
        $self->{locales}->@{ keys $class->{l10n}->%* } = ();

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

    # sort api methods
    for my $action ( keys $self->{api}->%* ) {
        $self->{api}->{$action} = [ sort { $a->{name} cmp $b->{name} } $self->{api}->{$action}->@* ];
    }

    return $js;
}

# OVERRIDES
sub _build_overrides ($self) {
    my @classes;

    push @classes, $self->_load_module('Pcore/Ext/Overrides/core.pm')->@*;

    push @classes, $self->_load_module("Pcore/Ext/Overrides/modern.pm")->@*;

    my $requires = {};

    for my $class (@classes) {
        $self->_build_class( $self->{classes}->{$class}, $requires );
    }

    my $build;

    for my $class ( sort keys $requires->%* ) {
        $build .= "$self->{classes}->{$class}->{build}\n\n";
    }

    $build = $self->_prepare_js($build);

    # CDN deploy
    $self->{cdn}->upload( '/app/overrides.js', $build );

    return;
}

# LOCALE
sub _build_locales ( $self ) {
    state $locale_settings = {};

    for my $locale (qw[ru]) {
        $locale_settings->{$locale} //= $ENV->{share}->read_cfg("data/ext/locale/$locale.perl");

        # load locale
        Pcore::Core::L10N::load_locale($locale) if !exists $Pcore::Core::L10N::MESSAGES->{$locale};

        # get messages, used by app classes
        my $locale_messages = $Pcore::Core::L10N::MESSAGES->{$locale};

        # grep app messages, that have translation
        my $messages = { $locale_messages->%{ grep { $locale_messages->{$_} } keys $self->{locales}->%* } };

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

        # CDN deploy
        $self->{cdn}->upload( "/app/$self->{id}/locale/$locale.js", $self->_prepare_js($js) );
    }

    return;
}

sub _prepare_js ( $self, $js ) {
    P->text->encode_utf8($js);

    if ( $self->{devel} ) {
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
## |    3 | 76, 77               | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 184                  | Subroutines::ProhibitExcessComplexity - Subroutine "_build_class" with high complexity score (25)              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 453                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
