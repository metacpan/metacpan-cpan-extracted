package Mite::Attribute;
use Mite::MyMoo;

has class =>
  is            => rw,
  isa           => Object,
  weak_ref      => true;

has name =>
  is            => rw,
  isa           => Str->where('length($_) > 0'),
  required      => true;

has init_arg =>
  is            => rw,
  isa           => Str|Undef,
  default       => sub { shift->name },
  lazy          => true;

has required =>
  is            => rw,
  isa           => Bool,
  default       => false;

has weak_ref =>
  is            => rw,
  isa           => Bool,
  default       => false;

has is =>
  is            => rw,
  isa           => Enum[ ro, rw, rwp, 'lazy', 'bare' ],
  default       => 'bare';

has [ 'reader', 'writer', 'accessor', 'clearer', 'predicate' ] =>
  is            => rw,
  isa           => Str->where('length($_) > 0') | Undef,
  builder       => true,
  lazy          => true;

has isa =>
  is            => 'bare',
  isa           => Str,
  reader        => '_isa',
  init_arg      => 'isa';

has type =>
  is            => 'lazy',
  isa           => Object|Undef,
  builder       => true;

has coerce =>
  is            => 'rw',
  isa           => Bool,
  default       => false;

has default =>
  is            => rw,
  isa           => Maybe[Str|Ref],
  predicate     => 'has_default';

has lazy =>
  is            => rw,
  isa           => Bool,
  default       => false;

has coderef_default_variable =>
  is            => rw,
  isa           => Str,
  lazy          => true,     # else $self->name might not be set
  default       => sub {
      my $self = shift;
      # This must be coordinated with Mite.pm
      return sprintf '$__%s_DEFAULT__', $self->name;
  };

has [ 'trigger', 'builder' ] =>
    is            => rw,
    isa           => Str->where('length($_) > 0') | CodeRef | Undef,
    predicate     => true;

my @method_name_generator = (
    { # public
        reader      => sub { "get_$_" },
        writer      => sub { "set_$_" },
        accessor    => sub { $_ },
        clearer     => sub { "clear_$_" },
        predicate   => sub { "has_$_" },
        builder     => sub { "_build_$_" },
        trigger     => sub { "_trigger_$_" },
    },
    { # private
        reader      => sub { "_get_$_" },
        writer      => sub { "_set_$_" },
        accessor    => sub { $_ },
        clearer     => sub { "_clear_$_" },
        predicate   => sub { "_has_$_" },
        builder     => sub { "_build_$_" },
        trigger     => sub { "_trigger_$_" },
    },
);

sub BUILD {
    my $self = shift;

    croak "Required attribute with no init_arg"
        if $self->required && !defined $self->init_arg;

    if ( $self->is eq 'lazy' ) {
        $self->lazy( true );
        $self->builder( 1 ) unless $self->has_builder;
        $self->is( 'ro' );
    }

    for my $property ( 'builder', 'trigger' ) {
        if ( CodeRef->check( $self->$property ) ) {
            my $coderef = $self->$property;
            my $newname = do {
                my $gen = $method_name_generator[$self->is_private]{$property};
                local $_ = $self->name;
                $gen->( $_ );
            };
            no strict 'refs';
            my $classname;
            if ( $self->class and $classname = $self->class->name ) {
                *{"$classname\::$newname"} = $coderef;
                $self->$property( $newname );
            }
            else {
                croak "Could not install $property => CODEREF as Mite could not determine which class to install it into.";
            }
        }
    }

    for my $property ( 'reader', 'writer', 'accessor', 'clearer', 'predicate', 'builder', 'trigger' ) {
        my $name = $self->$property;
        if ( defined $name and $name eq 1 ) {
            my $gen = $method_name_generator[$self->is_private]{$property};
            local $_ = $self->name;
            my $newname = $gen->( $_ );
            $self->$property( $newname );
        }
    }
}

