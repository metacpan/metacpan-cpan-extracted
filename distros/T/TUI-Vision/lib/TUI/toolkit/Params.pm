package TUI::toolkit::Params;
# ABSTRACT: Lightweight signature validation inspired by Type::Params

use 5.010;
use strict;
use warnings;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:BRICKPOOL';

# ----------------------------------------------------------------------
# Imports
# ----------------------------------------------------------------------

use B::Deparse    ();
use Carp          ();
use Params::Check ();
use Scalar::Util  ();

BEGIN { sub HAVE_SUB_UTIL () { eval q[ use Sub::Util () ]; !$@ } }

# ----------------------------------------------------------------------
# Exports
# ----------------------------------------------------------------------

use Exporter 'import';

our @EXPORT_OK = qw(
  signature
);

# ----------------------------------------------------------------------
# Define vars, types, templates, ...
# ----------------------------------------------------------------------

our @CARP_NOT = ( __PACKAGE__ );

# built-in Type checker
my $is_Undef     = sub ($) { !defined($_[0]) };
my $is_Str       = sub ($) { defined($_[0]) && ref(\$_[0]) eq 'SCALAR' };
my $is_Bool      = sub ($) { !defined($_[0]) || $_[0] =~ /\A[01]?\z/ };
my $is_Int       = sub ($) { defined($_[0]) && $_[0] =~ /\A-?\d+\z/ };
my $is_Object    = sub ($) { Scalar::Util::blessed($_[0]) };
my $is_Ref       = sub ($) { !!ref($_[0]) };
my $is_ScalarRef = sub ($) { ref($_[0]) eq 'SCALAR' || ref($_[0]) eq 'REF' };
my $is_ArrayRef  = sub ($) { ref($_[0]) eq 'ARRAY' };
my $is_CodeRef   = sub ($) { ref($_[0]) eq 'CODE' };

# syntax templates
my $tmpl_spec = {
  pos => {
    allow => $is_ArrayRef,
  },
  positional => {
    allow => $is_ArrayRef,
  },
  named => {
    allow => $is_ArrayRef,
  },
  named_to_list => { no_override => 1, default => 0 },
  list_to_named => { no_override => 1, default => 0 },
  head          => { no_override => 1 },
  tail          => { no_override => 1 },
  method => {
    allow => [ $is_Bool, $is_Object, $is_CodeRef ],
  },
  description => {
    allow => $is_Str,
  },
  package => {
    allow => $is_Str,
  },
  fallback => { no_override => 1 },
  on_die   => { no_override => 1 },
  strictness => {
    default => 1,
    allow   => $is_Bool,
  },
  multiple => { no_override => 1 },
  message => {
    allow => $is_Str,
  },
  bless          => { no_override => 1, default => 1 },
  class          => { no_override => 1 },
  constructor    => { no_override => 1 },
  returns        => { no_override => 1 },
  returns_scalar => { no_override => 1 },
  returns_list   => { no_override => 1 },
  allow_dash => {
    default => 0,
    allow   => $is_Bool,
  },
  subname => {
    allow => $is_Str,
  },
  caller_level => {
    default => 0,
    allow   => $is_Int,
  },
  next         => { no_override => 1 },
  want_source  => { no_override => 1, default => 0 },
  want_details => { no_override => 1, default => 0 },
  want_object  => { no_override => 1, default => 0 },
};

my $tmpl_param = {
  optional => {
    default => 0,
    allow   => $is_Bool,
  },
  slurpy => {
    default => 0,
    allow   => $is_Bool,
  },
  default => {
    allow => [ $is_Ref, $is_Str, $is_Undef ],
  },
  default_on_undef => { no_override => 1, default => 0 },
  coerce           => { no_override => 1, default => 0 },
  clone            => { no_override => 1, default => 0 },
  name             => { no_override => 1 },
  getter           => { no_override => 1 },
  predicate        => { no_override => 1 },
  alias => {
    allow => [ $is_Str, $is_ArrayRef ],
  },
  in_list    => { no_override => 1, default => 0 },
  strictness => { no_override => 1, default => 1 },
};

sub _croak ($);

# ----------------------------------------------------------------------
# Public API
# ----------------------------------------------------------------------

#
# Build-time constructor for a positional parameter validator.
#
# This function performs the following steps:
#
#   1. Parse the raw specification into a Signature structure. The Signature 
#      contains a Parameter structure for all fixed or named parameters and 
#      optionally one slurpy parameter.
#
#   2. Precompute all static metadata needed for efficient runtime
#      execution.
#
#   3. Pre-generate type-check closures for each parameter. These closures 
#      perform the actual runtime validation of individual values.
#
#   4. Pre-generate the slurpy checker (if present), which validates
#      the arrayref of remaining arguments.
#
#   5. Returns the final runtime executor closure. The executor performs:
#         - arity validation
#         - type checking
#         - default and optional handling
#         - alias handling
#         - slurpy collection
#
# The returned closure is the actual validator that will be invoked
# for each call site. Most expensive work is done at build time.
#
sub signature {
  my $norm     = _validate_specs( @_ );
  my $parsed   = _expand_specs( $norm );
  my $compiled = _execute_signature( $parsed );
  return $compiled;
}

