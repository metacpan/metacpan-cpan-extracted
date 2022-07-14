{

    package Sub::HandlesVia::CodeGenerator;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.006011";

    BEGIN {
        require Scalar::Util;
        *bare    = \&Sub::HandlesVia::Mite::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Sub::HandlesVia::Mite::carp;
        *confess = \&Sub::HandlesVia::Mite::confess;
        *croak   = \&Sub::HandlesVia::Mite::croak;
        *false   = \&Sub::HandlesVia::Mite::false;
        *guard   = \&Sub::HandlesVia::Mite::guard;
        *lazy    = \&Sub::HandlesVia::Mite::lazy;
        *ro      = \&Sub::HandlesVia::Mite::ro;
        *rw      = \&Sub::HandlesVia::Mite::rw;
        *rwp     = \&Sub::HandlesVia::Mite::rwp;
        *true    = \&Sub::HandlesVia::Mite::true;
    }

    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Attribute: toolkit
        if ( exists $args->{"toolkit"} ) {
            $self->{"toolkit"} = $args->{"toolkit"};
        }

        # Attribute: target
        if ( exists $args->{"target"} ) {
            $self->{"target"} = $args->{"target"};
        }

        # Attribute: attribute
        if ( exists $args->{"attribute"} ) {
            $self->{"attribute"} = $args->{"attribute"};
        }

        # Attribute: attribute_spec
        if ( exists $args->{"attribute_spec"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"attribute_spec"} ) eq 'HASH';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "attribute_spec", "HashRef";
            $self->{"attribute_spec"} = $args->{"attribute_spec"};
        }

        # Attribute: isa
        if ( exists $args->{"isa"} ) { $self->{"isa"} = $args->{"isa"}; }

        # Attribute: coerce
        if ( exists $args->{"coerce"} ) {
            do {

                package Sub::HandlesVia::Mite;
                !ref $args->{"coerce"}
                  and (!defined $args->{"coerce"}
                    or $args->{"coerce"} eq q()
                    or $args->{"coerce"} eq '0'
                    or $args->{"coerce"} eq '1' );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "coerce", "Bool";
            $self->{"coerce"} = $args->{"coerce"};
        }

        # Attribute: env
        $self->{"env"} = ( exists( $args->{"env"} ) ? $args->{"env"} : {} );

        # Attribute: generator_for_slot
        if ( exists $args->{"generator_for_slot"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_slot"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_slot", "CodeRef";
            $self->{"generator_for_slot"} = $args->{"generator_for_slot"};
        }

        # Attribute: generator_for_get
        if ( exists $args->{"generator_for_get"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_get"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_get", "CodeRef";
            $self->{"generator_for_get"} = $args->{"generator_for_get"};
        }

        # Attribute: generator_for_set
        if ( exists $args->{"generator_for_set"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_set"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_set", "CodeRef";
            $self->{"generator_for_set"} = $args->{"generator_for_set"};
        }

        # Attribute: generator_for_default
        if ( exists $args->{"generator_for_default"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_default"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_default", "CodeRef";
            $self->{"generator_for_default"} = $args->{"generator_for_default"};
        }

        # Attribute: generator_for_args
        if ( exists $args->{"generator_for_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_args"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_args", "CodeRef";
            $self->{"generator_for_args"} = $args->{"generator_for_args"};
        }

        # Attribute: generator_for_arg
        if ( exists $args->{"generator_for_arg"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_arg"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_arg", "CodeRef";
            $self->{"generator_for_arg"} = $args->{"generator_for_arg"};
        }

        # Attribute: generator_for_argc
        if ( exists $args->{"generator_for_argc"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_argc"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_argc", "CodeRef";
            $self->{"generator_for_argc"} = $args->{"generator_for_argc"};
        }

        # Attribute: generator_for_currying
        if ( exists $args->{"generator_for_currying"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_currying"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_currying", "CodeRef";
            $self->{"generator_for_currying"} =
              $args->{"generator_for_currying"};
        }

        # Attribute: generator_for_usage_string
        if ( exists $args->{"generator_for_usage_string"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_usage_string"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_usage_string", "CodeRef";
            $self->{"generator_for_usage_string"} =
              $args->{"generator_for_usage_string"};
        }

        # Attribute: generator_for_self
        if ( exists $args->{"generator_for_self"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_self"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_self", "CodeRef";
            $self->{"generator_for_self"} = $args->{"generator_for_self"};
        }

        # Attribute: method_installer
        if ( exists $args->{"method_installer"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"method_installer"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "method_installer", "CodeRef";
            $self->{"method_installer"} = $args->{"method_installer"};
        }

        # Attribute: is_method
        $self->{"is_method"} =
          ( exists( $args->{"is_method"} ) ? $args->{"is_method"} : "1" );

        # Attribute: get_is_lvalue
        $self->{"get_is_lvalue"} = (
            exists( $args->{"get_is_lvalue"} )
            ? $args->{"get_is_lvalue"}
            : "" );

        # Attribute: set_checks_isa
        $self->{"set_checks_isa"} = (
            exists( $args->{"set_checks_isa"} )
            ? $args->{"set_checks_isa"}
            : "" );

        # Attribute: set_strictly
        $self->{"set_strictly"} =
          ( exists( $args->{"set_strictly"} ) ? $args->{"set_strictly"} : "1" );

        # Enforce strict constructor
        my @unknown = grep not(
/\A(?:attribute(?:_spec)?|coerce|env|ge(?:nerator_for_(?:arg[cs]?|currying|default|get|s(?:e(?:lf|t)|lot)|usage_string)|t_is_lvalue)|is(?:_method|a)|method_installer|set_(?:checks_isa|strictly)|t(?:arget|oolkit))\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        return $self;
    }

    sub BUILDALL {
        my $class = ref( $_[0] );
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        $_->(@_) for @{ $meta->{BUILD} || [] };
    }

    sub DESTROY {
        my $self  = shift;
        my $class = ref($self) || $self;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $in_global_destruction =
          defined ${^GLOBAL_PHASE}
          ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
          : Devel::GlobalDestruction::in_global_destruction();
        for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
            my $e = do {
                local ( $?, $@ );
                eval { $demolisher->( $self, $in_global_destruction ) };
                $@;
            };
            no warnings 'misc';    # avoid (in cleanup) warnings
            die $e if $e;          # rethrow
        }
        return;
    }

    sub __META__ {
        no strict 'refs';
        no warnings 'once';
        my $class = shift;
        $class = ref($class) || $class;
        my $linear_isa = mro::get_linear_isa($class);
        return {
            BUILD => [
                map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                map { "$_\::BUILD" } reverse @$linear_isa
            ],
            DEMOLISH => [
                map   { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                  map { "$_\::DEMOLISH" } @$linear_isa
            ],
            HAS_BUILDARGS        => $class->can('BUILDARGS'),
            HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
        };
    }

    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    sub does {
        shift->DOES(@_);
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for _override
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "_override" => "_override" },
        );
    }
    else {
        *_override = sub {
            @_ > 1
              ? do { $_[0]{"_override"} = $_[1]; $_[0]; }
              : ( $_[0]{"_override"} );
        };
    }

    # Accessors for attribute
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "attribute" => "attribute" },
        );
    }
    else {
        *attribute = sub {
            @_ > 1
              ? croak("attribute is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"attribute"};
        };
    }

    # Accessors for attribute_spec
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "attribute_spec" => "attribute_spec" },
        );
    }
    else {
        *attribute_spec = sub {
            @_ > 1
              ? croak(
                "attribute_spec is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"attribute_spec"};
        };
    }

    # Accessors for coerce
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "coerce" => "coerce" },
        );
    }
    else {
        *coerce = sub {
            @_ > 1
              ? croak("coerce is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"coerce"};
        };
    }

    # Accessors for env
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "env" => "env" },
        );
    }
    else {
        *env = sub {
            @_ > 1 ? do { $_[0]{"env"} = $_[1]; $_[0]; } : ( $_[0]{"env"} );
        };
    }

    # Accessors for generator_for_arg
    sub generator_for_arg {
        @_ > 1
          ? croak(
            "generator_for_arg is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{"generator_for_arg"} ) ? $_[0]{"generator_for_arg"}
            : (
                $_[0]{"generator_for_arg"} = do {
                    my $default_value = $_[0]->_build_generator_for_arg;
                    ( ref($default_value) eq 'CODE' )
                      or croak( "Type check failed in default: %s should be %s",
                        "generator_for_arg", "CodeRef" );
                    $default_value;
                }
            )
          );
    }

    # Accessors for generator_for_argc
    sub generator_for_argc {
        @_ > 1
          ? croak(
            "generator_for_argc is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{"generator_for_argc"} ) ? $_[0]{"generator_for_argc"}
            : (
                $_[0]{"generator_for_argc"} = do {
                    my $default_value = $_[0]->_build_generator_for_argc;
                    ( ref($default_value) eq 'CODE' )
                      or croak( "Type check failed in default: %s should be %s",
                        "generator_for_argc", "CodeRef" );
                    $default_value;
                }
            )
          );
    }

    # Accessors for generator_for_args
    sub generator_for_args {
        @_ > 1
          ? croak(
            "generator_for_args is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{"generator_for_args"} ) ? $_[0]{"generator_for_args"}
            : (
                $_[0]{"generator_for_args"} = do {
                    my $default_value = $_[0]->_build_generator_for_args;
                    ( ref($default_value) eq 'CODE' )
                      or croak( "Type check failed in default: %s should be %s",
                        "generator_for_args", "CodeRef" );
                    $default_value;
                }
            )
          );
    }

    # Accessors for generator_for_currying
    sub generator_for_currying {
        @_ > 1
          ? croak(
            "generator_for_currying is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{"generator_for_currying"} )
            ? $_[0]{"generator_for_currying"}
            : (
                $_[0]{"generator_for_currying"} = do {
                    my $default_value = $_[0]->_build_generator_for_currying;
                    ( ref($default_value) eq 'CODE' )
                      or croak( "Type check failed in default: %s should be %s",
                        "generator_for_currying", "CodeRef" );
                    $default_value;
                }
            )
          );
    }

    # Accessors for generator_for_default
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_default" => "generator_for_default" },
        );
    }
    else {
        *generator_for_default = sub {
            @_ > 1
              ? croak(
"generator_for_default is a read-only attribute of @{[ref $_[0]]}"
              )
              : $_[0]{"generator_for_default"};
        };
    }

    # Accessors for generator_for_get
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_get" => "generator_for_get" },
        );
    }
    else {
        *generator_for_get = sub {
            @_ > 1
              ? croak(
                "generator_for_get is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_get"};
        };
    }

    # Accessors for generator_for_self
    sub generator_for_self {
        @_ > 1
          ? croak(
            "generator_for_self is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{"generator_for_self"} ) ? $_[0]{"generator_for_self"}
            : (
                $_[0]{"generator_for_self"} = do {
                    my $default_value = $_[0]->_build_generator_for_self;
                    ( ref($default_value) eq 'CODE' )
                      or croak( "Type check failed in default: %s should be %s",
                        "generator_for_self", "CodeRef" );
                    $default_value;
                }
            )
          );
    }

    # Accessors for generator_for_set
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_set" => "generator_for_set" },
        );
    }
    else {
        *generator_for_set = sub {
            @_ > 1
              ? croak(
                "generator_for_set is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_set"};
        };
    }

    # Accessors for generator_for_slot
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_slot" => "generator_for_slot" },
        );
    }
    else {
        *generator_for_slot = sub {
            @_ > 1
              ? croak(
                "generator_for_slot is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_slot"};
        };
    }

    # Accessors for generator_for_usage_string
    sub generator_for_usage_string {
        @_ > 1
          ? croak(
"generator_for_usage_string is a read-only attribute of @{[ref $_[0]]}"
          )
          : (
            exists( $_[0]{"generator_for_usage_string"} )
            ? $_[0]{"generator_for_usage_string"}
            : (
                $_[0]{"generator_for_usage_string"} = do {
                    my $default_value =
                      $_[0]->_build_generator_for_usage_string;
                    ( ref($default_value) eq 'CODE' )
                      or croak(
                        "Type check failed in default: %s should be %s",
                        "generator_for_usage_string",
                        "CodeRef"
                      );
                    $default_value;
                }
            )
          );
    }

    # Accessors for get_is_lvalue
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "get_is_lvalue" => "get_is_lvalue" },
        );
    }
    else {
        *get_is_lvalue = sub {
            @_ > 1
              ? do { $_[0]{"get_is_lvalue"} = $_[1]; $_[0]; }
              : ( $_[0]{"get_is_lvalue"} );
        };
    }

    # Accessors for is_method
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "is_method" => "is_method" },
        );
    }
    else {
        *is_method = sub {
            @_ > 1
              ? do { $_[0]{"is_method"} = $_[1]; $_[0]; }
              : ( $_[0]{"is_method"} );
        };
    }

    # Accessors for isa
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "isa" => "isa" },
        );
    }
    else {
        *isa = sub {
            @_ > 1
              ? croak("isa is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"isa"};
        };
    }

    # Accessors for method_installer
    sub method_installer {
        @_ > 1
          ? do {
            ( ref( $_[1] ) eq 'CODE' )
              or croak( "Type check failed in %s: value should be %s",
                "accessor", "CodeRef" );
            $_[0]{"method_installer"} = $_[1];
            $_[0];
          }
          : ( $_[0]{"method_installer"} );
    }

    # Accessors for set_checks_isa
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "set_checks_isa" => "set_checks_isa" },
        );
    }
    else {
        *set_checks_isa = sub {
            @_ > 1
              ? do { $_[0]{"set_checks_isa"} = $_[1]; $_[0]; }
              : ( $_[0]{"set_checks_isa"} );
        };
    }

    # Accessors for set_strictly
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "set_strictly" => "set_strictly" },
        );
    }
    else {
        *set_strictly = sub {
            @_ > 1
              ? do { $_[0]{"set_strictly"} = $_[1]; $_[0]; }
              : ( $_[0]{"set_strictly"} );
        };
    }

    # Accessors for target
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "target" => "target" },
        );
    }
    else {
        *target = sub {
            @_ > 1
              ? croak("target is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"target"};
        };
    }

    # Accessors for toolkit
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "toolkit" => "toolkit" },
        );
    }
    else {
        *toolkit = sub {
            @_ > 1
              ? croak("toolkit is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"toolkit"};
        };
    }

    1;
}