sub clone {
    my ( $self, %args ) = ( shift, @_ );

    $args{name} //= $self->name;
    $args{is}   //= $self->is;

    # Because undef is a valid default
    $args{default} = $self->default
        if !exists $args{default} and $self->has_default;

    return $self->new( %args );
}

sub is_private {
    ( shift->name =~ /^_/ ) ? 1 : 0;
}

sub _build_reader {
    my $self = shift;
    ( $self->is eq 'ro' || $self->is eq 'rwp' )
        ? $self->name
        : undef;
}

sub _build_writer {
    my $self = shift;
    $self->is eq 'rwp'
        ? sprintf( '_set_%s', $self->name )
        : undef;
}

sub _build_accessor {
    my $self = shift;
    $self->is eq 'rw'
        ? $self->name
        : undef;
}

sub _build_predicate { undef; }

sub _build_clearer { undef; }

sub _build_type {
    my $self = shift;

    my $isa = $self->_isa
        or return undef;

    state $type_registry = do {
        require Type::Registry;
        my $reg = 'Type::Registry'->for_me;
        $reg->add_types('Types::Standard');
        $reg->add_types('Types::Common::Numeric');
        $reg->add_types('Types::Common::String');
        $reg;
    };

    require Type::Utils;
    my $type = Type::Utils::dwim_type(
        $isa,
        fallback => [ 'make_class_type' ],
        for => __PACKAGE__,
    );

    $type
        or croak sprintf 'Type %s cannot be found', $isa;

    $type->can_be_inlined
        or croak sprintf 'Type %s cannot be inlined', $type->display_name;

    if ( $self->coerce ) {
        $type->has_coercion
            or carp sprintf 'Type %s has no coercions', $type->display_name;
        $type->coercion->can_be_inlined
            or carp sprintf 'Coercion to type %s cannot be inlined', $type->display_name;
    }

    return $type;
}

sub has_dataref_default {
    my $self = shift;

    # We don't have a default
    return 0 unless $self->has_default;

    # It's not a reference.
    return 0 if $self->has_simple_default;

    return ref $self->default ne 'CODE';
}

sub has_coderef_default {
    my $self = shift;

    # We don't have a default
    return 0 unless $self->has_default;

    return ref $self->default eq 'CODE';
}

sub has_simple_default {
    my $self = shift;

    return 0 unless $self->has_default;

    # Special case for regular expressions, they do not need to be dumped.
    return 1 if ref $self->default eq 'Regexp';

    return !ref $self->default;
}

sub _empty {
    my $self = shift;

    return ';';
}

sub _compile_coercion {
    my ( $self, $expression ) = @_;
    if ( $self->coerce and my $type = $self->type ) {
        return sprintf 'do { my $to_coerce = %s; %s }',
            $expression, $type->coercion->inline_coercion( '$to_coerce' );
    }
    return $expression;
}

sub _compile_checked_default {
    my ( $self, $selfvar ) = @_;

    my $default = $self->_compile_default( $selfvar );
    my $type = $self->type or return $default;

    local $Type::Tiny::AvoidCallbacks = 1;

    if ( $self->coerce ) {
        $default = $self->_compile_coercion( $default );
    }

    return sprintf 'do { my $default_value = %s; %s or do { require Carp; Carp::croak(q[Type check failed in default: %s should be %s]) }; $default_value }',
        $default, $type->inline_check('$default_value'), $self->name, $type->display_name;
}

sub _compile_default {
    my ( $self, $selfvar ) = @_;

    if ( $self->has_coderef_default ) {
        my $var = $self->coderef_default_variable;
        return sprintf 'do { our %s; %s->(%s) }',
          $var, $var, $selfvar;
    }
    elsif ( $self->has_simple_default ) {
        require B;
        return defined( $self->default ) ? B::perlstring( $self->default ) : 'undef';
    }
    elsif ( $self->has_builder ) {
        return sprintf '%s->%s', $selfvar, $self->builder;
    }

    # should never get here
    return 'undef';
}