# ----------------------------------------------------------------------
# Parser
# ----------------------------------------------------------------------

# Validate and normalize top level specifications
# - Param: %spec hash including the raw specs
# - Returns: a validated and normalized signature hash ref
sub _validate_specs {    # \%signature (%spec)
  local $Params::Check::PRESERVE_CASE        = 1;
  local $Params::Check::STRIP_LEADING_DASHES = 0;
  local $Params::Check::ALLOW_UNKNOWN        = 0;

  # Pre-Validate the spec
  my $spec = { @_ };
  for ( keys %$spec  ) {
    Carp::croak "Unknown parameter '$_'" if not exists $tmpl_spec->{$_};
  }

  $spec = Params::Check::check( $tmpl_spec, $spec )
    or Carp::croak Params::Check::last_error();

  # Check mutually exclusive pos/positional/named/multiple
  grep( exists $spec->{$_}, qw( pos positional named multiple ) ) == 1
    or Carp::croak "The Specification must contain exactly one of the ". 
      "options: pos, positional, named, or multiple";

  # Extract parts
  my $caller_level = $spec->{caller_level};
  my ( $package, undef, undef, $subname ) = caller( $caller_level + 2 );
  my $method   = $spec->{method};
  my $pos      = $spec->{pos} || $spec->{positional} || [];
  my $named    = $spec->{named} || [];

  # Init result signature hash
  my $sig = {
    package      => $package,
    subname      => $subname,
    method       => $method,
    parameters   => [],
    strictness   => $spec->{strictness} ? 1 : 0,
    is_named     => @$named ? 1 : 0,
    allow_dash   => $spec->{allow_dash} ? 1 : 0,
    pos          => $pos,
    named        => $named,
    caller_depth => $caller_level,
  };

  return $sig;
}

