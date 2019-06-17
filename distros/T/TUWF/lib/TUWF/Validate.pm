package TUWF::Validate;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Scalar::Util 'blessed';

our @EXPORT_OK = qw/compile validate/;
our $VERSION = '1.3';


# Unavailable as custom validation names
my %builtin = map +($_,1), qw/
  type
  required default
  rmwhitespace
  values scalar sort unique
  keys unknown
  func
/;


sub _length {
  my($exp, $min, $max) = @_;
  +{ _analyze_minlength => $min, _analyze_maxlength => $max, func => sub {
    my $got = ref $_[0] eq 'HASH' ? keys %{$_[0]} : ref $_[0] eq 'ARRAY' ? @{$_[0]} : length $_[0];
    (!defined $min || $got >= $min) && (!defined $max || $got <= $max) ? 1 : { expected => $exp, got => $got };
  }}
}

# Basically the same as ( regex => $arg ), but hides the regex error
sub _reg {
  my $reg = $_[0];
  ( type => 'scalar', _analyze_regex => "$reg", func => sub { $_[0] =~ $reg ? 1 : { got => $_[0] } } );
}


our $re_num       = qr/^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$/;
my  $re_int       = qr/^-?(?:0|[1-9]\d*)$/;
our $re_uint      = qr/^(?:0|[1-9]\d*)$/;
my  $re_fqdn      = qr/(?:[a-zA-Z0-9][\w-]*\.)+[a-zA-Z][a-zA-Z0-9-]{1,25}\.?/;
my  $re_ip4_digit = qr/(?:0|[1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])/;
my  $re_ip4       = qr/($re_ip4_digit\.){3}$re_ip4_digit/;
# This monstrosity is based on http://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
# Doesn't allow IPv4-mapped-IPv6 addresses or other fancy stuff.
my  $re_ip6       = qr/(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)/;
my  $re_ip        = qr/(?:$re_ip4|$re_ip6)/;
my  $re_domain    = qr/(?:$re_fqdn|$re_ip4|\[$re_ip6\])/;
# Also used by the TUWF::Misc::kv_validate()
our $re_email     = qr/^[-\+\.#\$=\w]+\@$re_domain$/;
our $re_weburl    = qr/^https?:\/\/$re_domain(?::[1-9][0-9]{0,5})?(?:\/[^\s<>"]*)$/;


our %default_validations = (
  regex => sub {
    my $reg = shift;
    # Error objects should be plain data structures so that they can easily
    # be converted to JSON for debugging. We have to stringify $reg in the
    # error object to ensure that.
    +{ type => 'scalar', _analyze_regex => "$reg", func => sub { $_[0] =~ $reg ? 1 : { regex => "$reg", got => $_[0] } } }
  },
  enum => sub {
    my @l = ref $_[0] eq 'HASH' ? sort keys %{$_[0]} : ref $_[0] eq 'ARRAY' ? @{$_[0]} : ($_[0]);
    my %opts = map +($_,1), @l;
    +{ type => 'scalar', func => sub { $opts{ (my $v = $_[0]) } ? 1 : { expected => \@l, got => $_[0] } } }
  },

  minlength => sub { _length $_[0], $_[0] },
  maxlength => sub { _length $_[0], undef, $_[0] },
  length    => sub { _length($_[0], ref $_[0] eq 'ARRAY' ? @{$_[0]} : ($_[0], $_[0])) },

  anybool   => { type => 'any', required => 0, default => 0, func => sub { $_[0] = $_[0] ? 1 : 0; 1 } },
  jsonbool  => { type => 'any', func => sub {
    my $r = $_[0];
    blessed $r && (
         $r->isa('JSON::PP::Boolean')
      || $r->isa('JSON::XS::Boolean')
      || $r->isa('Types::Serialiser::Boolean')
      || $r->isa('Cpanel::JSON::XS::Boolean')
      || $r->isa('boolean')
    ) ? 1 : {};
  } },

  # JSON number format, regex from http://stackoverflow.com/questions/13340717/json-numbers-regular-expression
  num  => { _reg $re_num },
  int  => { _reg $re_int }, # implies num
  uint => { _reg $re_uint }, # implies num
  min => sub {
    my $min = shift;
    +{ num => 1, _analyze_min => $min, func => sub { $_[0] >= $min ? 1 : { expected => $min, got => $_[0] } } }
  },
  max => sub {
    my $max = shift;
    +{ num => 1, _analyze_max => $max, func => sub { $_[0] <= $max ? 1 : { expected => $max, got => $_[0] } } }
  },
  range => sub { +{ min => $_[0][0], max => $_[0][1] } },

  ascii  => { _reg qr/^[\x20-\x7E]*$/ },
  ipv4   => { _reg $re_ip4 },
  ipv6   => { _reg $re_ip6 },
  ip     => { _reg $re_ip  },
  email  => { _reg($re_email),  maxlength => 254 },
  weburl => { _reg($re_weburl), maxlength => 65536 }, # the maxlength is a bit arbitrary, but better than unlimited
);


# Loads a hashref of validations and a schema definition, and converts it into
# an object with:
# {
#   name => $name_or_undef,
#   validations => [ $recursive_compiled_object, .. ],
#   schema => $modified_schema_without_validations,
#   known_keys => { $key => 1, .. }  # Extracted from 'keys', Used for the 'unknown' validation
# }
sub _compile {
  my($validations, $schema, $rec) = @_;

  my(%top, @val);
  my @keys = keys %{$schema->{keys}} if $schema->{keys};

  for(sort keys %$schema) {
    if($builtin{$_} || /^_analyze_/) {
      $top{$_} = $schema->{$_};
      next;
    }

    my $t = $validations->{$_} || $default_validations{$_};
    croak "Unknown validation: $_" if !$t;
    croak "Recursion limit exceeded while resolving validation '$_'" if $rec < 1;
    $t = ref $t eq 'HASH' ? $t : $t->($schema->{$_});

    my $v = _compile($validations, $t, $rec-1);
    $v->{name} = $_;
    push @val, $v;
  }

  # Inherit some builtin options from validations
  for my $t (@val) {
    if($top{type} && $t->{schema}{type} && $top{type} ne $t->{schema}{type}) {
      croak "Incompatible types, the schema specifies '$top{type}' but validation '$t->{name}' requires '$t->{schema}{type}'" if $schema->{type};
      croak "Incompatible types, '$t->[0]' requires '$t->{schema}{type}', but another validation requires '$top{type}'";
    }
    exists $t->{schema}{$_} and $top{$_} //= delete $t->{schema}{$_} for qw/required default rmwhitespace type scalar unknown sort unique/;

    push @keys, keys %{ delete $t->{known_keys} };
    push @keys, keys %{ $t->{schema}{keys} } if $t->{schema}{keys};
  }

  # Compile sub-schemas
  $top{keys} = { map +($_, compile($validations, $top{keys}{$_})), keys %{$top{keys}} } if $top{keys};
  $top{values} = compile($validations, $top{values}) if $top{values};

  # XXX: Flattening recursive validations would be faster and may simplify
  # the code a bit, but makes error objects harder to interpret.

  # XXX: As an optimization, it's possible to remove double validations (e.g.
  # multiple invocations of the same validation with the same options due to
  # validations calling each other). Care must be taken that this won't
  # affect error objects (i.e. only subsequent invocations should be
  # removed).

  return {
    validations => \@val,
    schema      => \%top,
    known_keys  => { map +($_,1), @keys },
  };
}


sub compile {
  my($validations, $schema) = @_;

  return $schema if ref $schema eq __PACKAGE__;

  my $c = _compile $validations, $schema, 64;

  $c->{schema}{type} //= 'scalar';
  $c->{schema}{required} //= 1;
  $c->{schema}{rmwhitespace} //= 1;
  $c->{schema}{unknown} //= 'remove';

  if(exists $c->{schema}{sort}) {
    my $s = $c->{schema}{sort};
    $c->{schema}{sort} =
      ref $s eq 'CODE' ? $s
      :    $s eq 'str' ? sub { $_[0] cmp $_[1] }
      :    $s eq 'num' ? sub { $_[0] <=> $_[1] }
      : croak "Unknown value for 'sort': $c->{schema}{sort}";
  }
  $c->{schema}{unique} = sub { $_[0] } if $c->{schema}{unique} && !ref $c->{schema}{unique} && !$c->{schema}{sort};

  bless $c, __PACKAGE__;
}


sub _validate_rec {
  my($c, $input) = @_;

  # hash keys
  if($c->{schema}{keys}) {
    my @err;
    for my $k (keys %{$c->{schema}{keys}}) {
      # We need to overload the '!exists && !required && !default'
      # scenario a bit, because in that case we should not create the key
      # in the output. All other cases will be handled just fine by
      # passing an implicit 'undef'.
      my $s = $c->{schema}{keys}{$k};
      next if !exists $input->{$k} && !$s->{schema}{required} && !exists $s->{schema}{default};

      my $r = _validate($s, $input->{$k});
      $input->{$k} = $r->[0];
      if($r->[1]) {
        $r->[1]{key} = $k;
        push @err, $r->[1];
      }
    }
    return [$input, { validation => 'keys', errors => \@err }] if @err;
  }

  # array values
  if($c->{schema}{values}) {
    my @err;
    for my $i (0..$#$input) {
      my $r = _validate($c->{schema}{values}, $input->[$i]);
      $input->[$i] = $r->[0];
      if($r->[1]) {
        $r->[1]{index} = $i;
        push @err, $r->[1];
      }
    }
    return [$input, { validation => 'values', errors => \@err }] if @err;
  }

  # validations
  for (@{$c->{validations}}) {
    my $r = _validate_rec($_, $input);
    $input = $r->[0];

    return [$input, {
      # If the error was a custom 'func' object, then make that the primary cause.
      # This makes it possible for validations to provide their own error objects.
      $r->[1]{validation} eq 'func' && (!exists $r->[1]{result} || keys %{$r->[1]} > 2) ? %{$r->[1]} : (error => $r->[1]),
      validation => $_->{name},
    }] if $r->[1];
  }

  # func
  if($c->{schema}{func}) {
    my $r = $c->{schema}{func}->($input);
    return [$input, { %$r, validation => 'func' }] if ref $r eq 'HASH';
    return [$input, { validation => 'func', result => $r }] if !$r;
  }

  return [$input]
}


sub _validate_array {
  my($c, $input) = @_;

  return [$input] if $c->{schema}{type} ne 'array';

  $input = [sort { $c->{schema}{sort}->($a,$b) } @$input ] if $c->{schema}{sort};

  # Key-based uniqueness
  if($c->{schema}{unique} && ref $c->{schema}{unique} eq 'CODE') {
    my %h;
    for my $i (0..$#$input) {
      my $k = $c->{schema}{unique}->($input->[$i]);
      return [$input, { validation => 'unique', index_a => $h{$k}, value_a => $input->[$h{$k}], index_b => $i, value_b => $input->[$i], key => $k }] if exists $h{$k};
      $h{$k} = $i;
    }

  # Comparison-based uniqueness
  } elsif($c->{schema}{unique}) {
    for my $i (0..$#$input-1) {
      return [$input, { validation => 'unique', index_a => $i, value_a => $input->[$i], index_b => $i+1, value_b => $input->[$i+1] }]
        if $c->{schema}{sort}->($input->[$i], $input->[$i+1]) == 0
    }
  }

  return [$input]
}


sub _validate {
  my($c, $input) = @_;

  # rmwhitespace (needs to be done before the 'required' test)
  if(defined $input && !ref $input && $c->{schema}{type} eq 'scalar' && $c->{schema}{rmwhitespace}) {
    $input =~ s/\r//g;
    $input =~ s/^\s*//;
    $input =~ s/\s*$//;
  }

  # required & default
  if(!defined $input || (!ref $input && $input eq '')) {
    # XXX: This will return undef if !required and no default is set, even for hash and array types. Should those get an empty hash or array?
    return [exists $c->{schema}{default} ? $c->{schema}{default} : $input] if !$c->{schema}{required};
    return [$input, { validation => 'required' }];
  }

  if($c->{schema}{type} eq 'scalar') {
    return [$input, { validation => 'type', expected => 'scalar', got => lc ref $input }] if ref $input;

  } elsif($c->{schema}{type} eq 'hash') {
    return [$input, { validation => 'type', expected => 'hash', got => lc ref $input || 'scalar' }] if ref $input ne 'HASH';

    # unknown
    if($c->{schema}{unknown} eq 'remove') {
      $input = { map +($_, $input->{$_}), grep $c->{known_keys}{$_}, keys %$input };
    } elsif($c->{schema}{unknown} eq 'reject') {
      my @err = grep !$c->{known_keys}{$_}, keys %$input;
      return [$input, { validation => 'unknown', keys => \@err, expected => [ sort keys %{$c->{known_keys}} ] }] if @err;
    } else {
      # Make a shallow copy of the hash, so that further validations can
      # perform in-place modifications without affecting the input.
      # (The other two if clauses above also ensure this)
      $input = { %$input };
    }

  } elsif($c->{schema}{type} eq 'array') {
    $input = [$input] if $c->{schema}{scalar} && !ref $input;
    return [$input, { validation => 'type', expected => $c->{schema}{scalar} ? 'array or scalar' : 'array', got => lc ref $input || 'scalar' }] if ref $input ne 'ARRAY';
    $input = [@$input]; # Create a shallow copy to prevent in-place modification.

  } elsif($c->{schema}{type} eq 'any') {
    # No need to do anything here.

  } else {
    croak "Unknown type '$c->{schema}{type}'"; # Should be checked in _compile(), preferably.
  }

  my $r = _validate_rec($c, $input);
  return $r if $r->[1];
  $input = $r->[0];

  _validate_array($c, $input);
}


sub validate {
  my($c, $input) = ref $_[0] eq __PACKAGE__ ? @_ : (compile($_[0], $_[1]), $_[2]);
  bless _validate($c, $input), 'TUWF::Validate::Result';
}


sub analyze {
  require TUWF::Validate::Interop;
  TUWF::Validate::Interop::analyze($_[0]);
}



package TUWF::Validate::Result;

use strict;
use warnings;
use Carp 'croak';

# A result object contains: [$data, $error]

# In boolean context, returns whether the validation succeeded.
use overload bool => sub { !$_[0][1] };

# Returns the validation errors, or undef if validation succeeded
sub err { $_[0][1] }

# Returns the validated and normalized input, dies if validation didn't succeed.
sub data {
  if($_[0][1]) {
    require Data::Dumper;
    my $s = Data::Dumper->new([$_[0][1]])->Terse(1)->Pair(':')->Indent(0)->Sortkeys(1)->Dump;
    croak "Validation failed: $s";
  }
  $_[0][0]
}

# Same as 'data', but returns partially validated and normalized data if validation failed.
sub unsafe_data { $_[0][0] }

# TODO: Human-readable error message formatting

1;
