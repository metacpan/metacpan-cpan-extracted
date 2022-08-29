{

    package Sub::HandlesVia::CodeGenerator;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.010005";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Sub::HandlesVia::Mite", "Sub::HandlesVia::CodeGenerator" );
        (
            *after, *around, *before,        *extends, *field,
            *has,   *param,  *signature_for, *with
          )
          = do {

            package Sub::HandlesVia::Mite;
            no warnings 'redefine';
            (
                sub { $SHIM->HANDLE_after( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_around( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_before( $CALLER, "class", @_ ) },
                sub { },
                sub { $SHIM->HANDLE_has( $CALLER, field => @_ ) },
                sub { $SHIM->HANDLE_has( $CALLER, has   => @_ ) },
                sub { $SHIM->HANDLE_has( $CALLER, param => @_ ) },
                sub { $SHIM->HANDLE_signature_for( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_with( $CALLER, @_ ) },
            );
          };
    }

    # Mite imports
    BEGIN {
        require Scalar::Util;
        *STRICT  = \&Sub::HandlesVia::Mite::STRICT;
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

    # Gather metadata for constructor and destructor
    sub __META__ {
        no strict 'refs';
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

    # Standard Moose/Moo-style constructor
    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Attribute toolkit
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 12
        if ( exists $args->{"toolkit"} ) {
            $self->{"toolkit"} = $args->{"toolkit"};
        }

        # Attribute target
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 16
        if ( exists $args->{"target"} ) {
            $self->{"target"} = $args->{"target"};
        }

        # Attribute attribute
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 20
        if ( exists $args->{"attribute"} ) {
            $self->{"attribute"} = $args->{"attribute"};
        }

        # Attribute attribute_spec (type: HashRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 24
        if ( exists $args->{"attribute_spec"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"attribute_spec"} ) eq 'HASH';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "attribute_spec", "HashRef";
            $self->{"attribute_spec"} = $args->{"attribute_spec"};
        }

        # Attribute isa
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 29
        if ( exists $args->{"isa"} ) { $self->{"isa"} = $args->{"isa"}; }

        # Attribute coerce (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 33
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

        # Attribute env (type: HashRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 38
        do {
            my $value = exists( $args->{"env"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"env"} ) eq 'HASH';
                    }
                ) ? $args->{"env"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "env", "HashRef"
                )
              )
              : {};
            $self->{"env"} = $value;
        };

        # Attribute sandboxing_package (type: Str|Undef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
        do {
            my $value = exists( $args->{"sandboxing_package"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        (
                            do {

                                package Sub::HandlesVia::Mite;
                                defined( $args->{"sandboxing_package"} )
                                  and do {
                                    ref( \$args->{"sandboxing_package"} ) eq
                                      'SCALAR'
                                      or ref(
                                        \(
                                            my $val =
                                              $args->{"sandboxing_package"}
                                        )
                                      ) eq 'SCALAR';
                                }
                              }
                              or do {

                                package Sub::HandlesVia::Mite;
                                !defined( $args->{"sandboxing_package"} );
                            }
                        );
                    }
                ) ? $args->{"sandboxing_package"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "sandboxing_package", "Str|Undef"
                )
              )
              : "Sub::HandlesVia::CodeGenerator::__SANDBOX__";
            $self->{"sandboxing_package"} = $value;
        };

        # Attribute generator_for_slot (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
        if ( exists $args->{"generator_for_slot"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_slot"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_slot", "CodeRef";
            $self->{"generator_for_slot"} = $args->{"generator_for_slot"};
        }

        # Attribute generator_for_get (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
        if ( exists $args->{"generator_for_get"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_get"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_get", "CodeRef";
            $self->{"generator_for_get"} = $args->{"generator_for_get"};
        }

        # Attribute generator_for_set (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
        if ( exists $args->{"generator_for_set"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_set"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_set", "CodeRef";
            $self->{"generator_for_set"} = $args->{"generator_for_set"};
        }

        # Attribute generator_for_default (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
        if ( exists $args->{"generator_for_default"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_default"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_default", "CodeRef";
            $self->{"generator_for_default"} = $args->{"generator_for_default"};
        }

        # Attribute generator_for_args (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 65
        do {
            my $value = exists( $args->{"generator_for_args"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_args"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_args"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_args", "CodeRef"
                )
              )
              : $self->_build_generator_for_args;
            $self->{"generator_for_args"} = $value;
        };

        # Attribute generator_for_arg (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 78
        do {
            my $value = exists( $args->{"generator_for_arg"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_arg"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_arg"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_arg", "CodeRef"
                )
              )
              : $self->_build_generator_for_arg;
            $self->{"generator_for_arg"} = $value;
        };

        # Attribute generator_for_argc (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 89
        do {
            my $value = exists( $args->{"generator_for_argc"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_argc"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_argc"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_argc", "CodeRef"
                )
              )
              : $self->_build_generator_for_argc;
            $self->{"generator_for_argc"} = $value;
        };

        # Attribute generator_for_currying (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 102
        do {
            my $value = exists( $args->{"generator_for_currying"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_currying"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_currying"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_currying", "CodeRef"
                )
              )
              : $self->_build_generator_for_currying;
            $self->{"generator_for_currying"} = $value;
        };

        # Attribute generator_for_usage_string (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 117
        do {
            my $value = exists( $args->{"generator_for_usage_string"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_usage_string"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_usage_string"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_usage_string", "CodeRef"
                )
              )
              : $self->_build_generator_for_usage_string;
            $self->{"generator_for_usage_string"} = $value;
        };

        # Attribute generator_for_self (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 128
        do {
            my $value = exists( $args->{"generator_for_self"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_self"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_self"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_self", "CodeRef"
                )
              )
              : $self->_build_generator_for_self;
            $self->{"generator_for_self"} = $value;
        };

        # Attribute generator_for_type_assertion (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 155
        do {
            my $value = exists( $args->{"generator_for_type_assertion"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_type_assertion"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_type_assertion"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_type_assertion",
                    "CodeRef"
                )
              )
              : $self->_build_generator_for_type_assertion;
            $self->{"generator_for_type_assertion"} = $value;
        };

        # Attribute method_installer (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 158
        if ( exists $args->{"method_installer"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"method_installer"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "method_installer", "CodeRef";
            $self->{"method_installer"} = $args->{"method_installer"};
        }

        # Attribute is_method
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 168
        $self->{"is_method"} =
          ( exists( $args->{"is_method"} ) ? $args->{"is_method"} : "1" );

        # Attribute get_is_lvalue
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 173
        $self->{"get_is_lvalue"} = (
            exists( $args->{"get_is_lvalue"} )
            ? $args->{"get_is_lvalue"}
            : "" );

        # Attribute set_checks_isa
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 178
        $self->{"set_checks_isa"} = (
            exists( $args->{"set_checks_isa"} )
            ? $args->{"set_checks_isa"}
            : "" );

        # Attribute set_strictly
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 183
        $self->{"set_strictly"} =
          ( exists( $args->{"set_strictly"} ) ? $args->{"set_strictly"} : "1" );

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(
/\A(?:attribute(?:_spec)?|coerce|env|ge(?:nerator_for_(?:arg[cs]?|currying|default|get|s(?:e(?:lf|t)|lot)|type_assertion|usage_string)|t_is_lvalue)|is(?:_method|a)|method_installer|s(?:andboxing_package|et_(?:checks_isa|strictly))|t(?:arget|oolkit))\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    # Used by constructor to call BUILD methods
    sub BUILDALL {
        my $class = ref( $_[0] );
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        $_->(@_) for @{ $meta->{BUILD} || [] };
    }

    # Destructor should call DEMOLISH methods
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

    my $__XS = !$ENV{PERL_ONLY}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for _override
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 163
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
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 20
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "attribute" => "attribute" },
        );
    }
    else {
        *attribute = sub {
            @_ == 1 or croak('Reader "attribute" usage: $self->attribute()');
            $_[0]{"attribute"};
        };
    }

    # Accessors for attribute_spec
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 24
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "attribute_spec" => "attribute_spec" },
        );
    }
    else {
        *attribute_spec = sub {
            @_ == 1
              or
              croak('Reader "attribute_spec" usage: $self->attribute_spec()');
            $_[0]{"attribute_spec"};
        };
    }

    # Accessors for coerce
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 33
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "coerce" => "coerce" },
        );
    }
    else {
        *coerce = sub {
            @_ == 1 or croak('Reader "coerce" usage: $self->coerce()');
            $_[0]{"coerce"};
        };
    }

    # Accessors for env
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 38
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "env" => "env" },
        );
    }
    else {
        *env = sub {
            @_ == 1 or croak('Reader "env" usage: $self->env()');
            $_[0]{"env"};
        };
    }

    # Accessors for generator_for_arg
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 78
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_arg" => "generator_for_arg" },
        );
    }
    else {
        *generator_for_arg = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_arg" usage: $self->generator_for_arg()');
            $_[0]{"generator_for_arg"};
        };
    }

    # Accessors for generator_for_argc
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 89
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_argc" => "generator_for_argc" },
        );
    }
    else {
        *generator_for_argc = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_argc" usage: $self->generator_for_argc()'
              );
            $_[0]{"generator_for_argc"};
        };
    }

    # Accessors for generator_for_args
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 65
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_args" => "generator_for_args" },
        );
    }
    else {
        *generator_for_args = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_args" usage: $self->generator_for_args()'
              );
            $_[0]{"generator_for_args"};
        };
    }

    # Accessors for generator_for_currying
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 102
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" =>
              { "generator_for_currying" => "generator_for_currying" },
        );
    }
    else {
        *generator_for_currying = sub {
            @_ == 1
              or croak(
'Reader "generator_for_currying" usage: $self->generator_for_currying()'
              );
            $_[0]{"generator_for_currying"};
        };
    }

    # Accessors for generator_for_default
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_default" => "generator_for_default" },
        );
    }
    else {
        *generator_for_default = sub {
            @_ == 1
              or croak(
'Reader "generator_for_default" usage: $self->generator_for_default()'
              );
            $_[0]{"generator_for_default"};
        };
    }

    # Accessors for generator_for_get
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_get" => "generator_for_get" },
        );
    }
    else {
        *generator_for_get = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_get" usage: $self->generator_for_get()');
            $_[0]{"generator_for_get"};
        };
    }

    # Accessors for generator_for_self
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 128
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_self" => "generator_for_self" },
        );
    }
    else {
        *generator_for_self = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_self" usage: $self->generator_for_self()'
              );
            $_[0]{"generator_for_self"};
        };
    }

    # Accessors for generator_for_set
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_set" => "generator_for_set" },
        );
    }
    else {
        *generator_for_set = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_set" usage: $self->generator_for_set()');
            $_[0]{"generator_for_set"};
        };
    }

    # Accessors for generator_for_slot
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 52
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_slot" => "generator_for_slot" },
        );
    }
    else {
        *generator_for_slot = sub {
            @_ == 1
              or croak(
                'Reader "generator_for_slot" usage: $self->generator_for_slot()'
              );
            $_[0]{"generator_for_slot"};
        };
    }

    # Accessors for generator_for_type_assertion
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 155
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => {
                "generator_for_type_assertion" => "generator_for_type_assertion"
            },
        );
    }
    else {
        *generator_for_type_assertion = sub {
            @_ == 1
              or croak(
'Reader "generator_for_type_assertion" usage: $self->generator_for_type_assertion()'
              );
            $_[0]{"generator_for_type_assertion"};
        };
    }

    # Accessors for generator_for_usage_string
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 117
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" =>
              { "generator_for_usage_string" => "generator_for_usage_string" },
        );
    }
    else {
        *generator_for_usage_string = sub {
            @_ == 1
              or croak(
'Reader "generator_for_usage_string" usage: $self->generator_for_usage_string()'
              );
            $_[0]{"generator_for_usage_string"};
        };
    }

    # Accessors for get_is_lvalue
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 173
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "get_is_lvalue" => "get_is_lvalue" },
        );
    }
    else {
        *get_is_lvalue = sub {
            @_ == 1
              or croak('Reader "get_is_lvalue" usage: $self->get_is_lvalue()');
            $_[0]{"get_is_lvalue"};
        };
    }

    # Accessors for is_method
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 168
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "is_method" => "is_method" },
        );
    }
    else {
        *is_method = sub {
            @_ == 1 or croak('Reader "is_method" usage: $self->is_method()');
            $_[0]{"is_method"};
        };
    }

    # Accessors for isa
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 29
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "isa" => "isa" },
        );
    }
    else {
        *isa = sub {
            @_ == 1 or croak('Reader "isa" usage: $self->isa()');
            $_[0]{"isa"};
        };
    }

    # Accessors for method_installer
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 158
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

    # Accessors for sandboxing_package
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "sandboxing_package" => "sandboxing_package" },
        );
    }
    else {
        *sandboxing_package = sub {
            @_ == 1
              or croak(
                'Reader "sandboxing_package" usage: $self->sandboxing_package()'
              );
            $_[0]{"sandboxing_package"};
        };
    }

    # Accessors for set_checks_isa
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 178
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "set_checks_isa" => "set_checks_isa" },
        );
    }
    else {
        *set_checks_isa = sub {
            @_ == 1
              or
              croak('Reader "set_checks_isa" usage: $self->set_checks_isa()');
            $_[0]{"set_checks_isa"};
        };
    }

    # Accessors for set_strictly
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 183
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "set_strictly" => "set_strictly" },
        );
    }
    else {
        *set_strictly = sub {
            @_ == 1
              or croak('Reader "set_strictly" usage: $self->set_strictly()');
            $_[0]{"set_strictly"};
        };
    }

    # Accessors for target
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 16
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "target" => "target" },
        );
    }
    else {
        *target = sub {
            @_ == 1 or croak('Reader "target" usage: $self->target()');
            $_[0]{"target"};
        };
    }

    # Accessors for toolkit
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 12
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "toolkit" => "toolkit" },
        );
    }
    else {
        *toolkit = sub {
            @_ == 1 or croak('Reader "toolkit" usage: $self->toolkit()');
            $_[0]{"toolkit"};
        };
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    1;
}