sub _compile_trigger {
    my ( $self, $selfvar, @args ) = @_;
    my $method_name = $self->trigger;

    return sprintf '%s->%s( %s )',
        $selfvar, $method_name, join( q{, }, @args );
}

sub compile_init {
    my ( $self, $selfvar, $argvar ) = @_;

    my $init_arg = $self->init_arg;

    my $code = '';
    if ( defined $init_arg ) {
        $code .= sprintf 'if ( exists(%s->{q[%s]}) ) { ',
            $argvar, $init_arg;
        if ( my $type = $self->type ) {
            local $Type::Tiny::AvoidCallbacks = 1;
            my $valuevar = sprintf '%s->{q[%s]}', $argvar, $init_arg;
            if ( $self->coerce ) {
                $code .= sprintf 'my $value = %s; ', $self->_compile_coercion( $valuevar );
                $valuevar = '$value';
            }
            $code .= sprintf '%s or require Carp && Carp::croak(q[Type check failed in constructor: %s should be %s]); ',
                $type->inline_check( $valuevar ),
                $self->init_arg,
                $type->display_name;
            $code .= sprintf '%s->{q[%s]} = %s; ',
                $selfvar, $self->name, $valuevar;
        }
        else {
            $code .= sprintf '%s->{q[%s]} = %s->{q[%s]}; ',
                $selfvar, $self->name, $argvar, $init_arg;
        }
        $code .= ' }';
    }

    if ( $self->has_default || $self->has_builder
    and not $self->lazy ) {
        if ( $code ) {
            $code .= ' else { ';
        }
        else {
            $code .= 'do { ';
        }
        $code .= sprintf 'my $value = %s; ',
            $self->_compile_checked_default( $selfvar );
        $code .= sprintf '%s->{q[%s]} = %s; ',
            $selfvar, $self->name, '$value';
        $code .= ' }';
    }
    elsif ( defined $init_arg
    and $self->required
    and not ($self->has_default || $self->has_builder) ) {
        $code .= sprintf ' else { require Carp; Carp::croak("Missing key in constructor: %s") }',
            $init_arg;
    }

    if ( $self->weak_ref ) {
      $code .= sprintf ' require Scalar::Util && Scalar::Util::weaken(%s->{q[%s]});',
         $selfvar, $self->name;
    }

    if ( $self->trigger ) {
        $code .= ' ' . $self->_compile_trigger(
            $selfvar,
            sprintf( '%s->{q[%s]}', $selfvar, $self->name ),
        ) . ';';
    }

    return $code;
}