# Expand raw spec into param specs
# - Param: \%signature structure including the normalized specs
# - Returns: a signature hash ref representing the parsed specs
sub _expand_specs {    # \%signature (\%signature)
  my ( $sig ) = @_;

  # Extract parts
  my $method   = $sig->{method};
  my $pos      = $sig->{pos};
  my $named    = $sig->{named};
  my $is_named = $sig->{is_named};

  # flags and helpers
  my $has_method = 0;
  my $has_optional = 0;
  my $has_slurpy = 0;

  my @params;
  my $slurpy;
  my %alias_of;
  
  # Method handling: build method param if given
  if ( $method ) {
    my $isa = ref $sig->{method}
            ? $sig->{method} 
            : sub { defined $_[0] };

    # pre-compile method checker
    my $type_check   = _generate_type_checker( $isa );
    my $method_check = sub {
      my ( $val ) = @_;
      return $type_check->( $val, '$_[0]' );
    };
  
    $method = {
      isa      => $isa,
      optional => 0,
      name     => '$_[0]',
      alias    => [],
      check    => $method_check,
    };

    $has_method = 1;
  }

  #
  # Parse named parameters
  #   Format: named => [ name => $type, { options }, name2 => $type2, ... ]
  #   options may contain: optional, default, alias, slurpy
  #
  if ( $is_named ) {

    my $i = 0;
    while ( $i < @$named ) {
      my $name = $named->[ $i++ ];
      my $type = $named->[ $i++ ];
      my $label = sprintf '$_{"%s"}', $name;

      my $opts = {};
      if ( $i < @$named && ref $named->[$i] eq 'HASH' ) {
        $opts = $named->[ $i++ ];
      }

      # validate opts
      for ( keys %$opts ) {
        Carp::croak "Unknown parameter '$_'" unless exists $tmpl_param->{$_};
      }
      $opts = Params::Check::check( $tmpl_param, $opts )
        or Carp::croak Params::Check::last_error();

      # normalize default (if present)
      my $default;
      if ( exists $opts->{default} ) {
        $default = _materialize_default( $opts->{default} );
        $opts->{optional} = 1;    # default implies optional
      }

      # slurpy handling
      if ( $opts->{slurpy} ) {
        Carp::croak "Slurpy parameter cannot be optional"
          if $opts->{optional};
        Carp::croak "Slurpy parameter must not appear more than once" 
          if $has_slurpy;

        $has_slurpy = 1;

        # pre-compile slurpy checker
        my $type_check   = _generate_type_checker( $type );
        my $slurpy_check = sub {
          my ( $val ) = @_;
          return $type_check->( $val, $label );
        };

        $slurpy = {
          isa      => $type,
          optional => 1,
          name     => $name,
          alias    => [],
          check    => $slurpy_check,
          is_hash  => 1,        # for named slurpy we always treat as hash
        };

        next;    # do not push into params
      }

      # optionals flag
      # $has_optional = 1 if $opts->{optional};

      # alias handling
      my @aliases = ();
      if ( defined $opts->{alias} ) {
        my $aref = ref $opts->{alias} eq 'ARRAY'
                 ? $opts->{alias}
                 : [ $opts->{alias} ];

        foreach my $a ( @$aref ) {
          Carp::croak "Alias '$a' duplicates existing parameter"
            if exists $alias_of{$a}
            || grep { $_->{name} eq $a } @params;

          $alias_of{$a} = $name;
          push @aliases => $a;
        }
      }

      # pre-compile checkers for named parameters
      my $type_check = _generate_type_checker( $type );
      my $param_check = sub {
        my ( $val ) = @_;
        return $type_check->( $val, $label );
      };

      # build param hash
      my $param = {
        isa      => $type,
        optional => $opts->{optional} ? 1 : 0,
        name     => $name,
        alias    => \@aliases,
        check    => $param_check,
      };
      $param->{default} = $default if exists $opts->{default};

      push @params => $param;
    }
  }

  #
  # Parse positional parameters
  #   Format: pos/positional => [ $type, { options }, $type2, ... ]
  #   options may contain: optional, default, slurpy
  #
  else {

    my $offset = $has_method ? 1 : 0;
    my $i = 0;
    while ( $i < @$pos ) {
      my $name = sprintf '$_[%d]', @params + $offset;
      my $type = $pos->[ $i++ ];

      my $opts = {};
      if ( $i < @$pos && ref( $pos->[$i] ) eq 'HASH' ) {
        $opts = $pos->[ $i++ ];
      }

      # validate opts
      for ( keys %$opts ) {
        Carp::croak "Unknown parameter '$_'" unless exists $tmpl_param->{$_};
      }
      $opts = Params::Check::check( $tmpl_param, $opts )
        or Carp::croak Params::Check::last_error();

      # normalize default (if present)
      my $default;
      if ( exists $opts->{default} ) {
        $default = _materialize_default( $opts->{default} );
        $opts->{optional} = 1;    # default implies optional
      }

      # slurpy handling
      if ( $opts->{slurpy} ) {
        Carp::croak "Slurpy parameter cannot be optional"
          if $opts->{optional};
        Carp::croak "Parameter following slurpy parameter"
          if $i < @$pos;

        $has_slurpy = 1;

        # pre-compile slurpy checker
        my $type_check   = _generate_type_checker( $type );
        my $slurpy_check = sub {
          my ( $val ) = @_;
          return $type_check->( $val, '$SLURPY' );
        };

        my $is_hash = _detect_slurpy_is_hash( $type ) ? 1 : 0;

        $slurpy = {
          isa      => $type,
          optional => 0,
          name     => '$SLURPY',
          alias    => [],
          check    => $slurpy_check,
          is_hash  => $is_hash,
        };

        next;
      }

      # optional-block rule
      if ( $opts->{optional} ) {
        $has_optional = 1;
      }
      elsif ( $has_optional ) {
        Carp::croak "Non-Optional parameter following Optional parameter";
      }

      # alias not really supported for pos
      if ( defined $opts->{alias} ) {
        Carp::carp "alias not supported for positional parameters";
      }

      # pre-compile checkers for fixed parameters
      my $type_check = _generate_type_checker( $type );
      my $param_check = sub {
        my ( $val ) = @_;
        return $type_check->( $val, $name );
      };

      # build param hash
      my $param = {
        isa      => $type,
        optional => $opts->{optional} ? 1 : 0,
        name     => $name,
        alias    => [],
        check    => $param_check,
      };
      $param->{default} = $default if exists $opts->{default};

      push @params => $param;
    }
  }

  # finalize $sig
  $sig->{method}     = $method;
  $sig->{parameters} = \@params;
  $sig->{slurpy}     = $slurpy;

  return $sig;
}

# ----------------------------------------------------------------------
# Executor
# ----------------------------------------------------------------------

# Constructs the runtime executor for a compiled signature.
# - Params: \%signature with precompiled checker
# - Returns: a code ref to validate the arguments -> sub (@_)
sub _execute_signature {    # \&executor (\%signature)
  my ( $sig ) = @_;

  # Flags for optional and alias
  my $has_optional = !! grep { $_->{optional}   } @{ $sig->{parameters} };
  my $has_aliases  = !! grep { @{ $_->{alias} } } @{ $sig->{parameters} };

  # generate named executor
  if ( $sig->{is_named} ) {
    return _executor_named_hot( $sig )
      if !defined $sig->{slurpy}
      && !$sig->{allow_dash}
      && !$sig->{strictness}
      && !$has_optional
      && !$has_aliases;

    return _executor_named_cold( $sig );
  }

  # generate positional executor
  return _executor_pos_hot( $sig )
    if defined $sig->{method} 
    && !defined $sig->{slurpy}
    && !$has_optional;

  return _executor_pos_cold( $sig );
}

