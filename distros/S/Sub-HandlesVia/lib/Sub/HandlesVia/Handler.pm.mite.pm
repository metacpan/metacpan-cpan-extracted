{

    package Sub::HandlesVia::Handler;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.010008";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Sub::HandlesVia::Mite", "Sub::HandlesVia::Handler" );
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

        # Attribute name (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 12
        if ( exists $args->{"name"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"name"} ) and do {
                    ref( \$args->{"name"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"name"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "name", "Str";
            $self->{"name"} = $args->{"name"};
        }

        # Attribute template (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 17
        if ( exists $args->{"template"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"template"} ) and do {
                    ref( \$args->{"template"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"template"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "template", "Str";
            $self->{"template"} = $args->{"template"};
        }

        # Attribute lvalue_template (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 22
        if ( exists $args->{"lvalue_template"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"lvalue_template"} ) and do {
                    ref( \$args->{"lvalue_template"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"lvalue_template"} ) ) eq
                      'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "lvalue_template", "Str";
            $self->{"lvalue_template"} = $args->{"lvalue_template"};
        }

        # Attribute args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 27
        do {
            my $value = exists( $args->{"args"} ) ? $args->{"args"} : undef;
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $value;
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or ( !defined($value) )
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "args", "Int|Undef";
            $self->{"args"} = $value;
        };

        # Attribute min_args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
        if ( exists $args->{"min_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $args->{"min_args"};
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"min_args"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "min_args", "Int|Undef";
            $self->{"min_args"} = $args->{"min_args"};
        }

        # Attribute max_args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
        if ( exists $args->{"max_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $args->{"max_args"};
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"max_args"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "max_args", "Int|Undef";
            $self->{"max_args"} = $args->{"max_args"};
        }

        # Attribute signature (type: ArrayRef|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 43
        if ( exists $args->{"signature"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"signature"} ) eq 'ARRAY';
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"signature"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "signature", "ArrayRef|Undef";
            $self->{"signature"} = $args->{"signature"};
        }

        # Attribute usage (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 48
        if ( exists $args->{"usage"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"usage"} ) and do {
                    ref( \$args->{"usage"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"usage"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "usage", "Str";
            $self->{"usage"} = $args->{"usage"};
        }

        # Attribute curried (type: ArrayRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 54
        if ( exists $args->{"curried"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"curried"} ) eq 'ARRAY';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "curried", "ArrayRef";
            $self->{"curried"} = $args->{"curried"};
        }

        # Attribute is_chainable (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
        if ( exists $args->{"is_chainable"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"is_chainable"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "is_chainable", "Bool";
                $self->{"is_chainable"} = $coerced_value;
            };
        }

        # Attribute no_validation_needed (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
        if ( exists $args->{"no_validation_needed"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"no_validation_needed"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "no_validation_needed", "Bool";
                $self->{"no_validation_needed"} = $coerced_value;
            };
        }

        # Attribute is_mutator (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 70
        if ( exists $args->{"is_mutator"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"is_mutator"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "is_mutator", "Bool";
                $self->{"is_mutator"} = $coerced_value;
            };
        }

        # Attribute allow_getter_shortcuts (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 72
        do {
            my $value =
              exists( $args->{"allow_getter_shortcuts"} )
              ? $args->{"allow_getter_shortcuts"}
              : true;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "allow_getter_shortcuts", "Bool";
                $self->{"allow_getter_shortcuts"} = $coerced_value;
            };
        };

        # Attribute prefer_shift_self (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 79
        do {
            my $value =
              exists( $args->{"prefer_shift_self"} )
              ? $args->{"prefer_shift_self"}
              : false;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "prefer_shift_self", "Bool";
                $self->{"prefer_shift_self"} = $coerced_value;
            };
        };

        # Attribute additional_validation (type: CodeRef|Str|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 86
        if ( exists $args->{"additional_validation"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"additional_validation"} ) eq 'CODE';
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        defined( $args->{"additional_validation"} ) and do {
                            ref( \$args->{"additional_validation"} ) eq 'SCALAR'
                              or ref(
                                \( my $val = $args->{"additional_validation"} )
                              ) eq 'SCALAR';
                        }
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"additional_validation"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "additional_validation", "CodeRef|Str|Undef";
            $self->{"additional_validation"} = $args->{"additional_validation"};
        }

        # Attribute default_for_reset (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 91
        if ( exists $args->{"default_for_reset"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"default_for_reset"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "default_for_reset", "CodeRef";
            $self->{"default_for_reset"} = $args->{"default_for_reset"};
        }

        # Attribute documentation (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 96
        if ( exists $args->{"documentation"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"documentation"} ) and do {
                    ref( \$args->{"documentation"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"documentation"} ) ) eq
                      'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "documentation", "Str";
            $self->{"documentation"} = $args->{"documentation"};
        }

        # Attribute _examples (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 101
        if ( exists $args->{"_examples"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"_examples"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "_examples", "CodeRef";
            $self->{"_examples"} = $args->{"_examples"};
        }

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(
/\A(?:_examples|a(?:dditional_validation|llow_getter_shortcuts|rgs)|curried|d(?:efault_for_reset|ocumentation)|is_(?:chainable|mutator)|lvalue_template|m(?:ax_args|in_args)|n(?:ame|o_validation_needed)|prefer_shift_self|signature|template|usage)\z/
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

    # Accessors for _examples
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 101
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "_examples" => "_examples" },
        );
    }
    else {
        *_examples = sub {
            @_ == 1 or croak('Reader "_examples" usage: $self->_examples()');
            $_[0]{"_examples"};
        };
    }

    # Accessors for additional_validation
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 86
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "additional_validation" => "additional_validation" },
        );
    }
    else {
        *additional_validation = sub {
            @_ == 1
              or croak(
'Reader "additional_validation" usage: $self->additional_validation()'
              );
            $_[0]{"additional_validation"};
        };
    }

    # Accessors for allow_getter_shortcuts
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 72
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" =>
              { "allow_getter_shortcuts" => "allow_getter_shortcuts" },
        );
    }
    else {
        *allow_getter_shortcuts = sub {
            @_ == 1
              or croak(
'Reader "allow_getter_shortcuts" usage: $self->allow_getter_shortcuts()'
              );
            $_[0]{"allow_getter_shortcuts"};
        };
    }

    # Accessors for args
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 27
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "args" => "args" },
        );
    }
    else {
        *args = sub {
            @_ == 1 or croak('Reader "args" usage: $self->args()');
            $_[0]{"args"};
        };
    }

    # Accessors for curried
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 54
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "curried" => "curried" },
        );
    }
    else {
        *curried = sub {
            @_ == 1 or croak('Reader "curried" usage: $self->curried()');
            $_[0]{"curried"};
        };
    }

    # Accessors for default_for_reset
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 91
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "default_for_reset" => "default_for_reset" },
        );
    }
    else {
        *default_for_reset = sub {
            @_ == 1
              or croak(
                'Reader "default_for_reset" usage: $self->default_for_reset()');
            $_[0]{"default_for_reset"};
        };
    }

    # Accessors for documentation
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 96
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "documentation" => "documentation" },
        );
    }
    else {
        *documentation = sub {
            @_ == 1
              or croak('Reader "documentation" usage: $self->documentation()');
            $_[0]{"documentation"};
        };
    }

    # Accessors for is_chainable
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "is_chainable" => "is_chainable" },
        );
    }
    else {
        *is_chainable = sub {
            @_ == 1
              or croak('Reader "is_chainable" usage: $self->is_chainable()');
            $_[0]{"is_chainable"};
        };
    }

    # Accessors for is_mutator
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 70
    sub is_mutator {
        @_ == 1 or croak('Reader "is_mutator" usage: $self->is_mutator()');
        (
            exists( $_[0]{"is_mutator"} ) ? $_[0]{"is_mutator"} : (
                $_[0]{"is_mutator"} = do {
                    my $default_value = do {
                        my $to_coerce =
                          $Sub::HandlesVia::Handler::__is_mutator_DEFAULT__->(
                            $_[0] );
                        (
                            (
                                !ref $to_coerce
                                  and (!defined $to_coerce
                                    or $to_coerce eq q()
                                    or $to_coerce eq '0'
                                    or $to_coerce eq '1' )
                            )
                          ) ? $to_coerce
                          : ( ( !!1 ) )
                          ? scalar( do { local $_ = $to_coerce; !!$_ } )
                          : $to_coerce;
                    };
                    (
                        !ref $default_value
                          and (!defined $default_value
                            or $default_value eq q()
                            or $default_value eq '0'
                            or $default_value eq '1' )
                      )
                      or croak( "Type check failed in default: %s should be %s",
                        "is_mutator", "Bool" );
                    $default_value;
                }
            )
        );
    }

    # Accessors for lvalue_template
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 22
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "lvalue_template" => "lvalue_template" },
        );
    }
    else {
        *lvalue_template = sub {
            @_ == 1
              or
              croak('Reader "lvalue_template" usage: $self->lvalue_template()');
            $_[0]{"lvalue_template"};
        };
    }

    # Accessors for max_args
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
    sub max_args {
        @_ == 1 or croak('Reader "max_args" usage: $self->max_args()');
        (
            exists( $_[0]{"max_args"} ) ? $_[0]{"max_args"} : (
                $_[0]{"max_args"} = do {
                    my $default_value = $_[0]->_build_max_args;
                    do {

                        package Sub::HandlesVia::Mite;
                        (
                            (
                                do {
                                    my $tmp = $default_value;
                                    defined($tmp)
                                      and !ref($tmp)
                                      and $tmp =~ /\A-?[0-9]+\z/;
                                }
                            )
                              or ( !defined($default_value) )
                        );
                      }
                      or croak( "Type check failed in default: %s should be %s",
                        "max_args", "Int|Undef" );
                    $default_value;
                }
            )
        );
    }

    # Accessors for min_args
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
    sub min_args {
        @_ == 1 or croak('Reader "min_args" usage: $self->min_args()');
        (
            exists( $_[0]{"min_args"} ) ? $_[0]{"min_args"} : (
                $_[0]{"min_args"} = do {
                    my $default_value = $_[0]->_build_min_args;
                    do {

                        package Sub::HandlesVia::Mite;
                        (
                            (
                                do {
                                    my $tmp = $default_value;
                                    defined($tmp)
                                      and !ref($tmp)
                                      and $tmp =~ /\A-?[0-9]+\z/;
                                }
                            )
                              or ( !defined($default_value) )
                        );
                      }
                      or croak( "Type check failed in default: %s should be %s",
                        "min_args", "Int|Undef" );
                    $default_value;
                }
            )
        );
    }

    # Accessors for name
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 12
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "name" => "name" },
        );
    }
    else {
        *name = sub {
            @_ == 1 or croak('Reader "name" usage: $self->name()');
            $_[0]{"name"};
        };
    }

    # Accessors for no_validation_needed
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "no_validation_needed" => "no_validation_needed" },
        );
    }
    else {
        *no_validation_needed = sub {
            @_ == 1
              or croak(
'Reader "no_validation_needed" usage: $self->no_validation_needed()'
              );
            $_[0]{"no_validation_needed"};
        };
    }

    # Accessors for prefer_shift_self
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 79
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "prefer_shift_self" => "prefer_shift_self" },
        );
    }
    else {
        *prefer_shift_self = sub {
            @_ == 1
              or croak(
                'Reader "prefer_shift_self" usage: $self->prefer_shift_self()');
            $_[0]{"prefer_shift_self"};
        };
    }

    # Accessors for signature
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 43
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "signature" => "signature" },
        );
    }
    else {
        *signature = sub {
            @_ == 1 or croak('Reader "signature" usage: $self->signature()');
            $_[0]{"signature"};
        };
    }

    # Accessors for template
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 17
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "template" => "template" },
        );
    }
    else {
        *template = sub {
            @_ == 1 or croak('Reader "template" usage: $self->template()');
            $_[0]{"template"};
        };
    }

    # Accessors for usage
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 48
    sub usage {
        @_ == 1 or croak('Reader "usage" usage: $self->usage()');
        (
            exists( $_[0]{"usage"} ) ? $_[0]{"usage"} : (
                $_[0]{"usage"} = do {
                    my $default_value = $_[0]->_build_usage;
                    do {

                        package Sub::HandlesVia::Mite;
                        defined($default_value) and do {
                            ref( \$default_value ) eq 'SCALAR'
                              or ref( \( my $val = $default_value ) ) eq
                              'SCALAR';
                        }
                      }
                      or croak( "Type check failed in default: %s should be %s",
                        "usage", "Str" );
                    $default_value;
                }
            )
        );
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        if ( $INC{'Moose/Util.pm'}
            and my $meta = Moose::Util::find_meta( ref $self or $self ) )
        {
            $meta->can('does_role') and $meta->does_role($role) and return 1;
        }
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    1;
}
{

    package Sub::HandlesVia::Handler::Traditional;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.010008";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Sub::HandlesVia::Mite", "Sub::HandlesVia::Handler::Traditional" );
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

    BEGIN {

        use mro 'c3';
        our @ISA;
        push @ISA, "Sub::HandlesVia::Handler";
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

        # Attribute template (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 17
        if ( exists $args->{"template"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"template"} ) and do {
                    ref( \$args->{"template"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"template"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "template", "Str";
            $self->{"template"} = $args->{"template"};
        }

        # Attribute lvalue_template (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 22
        if ( exists $args->{"lvalue_template"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"lvalue_template"} ) and do {
                    ref( \$args->{"lvalue_template"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"lvalue_template"} ) ) eq
                      'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "lvalue_template", "Str";
            $self->{"lvalue_template"} = $args->{"lvalue_template"};
        }

        # Attribute args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 27
        do {
            my $value = exists( $args->{"args"} ) ? $args->{"args"} : undef;
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $value;
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or ( !defined($value) )
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "args", "Int|Undef";
            $self->{"args"} = $value;
        };

        # Attribute min_args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
        if ( exists $args->{"min_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $args->{"min_args"};
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"min_args"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "min_args", "Int|Undef";
            $self->{"min_args"} = $args->{"min_args"};
        }

        # Attribute max_args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
        if ( exists $args->{"max_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $args->{"max_args"};
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"max_args"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "max_args", "Int|Undef";
            $self->{"max_args"} = $args->{"max_args"};
        }

        # Attribute signature (type: ArrayRef|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 43
        if ( exists $args->{"signature"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"signature"} ) eq 'ARRAY';
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"signature"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "signature", "ArrayRef|Undef";
            $self->{"signature"} = $args->{"signature"};
        }

        # Attribute usage (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 48
        if ( exists $args->{"usage"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"usage"} ) and do {
                    ref( \$args->{"usage"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"usage"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "usage", "Str";
            $self->{"usage"} = $args->{"usage"};
        }

        # Attribute curried (type: ArrayRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 54
        if ( exists $args->{"curried"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"curried"} ) eq 'ARRAY';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "curried", "ArrayRef";
            $self->{"curried"} = $args->{"curried"};
        }

        # Attribute is_chainable (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
        if ( exists $args->{"is_chainable"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"is_chainable"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "is_chainable", "Bool";
                $self->{"is_chainable"} = $coerced_value;
            };
        }

        # Attribute no_validation_needed (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
        if ( exists $args->{"no_validation_needed"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"no_validation_needed"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "no_validation_needed", "Bool";
                $self->{"no_validation_needed"} = $coerced_value;
            };
        }

        # Attribute is_mutator (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 70
        if ( exists $args->{"is_mutator"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"is_mutator"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "is_mutator", "Bool";
                $self->{"is_mutator"} = $coerced_value;
            };
        }

        # Attribute allow_getter_shortcuts (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 72
        do {
            my $value =
              exists( $args->{"allow_getter_shortcuts"} )
              ? $args->{"allow_getter_shortcuts"}
              : true;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "allow_getter_shortcuts", "Bool";
                $self->{"allow_getter_shortcuts"} = $coerced_value;
            };
        };

        # Attribute prefer_shift_self (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 79
        do {
            my $value =
              exists( $args->{"prefer_shift_self"} )
              ? $args->{"prefer_shift_self"}
              : false;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "prefer_shift_self", "Bool";
                $self->{"prefer_shift_self"} = $coerced_value;
            };
        };

        # Attribute additional_validation (type: CodeRef|Str|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 86
        if ( exists $args->{"additional_validation"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"additional_validation"} ) eq 'CODE';
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        defined( $args->{"additional_validation"} ) and do {
                            ref( \$args->{"additional_validation"} ) eq 'SCALAR'
                              or ref(
                                \( my $val = $args->{"additional_validation"} )
                              ) eq 'SCALAR';
                        }
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"additional_validation"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "additional_validation", "CodeRef|Str|Undef";
            $self->{"additional_validation"} = $args->{"additional_validation"};
        }

        # Attribute default_for_reset (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 91
        if ( exists $args->{"default_for_reset"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"default_for_reset"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "default_for_reset", "CodeRef";
            $self->{"default_for_reset"} = $args->{"default_for_reset"};
        }

        # Attribute documentation (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 96
        if ( exists $args->{"documentation"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"documentation"} ) and do {
                    ref( \$args->{"documentation"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"documentation"} ) ) eq
                      'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "documentation", "Str";
            $self->{"documentation"} = $args->{"documentation"};
        }

        # Attribute _examples (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 101
        if ( exists $args->{"_examples"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"_examples"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "_examples", "CodeRef";
            $self->{"_examples"} = $args->{"_examples"};
        }

        # Attribute name (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 281
        croak "Missing key in constructor: name" unless exists $args->{"name"};
        do {

            package Sub::HandlesVia::Mite;
            defined( $args->{"name"} ) and do {
                ref( \$args->{"name"} ) eq 'SCALAR'
                  or ref( \( my $val = $args->{"name"} ) ) eq 'SCALAR';
            }
          }
          or croak "Type check failed in constructor: %s should be %s", "name",
          "Str";
        $self->{"name"} = $args->{"name"};

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(
/\A(?:_examples|a(?:dditional_validation|llow_getter_shortcuts|rgs)|curried|d(?:efault_for_reset|ocumentation)|is_(?:chainable|mutator)|lvalue_template|m(?:ax_args|in_args)|n(?:ame|o_validation_needed)|prefer_shift_self|signature|template|usage)\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    my $__XS = !$ENV{PERL_ONLY}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for name
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 281
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "name" => "name" },
        );
    }
    else {
        *name = sub {
            @_ == 1 or croak('Reader "name" usage: $self->name()');
            $_[0]{"name"};
        };
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        if ( $INC{'Moose/Util.pm'}
            and my $meta = Moose::Util::find_meta( ref $self or $self ) )
        {
            $meta->can('does_role') and $meta->does_role($role) and return 1;
        }
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    1;
}
{

    package Sub::HandlesVia::Handler::CodeRef;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.010008";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Sub::HandlesVia::Mite", "Sub::HandlesVia::Handler::CodeRef" );
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

    BEGIN {

        use mro 'c3';
        our @ISA;
        push @ISA, "Sub::HandlesVia::Handler";
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

        # Attribute name (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 12
        if ( exists $args->{"name"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"name"} ) and do {
                    ref( \$args->{"name"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"name"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "name", "Str";
            $self->{"name"} = $args->{"name"};
        }

        # Attribute template (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 17
        if ( exists $args->{"template"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"template"} ) and do {
                    ref( \$args->{"template"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"template"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "template", "Str";
            $self->{"template"} = $args->{"template"};
        }

        # Attribute lvalue_template (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 22
        if ( exists $args->{"lvalue_template"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"lvalue_template"} ) and do {
                    ref( \$args->{"lvalue_template"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"lvalue_template"} ) ) eq
                      'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "lvalue_template", "Str";
            $self->{"lvalue_template"} = $args->{"lvalue_template"};
        }

        # Attribute args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 27
        do {
            my $value = exists( $args->{"args"} ) ? $args->{"args"} : undef;
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $value;
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or ( !defined($value) )
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "args", "Int|Undef";
            $self->{"args"} = $value;
        };

        # Attribute min_args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
        if ( exists $args->{"min_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $args->{"min_args"};
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"min_args"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "min_args", "Int|Undef";
            $self->{"min_args"} = $args->{"min_args"};
        }

        # Attribute max_args (type: Int|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 37
        if ( exists $args->{"max_args"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    (
                        do {
                            my $tmp = $args->{"max_args"};
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    )
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"max_args"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "max_args", "Int|Undef";
            $self->{"max_args"} = $args->{"max_args"};
        }

        # Attribute signature (type: ArrayRef|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 43
        if ( exists $args->{"signature"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"signature"} ) eq 'ARRAY';
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"signature"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "signature", "ArrayRef|Undef";
            $self->{"signature"} = $args->{"signature"};
        }

        # Attribute usage (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 48
        if ( exists $args->{"usage"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"usage"} ) and do {
                    ref( \$args->{"usage"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"usage"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "usage", "Str";
            $self->{"usage"} = $args->{"usage"};
        }

        # Attribute curried (type: ArrayRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 54
        if ( exists $args->{"curried"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"curried"} ) eq 'ARRAY';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "curried", "ArrayRef";
            $self->{"curried"} = $args->{"curried"};
        }

        # Attribute is_chainable (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
        if ( exists $args->{"is_chainable"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"is_chainable"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "is_chainable", "Bool";
                $self->{"is_chainable"} = $coerced_value;
            };
        }

        # Attribute no_validation_needed (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 59
        if ( exists $args->{"no_validation_needed"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"no_validation_needed"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "no_validation_needed", "Bool";
                $self->{"no_validation_needed"} = $coerced_value;
            };
        }

        # Attribute is_mutator (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 70
        if ( exists $args->{"is_mutator"} ) {
            do {
                my $coerced_value = do {
                    my $to_coerce = $args->{"is_mutator"};
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "is_mutator", "Bool";
                $self->{"is_mutator"} = $coerced_value;
            };
        }

        # Attribute allow_getter_shortcuts (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 72
        do {
            my $value =
              exists( $args->{"allow_getter_shortcuts"} )
              ? $args->{"allow_getter_shortcuts"}
              : true;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "allow_getter_shortcuts", "Bool";
                $self->{"allow_getter_shortcuts"} = $coerced_value;
            };
        };

        # Attribute prefer_shift_self (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 79
        do {
            my $value =
              exists( $args->{"prefer_shift_self"} )
              ? $args->{"prefer_shift_self"}
              : false;
            do {
                my $coerced_value = do {
                    my $to_coerce = $value;
                    (
                        (
                            !ref $to_coerce
                              and (!defined $to_coerce
                                or $to_coerce eq q()
                                or $to_coerce eq '0'
                                or $to_coerce eq '1' )
                        )
                      ) ? $to_coerce
                      : ( ( !!1 ) )
                      ? scalar( do { local $_ = $to_coerce; !!$_ } )
                      : $to_coerce;
                };
                (
                    !ref $coerced_value
                      and (!defined $coerced_value
                        or $coerced_value eq q()
                        or $coerced_value eq '0'
                        or $coerced_value eq '1' )
                  )
                  or croak "Type check failed in constructor: %s should be %s",
                  "prefer_shift_self", "Bool";
                $self->{"prefer_shift_self"} = $coerced_value;
            };
        };

        # Attribute additional_validation (type: CodeRef|Str|Undef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 86
        if ( exists $args->{"additional_validation"} ) {
            do {

                package Sub::HandlesVia::Mite;
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"additional_validation"} ) eq 'CODE';
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        defined( $args->{"additional_validation"} ) and do {
                            ref( \$args->{"additional_validation"} ) eq 'SCALAR'
                              or ref(
                                \( my $val = $args->{"additional_validation"} )
                              ) eq 'SCALAR';
                        }
                      }
                      or do {

                        package Sub::HandlesVia::Mite;
                        !defined( $args->{"additional_validation"} );
                    }
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "additional_validation", "CodeRef|Str|Undef";
            $self->{"additional_validation"} = $args->{"additional_validation"};
        }

        # Attribute default_for_reset (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 91
        if ( exists $args->{"default_for_reset"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"default_for_reset"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "default_for_reset", "CodeRef";
            $self->{"default_for_reset"} = $args->{"default_for_reset"};
        }

        # Attribute documentation (type: Str)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 96
        if ( exists $args->{"documentation"} ) {
            do {

                package Sub::HandlesVia::Mite;
                defined( $args->{"documentation"} ) and do {
                    ref( \$args->{"documentation"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"documentation"} ) ) eq
                      'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "documentation", "Str";
            $self->{"documentation"} = $args->{"documentation"};
        }

        # Attribute _examples (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 101
        if ( exists $args->{"_examples"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"_examples"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "_examples", "CodeRef";
            $self->{"_examples"} = $args->{"_examples"};
        }

        # Attribute delegated_coderef (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 302
        croak "Missing key in constructor: delegated_coderef"
          unless exists $args->{"delegated_coderef"};
        do {

            package Sub::HandlesVia::Mite;
            ref( $args->{"delegated_coderef"} ) eq 'CODE';
          }
          or croak "Type check failed in constructor: %s should be %s",
          "delegated_coderef", "CodeRef";
        $self->{"delegated_coderef"} = $args->{"delegated_coderef"};

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(
/\A(?:_examples|a(?:dditional_validation|llow_getter_shortcuts|rgs)|curried|d(?:e(?:fault_for_reset|legated_coderef)|ocumentation)|is_(?:chainable|mutator)|lvalue_template|m(?:ax_args|in_args)|n(?:ame|o_validation_needed)|prefer_shift_self|signature|template|usage)\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    my $__XS = !$ENV{PERL_ONLY}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for delegated_coderef
    # has declaration, file lib/Sub/HandlesVia/Handler.pm, line 302
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "delegated_coderef" => "delegated_coderef" },
        );
    }
    else {
        *delegated_coderef = sub {
            @_ == 1
              or croak(
                'Reader "delegated_coderef" usage: $self->delegated_coderef()');
            $_[0]{"delegated_coderef"};
        };
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        if ( $INC{'Moose/Util.pm'}
            and my $meta = Moose::Util::find_meta( ref $self or $self ) )
        {
            $meta->can('does_role') and $meta->does_role($role) and return 1;
        }
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    1;
}