my %code_template;
%code_template = (
    reader => sub {
        my $self = shift;
        my %arg = @_;
        my $slot_name = $self->name;
        my $code = sprintf '$_[0]{q[%s]}', $slot_name;
        if ( $self->lazy ) {
            $code = sprintf '( exists($_[0]{q[%s]}) ? $_[0]{q[%s]} : ( $_[0]{q[%s]} = %s ) )',
                $slot_name, $slot_name, $slot_name, $self->_compile_checked_default( '$_[0]' );
        }
        unless ( $arg{no_croak} ) {
            $code = sprintf '@_ > 1 ? require Carp && Carp::croak("%s is a read-only attribute of @{[ref $_[0]]}") : %s',
                $slot_name, $code;
        }
        return $code;
    },
    writer => sub {
        my $self = shift;
        my %arg = @_;
        my $slot_name = $self->name;
        my $code = '';
        if ( $self->trigger ) {
            $code .= sprintf 'my @oldvalue; @oldvalue = $_[0]{q[%s]} if exists $_[0]{q[%s]}; ',
                $slot_name, $slot_name;
        }
        if ( my $type = $self->type ) {
            local $Type::Tiny::AvoidCallbacks = 1;
            my $valuevar = '$_[1]';
            if ( $self->coerce ) {
                $code .= sprintf 'my $value = %s; ', $self->_compile_coercion($valuevar);
                $valuevar = '$value';
            }
            $code .= sprintf '%s or require Carp && Carp::croak(q[Type check failed in %s: value should be %s]); $_[0]{q[%s]} = %s;',
                $type->inline_check($valuevar), $arg{label}//'writer', $type->display_name, $slot_name, $valuevar;
        }
        else {
            $code .= sprintf '$_[0]{q[%s]} = $_[1];', $slot_name;
        }
        if ( $self->trigger ) {
            $code .= ' ' . $self->_compile_trigger(
                '$_[0]',
                sprintf( '$_[0]{q[%s]}', $self->name ),
                '@oldvalue',
            ) . ';';
        }
        if ( $self->weak_ref ) {
            $code .= sprintf ' require Scalar::Util && Scalar::Util::weaken($_[0]{q[%s]});',
                $slot_name;
        }
        $code .= ' $_[0];';
        return $code;
    },
    accessor => sub {
        my $self = shift;
        my %arg = @_;
        my @parts = (
            $code_template{writer}->( $self, label => 'accessor' ),
            $code_template{reader}->( $self, no_croak => true ),
        );
        for my $i ( 0 .. 1 ) {
            $parts[$i] = $parts[$i] =~ /\;/
                ? "do { $parts[$i] }"
                : "( $parts[$i] )"
        }
        sprintf '@_ > 1 ? %s : %s', @parts;
    },
    clearer => sub {
        my $slot_name = shift->name;
        my %arg = @_;
        sprintf 'delete $_[0]->{q[%s]}; $_[0];',
            $slot_name;
    },
    predicate => sub {
        my $slot_name = shift->name;
        sprintf 'exists $_[0]->{q[%s]}',
            $slot_name;
    },
);

sub compile {
    my $self = shift;
    my %args = @_;

    my $xs_condition = $args{xs_condition}
        || '!$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") }';
    my $slot_name = $self->name;

    my %xs_option_name = (
        reader    => 'getters',
        writer    => 'setters',
        accessor  => 'accessors',
        predicate => 'exists_predicates',
    );

    my %want_xs;
    my %want_pp;
    my %method_name;

    for my $property ( keys %code_template ) {
        my $method_name = $self->$property;
        next unless defined $method_name;

        $method_name{$property} = $method_name;
        if ( $xs_option_name{$property} ) {
            $want_xs{$property} = 1;
        }
        $want_pp{$property} = 1;
    }

    # Class::XSAccessor can't do type checks, triggers, or weaken
    if ( $self->type or $self->weak_ref or $self->trigger ) {
        delete $want_xs{writer};
        delete $want_xs{accessor};
    }

    # Class::XSAccessor can't do lazy builders checks
    if ( $self->lazy ) {
        delete $want_xs{reader};
        delete $want_xs{accessor};
    }

    my $code = "# Accessors for $slot_name\n";
    if ( keys %want_xs ) {
        $code .= "if ( $xs_condition ) {\n";
        $code .= "    Class::XSAccessor->import(\n";
        $code .= "        chained => 1,\n";
        for my $property ( sort keys %want_xs ) {
            $code .= "        $xs_option_name{$property} => { q[$method_name{$property}] => q[$slot_name] },\n";
        }
        $code .= "    );\n";
        $code .= "}\n";
        $code .= "else {\n";
        for my $property ( sort keys %want_xs ) {
            $code .= sprintf '    *%s = sub { %s };' . "\n",
                $method_name{$property}, $code_template{$property}->($self);
            delete $want_pp{$property};
        }
        $code .= "}\n";
    }

    for my $property ( sort keys %want_pp ) {
        $code .= sprintf '*%s = sub { %s };' . "\n",
            $method_name{$property}, $code_template{$property}->($self);
    }

    $code .= "\n";

    return $code;
}

1;