# Fast path for simple named signatures: NO slurpy, NO alias, BUT method
# - Params: \%signature with precompiled checker
# - Returns: coderef of a pre compiled named parameter checker
sub _executor_named_hot {    # \&executor (\%signature)
  my ( $sig ) = @_;

  # Precompute checkers and required names
  my $method_check = $sig->{method}{check};
  my $method_name  = $sig->{method}{name};
  my %check_for    = map { $_->{name} => $_->{check} } @{ $sig->{parameters} };
  my @required     = sort keys %check_for;

  return sub {
    local $Carp::CarpLevel = $Carp::CarpLevel + $sig->{caller_depth} + 1;

    my $proto = shift;
    $method_check->( $proto, $method_name );
    
    _croak "Odd number of named parameters" unless @_ % 2;

    my %args = @_;

    for my $name ( @required ) {
      exists $args{$name}
        or _croak "Missing required named parameter '$name'";

      eval { $check_for{$name}->( $args{$name}, $name ); 1 }
        or _croak( $@ );
    }

    return ( $proto, \%args );
  };
}

# Handles all named cases (slurpy, alias, method, ...)
# - Params: \%signature with precompiled checker
# - Returns: coderef of a pre compiled named parameter checker
sub _executor_named_cold {    # \&executor (\%signature)
  my ( $sig ) = @_;

  # Extract specs from signature
  my @params   = @{ $sig->{parameters} };
  my $method   = $sig->{method};
  my $slurpy   = $sig->{slurpy};

  my %alias_of;
  for my $p ( @params ) {
    $alias_of{$_} = $p->{name} for @{ $p->{alias} };
  }

  # Flags
  my $has_method = defined $method;
  my $has_slurpy = defined $slurpy;
  my $strict     = $sig->{strictness};
  my $allow_dash = $sig->{allow_dash};

  return sub {
    # Adjust Carp stack level so errors point to the caller of the signature
    local $Carp::CarpLevel = $Carp::CarpLevel + $sig->{caller_depth} + 1;

    my $argc = @_;

    # Optional method handling
    my $self;
    if ( $has_method ) {
      $self = shift;
      eval { $method->{check}->( $self, $method->{name} ); 1 }
        or _croak( $@ );
      $argc--;
    }

    # Quick even-number check
    _croak("Odd number of named parameters") if @_ % 2;

    # Strip leading dash (optional)
    my %raw;
    if ( $allow_dash ) {
      while ( @_ ) {
        my ( $key, $val ) = ( shift, shift );
        $key =~ s/^-//;
        $raw{$key} = $val;
      }
    }
    else {
      %raw = @_;
    }

    # Apply alias mapping: alias_of => main
    my %args = %raw;
    for my $alias ( keys %alias_of ) {
      next unless exists $raw{$alias};

      my $main = $alias_of{$alias};

      if ( exists $raw{$main} ) {
        _croak "Superfluous alias \"$alias\" for argument \"$main\"";
      }

      # move alias value to main key
      $args{$main} = delete $args{$alias};
    }

    # Fixed parameter processing: required/optional/default
    my %out;     # name -> value
    my %used;    # keys consumed by fixed params
    for my $p ( @params ) {
      my $name = $p->{name};
      my $val;

      # argument provided?
      if ( exists $args{$name} ) {
        $val = $args{$name};
        $used{$name} = 1;
      }

      # default provided?
      elsif ( ref $p->{default} ) {
        $val = $p->{default}->( $self )
      }

      # optional without default
      elsif ( $p->{optional} ) {
        next
      }

      else {
        _croak( "Missing required named parameter '$name'" );
      }

      # Run type check
      eval { $p->{check}->( $val, $name ); 1 }
        or _croak( $@ );
      $out{$name} = $val;
    }

    # Slurpy or unknown-key handling
    my %rest = map { $_ => $args{$_} } grep { !$used{$_} } keys %args;

    if ( $has_slurpy ) {
      my $val;
      if ( $slurpy->{is_hash} ) {
        # Hash-style slurpy: pass remaining key/value pairs as hashref
        $val = \%rest;
      }
      else {
        # Fallback: array-style slurpy for named (rare case)
        my @pairs;
        for my $key ( keys %rest ) {
          push @pairs, $key, $rest{$key};
        }
        $val = \@pairs;
      }
      eval { $slurpy->{check}->( $val, $slurpy->{name} ); 1 }
        or _croak( $@ );

      $out{ $slurpy->{name} } = $val;
    }
    else {
      # No slurpy and strictness: detect unknown keys
      if ( $strict && %rest ) {
        my @unknown = sort keys %rest;
        _croak( "Unknown named parameter(s): " . join( ", ", @unknown ) );
      }
    }

    return ( $self, \%out ) if $has_method;
    return \%out;
  };
}

# Fast path for simple positional signatures: NO method, NO optional, NO slurpy
# - Params: \%signature with precompiled checker
# - Returns: coderef of a pre compiled positional parameter checker
sub _executor_pos_hot {    # \&executor (\%signature)
  my ( $sig ) = @_;

  # Precompute arity and checkers
  my $arity = scalar @{ $sig->{parameters} };
  my @check_for = map { $_->{check} } @{ $sig->{parameters} };

  # Optional method at position 0
  if ( my $method = $sig->{method} ) {
    $arity++;
    unshift @check_for => $method->{check};
  }

  return sub {
    local $Carp::CarpLevel = $Carp::CarpLevel + $sig->{caller_depth} + 1;

    # Fixed arity check
    if ( @_ != $arity ) {
      my $argc = @_;
      _croak "Wrong number of parameters; got $argc; expected $arity";
    }

    # Validate all arguments in-place
    for my $i ( 0 .. $#check_for ) {
      eval { $check_for[$i]->( $_[$i], "\$_[$i]" ); 1 }
        or _croak( $@ );
    }

    # Hot path: return @_ unchanged
    return @_;
  };
}

# Handles all positional cases (method, optional, slurpy ...)
# - Params: \%signature with precompiled checker
# - Returns: coderef of a pre compiled positional parameter checker
sub _executor_pos_cold {    # \&executor (\%signature)
  my ( $sig ) = @_;

  # Extract specs from signature
  my @params = @{ $sig->{parameters} };
  my $method = $sig->{method};
  my $slurpy = $sig->{slurpy};

  # Flags
  my $has_method = defined $method;
  my $has_slurpy = defined $slurpy;

  # Precompute arity
  my $offset    = $has_method ? 1 : 0;
  my $min_arity = $offset + scalar grep { !$_->{optional} } @params;
  my $max_arity = $offset + scalar @params;

  return sub {
    local $Carp::CarpLevel = $Carp::CarpLevel + $sig->{caller_depth} + 1;

    my $argc = @_;

    # Arity checks
    my $too_few  = $argc < $min_arity;
    my $too_many = !$has_slurpy && $argc > $max_arity;

    if ( $too_few || $too_many ) {
      my $expected = $has_slurpy              ? "at least $min_arity"
                   : $min_arity == $max_arity ? "$min_arity"
                   :                            "$min_arity to $max_arity";

      _croak "Wrong number of parameters; got $argc; expected $expected";
    }

    my @out;

    # Method handling (optional)
    my $self;
    if ( $has_method ) {
      $self = shift;
      eval { $method->{check}->( $self, $method->{name} ); 1 }
        or _croak( $@ );
      $argc--;
      push @out, $self;
    }

    # Validate fixed (non-slurpy) positional arguments
    for my $i ( 0 .. $#params ) {
      my $p = $params[$i];
      my $name = $p->{name};
      my $val;

      # argument provided?
      if ( $i < $argc ) {
        $val = $_[$i];
      }

      # default provided?
      elsif ( ref $p->{default} ) {
        $val = $p->{default}->( $self )
      }

      # optional without default -> stop, no further checks
      elsif ( $p->{optional} ) {
        last;
      }

      # Run type check
      eval { $p->{check}->( $val, $name ); 1 }
        or _croak( $@ );
      push @out, $val;
    }

    # If there is no slurpy parameter, just return
    return @out unless $has_slurpy;

    # Slurpy: arrayref or hashref of remaining args (empty is allowed)
    my $rest = [];
    my $slurpy_ofs = scalar @params;
    my $slurpy_len = $argc - $slurpy_ofs;

    if ( $slurpy_len > 0 ) {
      my $slurpy_is_hash = $slurpy->{is_hash};

      # Special case: number of remaining parameters is 1
      if ( $slurpy_len == 1 ) {
        my $last = $_[-1];
        if ( !$slurpy_is_hash ) {
          $rest = [$last];
        }
        elsif ( ref $last ne 'HASH' ) {
          $rest = {$last};
        }
        else {
          $rest = $last;
        }
      }

      # Default case: process remaining parameters
      else {
        my @slurpy_args = @_[ $slurpy_ofs .. $slurpy_ofs + $slurpy_len - 1 ];
        if ( $slurpy_is_hash ) {
          _croak "Odd number of elements in slurpy hash parameter"
            if @slurpy_args % 2;
          $rest = {@slurpy_args};
        }
        else {
          $rest = \@slurpy_args;
        }
      }

      # Check remaining parameters in a single step
      eval { $slurpy->{check}->( $rest, $slurpy->{name} ); 1 }
        or _croak( $@ );
    }

    # Return fixed values plus array ref for slurpy
    return ( @out, $rest );
  };

}

# ----------------------------------------------------------------------
# Utilities
# ----------------------------------------------------------------------

# Generate a checker subroutine for a single type. 
# - Param: $isa as a type object or CODE reference
# - Returns: a code reference for on signature-entry -> sub ($value, $label)
sub _generate_type_checker {    # \&check ($isa)
  my ( $isa ) = @_;

  # 1. Type::API::Constraint::Inlinable (e.g. Type::Standard)
  if ( Scalar::Util::blessed( $isa )
    && $isa->DOES( "Type::API::Constraint::Inlinable" )
    && $isa->can_be_inlined
  ) {
    # Ask the type for inline code; it may use $val, $_[1], or local $_
    my $inline = $isa->inline_check( '$val' );

    # Build the low-level predicate: ($isa, $value) -> bool
    my $check = do {
      local $@;
      eval "sub { my (\$isa, \$val) = \@_; $inline; }"
        or Carp::croak "Error compiling inline predicate: $@";
    };

    # High-level checker: ($value, $label) -> $value or croak
    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $isa->$check( $val );
      die( $isa->get_message( $val ) . " (in $label)\n" );
    };
  }

  # 2. Type::API::Constraint (non-inlinable)
  elsif ( Scalar::Util::blessed( $isa )
    && $isa->DOES( "Type::API::Constraint" )
  ) {
    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $isa->check( $val );
      die( $isa->get_message( $val ) . " (in $label)\n" );
    };
  }

  # 3. Generic Type::API-style object with ->check
  elsif ( Scalar::Util::blessed( $isa ) && $isa->can( 'check' ) ) {

    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $isa->check( $val );

      my $msg = $isa->can( 'get_message' )
              ? $isa->get_message( $val )
              : "Argument did not pass type constraint";

      die( "$msg (in $label)\n" );
    };
  }

  # 4. plain CODE reference
  elsif ( ref( $isa ) eq 'CODE' ) {
    my $name = _coderef2text( $isa );
    if ( HAVE_SUB_UTIL ) {
      my $subname = Sub::Util::subname( $isa );
      $name = $subname if $subname && $subname !~ /::__ANON__$/;
    } 

    return sub {
      my ( $val, $label ) = @_;
      local $_ = $val;

      return $val if $isa->( $val );

      my $desc = !defined( $val ) ? "Undef"
               : ref( $val )      ? "Reference $val"
               :                    "Value \"$val\"";

      die( "$desc did not pass type constraint $name (in $label)\n" );
    };
  }

  # 5. Unsupported type specification
  return sub {
    my ( undef, $label ) = @_;
    die( "Unsupported type definition for argument $label\n" );
  };
}

# Inspects a potential slurpy type and determines whether it behaves like a 
# HashRef.
# - Param: $isa as a type object or CODE reference
# - Returns: a boolean value evaluates to true for a hash
sub _detect_slurpy_is_hash {    # $bool ($isa)
  my ( $isa ) = @_;

  # 1. Type object with ->name that starts with "HashRef"
  return 1 
    if Scalar::Util::blessed( $isa )
    && $isa->can( 'name' ) 
    && $isa->name =~ /^HashRef/;

  # 2. Type object with ->check that accepts {} but not []
  return 1
    if Scalar::Util::blessed( $isa ) 
    && $isa->can( 'check' )
    && $isa->check( {} ) && !$isa->check( [] );

  # 3. Fallback: use $isa as coderef
  local $@;
  return eval { $isa->( {} ) } && !eval { $isa->( [] ) };
}

# Validate and normalize default value (if any)
# - Param: the $default option
# - Returns: the validated and normalized default -> sub { $self }
sub _materialize_default {    # $default ($default)
  my ( $default ) = @_; 

  if ( !defined $default ) {
    return sub { undef };
  }
  elsif ( !ref $default ) {
    return sub { $default };
  }
  elsif ( ref $default eq 'CODE' ) {
    return $default;
  }
  elsif ( ref $default eq 'ARRAY' && @$default == 0 ) {
    return sub { [] };
  }
  elsif ( ref $default eq 'HASH' && !keys %$default ) {
    return sub { {} };
  }
  elsif ( ref $default eq 'SCALAR' && !ref $$default ) {
    # compile scalar-ref code
    my $src = $$default;
    return do {
      local $@;
      eval "sub { $src }"
        or Carp::croak "Invalid default expression '$src': $@";
    };
  }

  Carp::croak "Default expected to be undef, string, coderef, or empty " .
    "arrayref/hashref";
}

# Reconstructs the code from Perl's internal syntax tree 
# - Param: $code is a type constraint CODE reference
# - Returns: A string that maps the code reference from Perl's Optree.
sub _coderef2text {
  my ( $code ) = @_;
  state $DEPARSE = B::Deparse->new( "-P", "-sC" );
  my $body = $DEPARSE->coderef2text( $code );
  for ( $body ) {
    s/^\h+(?:use|no) (?:strict|warnings|feature|integer|utf8|bytes|re)\b[^\n]*\n//gm;
    s/^\h+package [^\n]*;\n//gm;
    s/\A\{\n\h+([^\n;]*);\n\}\z/{ $1 }/;
  }
  return $body;
}

# Lightweight Carp-style exception using caller and $Carp::CarpLevel
# - Param: $msg is the error message
# - Effect: Dies with a message tagged with the adjusted caller location
sub _croak ($) {
  my $error = shift || 'Unknown error';
  $error =~ s/\s+at \S+ line \d+\.?\s*$//;
  my $msg = Carp::shortmess( $error );
  unless ( $Carp::Verbose ) {
    my ( undef, $file, $line ) = caller( $Carp::CarpLevel + 1 );
    if ( $file ) {
      $msg =~ s/\s+at \S+ line \d+\.?\s*$/ at $file line $line.\n/s;
    }
  }
  die $msg;
}

1

__END__

=pod

=head1 NAME

TUI::toolkit::Params - Lightweight signature validation inspired by Type::Params

=head1 SYNOPSIS

  use TUI::toolkit::Params qw( signature );
  use Type::Standard qw( ArrayRef Int );
  use Scalar::Util qw( looks_like_number );

  # Basic example
  sub add_numbers {
    state $sig = signature(
      pos => [
        Int,                 # Type::API / Type::Tiny compatible object
        sub { /^\d+$/ },     # custom CODE predicate
      ],
    );

    my ($x, $y) = $sig->(@_);
    return $x + $y;
  }

  say add_numbers(3, 5);      # ok
  say add_numbers(3, "abc");  # dies with descriptive error message

  # Example with slurpy parameter
  sub sum {
    state $sig = signature(
      pos => [
        Int,
        ArrayRef[Int], { slurpy => 1 },
      ],
    );

    my ($first, $rest) = $sig->(@_);   # $rest is an arrayref
    my $sum = $first;
    $sum += $_ for @$rest;
    return $sum;
  }

  say sum(1, 2, 3, 4);  # ok
  say sum(1, "x");      # dies with descriptive error

  # Example with optional parameters
  sub vector_length {
    state $sig = signature(
      pos => [
        \&looks_like_number,                      # x (mandatory)
        \&looks_like_number, { optional => 1 },   # y (optional)
        \&looks_like_number, { optional => 1 },   # z (optional)
      ],
    );

    my ($x, $y, $z) = $sig->(@_);

    # Missing optional components default to zero
    $y //= 0;
    $z //= 0;

    return sqrt($x*$x + $y*$y + $z*$z);
  }

  say vector_length(3, 4);       # 2D -> 5
  say vector_length(3, 4, 12);   # 3D -> 13

  # Example with defaults
  sub compute_magic {
    state $sig = signature(
      pos => [
        Int,                                   # required
        Int, { default => 10 },                # default integer value
        Int, { default => "999" },             # default string
        Int, { default => sub { 2 * 21 } },    # compiled into 42
        Int, { default => \'6 * 111' },        # smarter into 666
      ],
    );

    my ($x, $y, $a, $b, $c) = $sig->(@_);
    return $x * $y + $a + $b + $c;
  }

  # Named example
  sub create_user {
    state $sig = signature(
      named => [
        name => Str,
        age  => Int, { optional => 1 },
      ],
    );
    my ($args) = $sig->(@_);
    return "User $args->{name}, $args->{age}";
  }

  # Method signatures
  sub do_it {
    state $sig = signature(
      method => Object,
      pos    => [ Int ],
    );
    my ($self, $i) = $sig->(@_);
    ...;
  }

=head1 DESCRIPTION

The function C<signature> provides a lightweight mechanism for validating
positional arguments to Perl subroutines. It is inspired by L<Type::Params>,
but intentionally simpler and without dependencies on XS or Perl components 
that are not part of the standard distribution.

The module accepts a list of type specifications and returns a compiled
checker subroutine. This checker performs:

=over 4

=item * arity validation

=item * type checking via Type::API or plain CODE predicates

=item * default value handling

=item * optional parameters

=item * method invocant support

=item * slurpy parameters (hash or array semantics)

=item * named alias resolution

=back

All type checking logic is compiled once at signature creation time,
resulting in faster validation than doing checks inside the subroutine body.

=head1 SIGNATURE SPECIFICATION

=head2 C<pos> / C<positional>

  signature(
    pos => [
      Int,
      Str,     { optional => 1 },
      HashRef, { slurpy   => 1 },
    ],
  );

Positional parameters are specified as alternating C<TYPE> and optional 
C<\{OPTIONS\}> entries.

=head2 C<named>

  signature(
    named => [
      foo => Int,
      bar => Str,     { optional => 1 },
      baz => HashRef, { slurpy   => 1 },
    ],
  );

Named signatures take key/value pairs followed by optional option hashes.

=head2 C<method>

The C<method> option provides syntactic sugar for defining method invocants
in a positional signature. It prepends an additional, non-optional positional
parameter to the beginning of the signature.

This parameter is treated exactly like any other entry in C<pos>, and supports
the same type specifications (Type::Tiny, Type::API, CODE predicates, etc.).

=head3 method => 1

Using C<< method => 1 >> prepends a predicate for a basic check. This means:

=over 4

=item * An invocant is required (arity increases by one).

=item * The invocant is not undefined.

=item * The implementation simply uses a C<sub { defined }> predicate.

=back

Example:

  signature(
    method => 1,
    pos    => [ Int, Str ],
  );

behaves exactly like:

  signature(
    pos => [ sub { defined }, Int, Str ],
  );

=head3 method => $isa

If the argument is a type object or predicate, it is prepended as-is to the
positional parameter list. This allows expressing object or class method
signatures declaratively.

Examples:

  signature(
    method => Object,
    pos    => [ Int ],
  );

is equivalent to:

  signature(
    pos => [ Object, Int ],
  );

If neither C<pos> nor C<positional> is provided, an empty positional list is
created automatically, and the method parameter is prepended. This allows
signatures consisting solely of an invocant.

=head1 PARAMETER OPTIONS

=head2 C<optional>

Optional parameters may be declared by attaching a hashref:

  pos => [
    Int,
    Str, { optional => 1 },
    Str, { optional => 1 },
  ]

Rules:

=over 4

=item *

Optional parameters must appear as one continuous block at the end of
the non-slurpy parameters on positional signatures.

=item *

A mandatory parameter after an optional parameter is an error for positional 
signatures.

=item *

Missing optional values are returned as C<undef>.

=back

=head2 C<default>

Parameters may define a default value using C<< default => ... >> inside the
option hashref:

  positional => [
    Int,
    Int, { default => 42 },          # simple scalar
    Int, { default => \"333 * 2" },  # string ref
  ];

Any parameter with a default is automatically optional.

Supported forms of default values are:

=over 4

=item * C<undef>

=item * Plain non-reference scalars (strings or numbers)

=item * Empty arrayrefs (C<[]>)

=item * Empty hashrefs (C<{}>)

=item * CODE references, which are executed to generate the default value

=item * SCALAR references containing a string of Perl source code

=back

Unsupported defaults will cause an exception at signature construction time.

Default values are validated against the parameter type, just like explicit
arguments.

=head2 C<slurpy>

A single slurpy parameter may be declared:

  pos => [
    Int,
    ArrayRef[Int], { slurpy => 1 },
  ]

Rules:

=over 4

=item *

The slurpy parameter must be the last entry.

=item *

Only one slurpy parameter is allowed.

=item *

A slurpy parameter must have a type constraint that accepts the value
produced by slurpy processing. In array-slurpy mode this value is an
array reference; in hash-slurpy mode it is a hash reference.

=item *

Slurpy processing produces either an array reference or a hash reference,
depending on the slurpy mode. This value is then validated against the
type constraint of the slurpy parameter.

=item * B<Array-slurpy>

Remaining arguments are collected into an array reference:

=over 4

=item - Zero remaining arguments: []

=item - One remaining argument: [ $value ]

=item - Multiple remaining arguments: [ @values ]

=back

=item * B<Hash-slurpy>

Remaining arguments are collected into a hash reference:

=over 4

=item - Zero remaining arguments: {}

=item - One remaining argument: ( ref $value eq 'HASH' ) ? $value : { $value }

=item - Multiple remaining arguments: { @values }

=back

B<Note>: Simple types such as C<Any> or C<Ref> accept these structures and are
therefore valid slurpy parameter types, resulting in an array reference.

=back

=head2 C<alias> (named only)

Declares one or more alias names for a named parameter.

=head1 LIMITATIONS

This module implements only a subset of Type::Params. Notable limits:

=over 4

=item * Only C<signature> is supported

=item * No coercions or automatic type conversions.

=item * No advanced parameter kinds.

No parameter unions, parameter packs, or complex tuple types.

The L<Type::Standard> objects C<Slurpy['a]> and C<Optional['a]> are not 
recognized and therefore do not replace the parameters 
C<< optional => 1 >> or C<< slurpy => 1 >>.

=item * Having any optionals, default or aliases disables the fast-path.

Note that having any parameter with a optional or default disables the 
fast-path optimization in which the validator can return C<@_> unchanged.

=back

=head1 REQUIRES

Only core modules are used:

=over 4

=item * Perl 5.10+

=item * L<B::Deparse>

=item * L<Carp>

=item * L<Exporter>

=item * L<Params::Check>

=item * L<Scalar::Util>

=back

=head1 SEE ALSO

=over 4

=item * L<Type::API>

=item * L<Type::Params>

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Toby Inkster <tobyink@cpan.org>

=head1 LICENSE

Copyright (c) 2013-2014, 2017-2026 the L</AUTHORS> and L</CONTRIBUTORS> as 
listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
