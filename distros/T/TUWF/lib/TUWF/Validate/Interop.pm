package TUWF::Validate::Interop;

use strict;
use warnings;
use TUWF::Validate;
use Exporter 'import';
use Carp 'croak';

our @EXPORT_OK = ('analyze');
our $VERSION = '1.4';


# Analyzed ("flattened") object:
#   { type => scalar | bool | num | int | array | hash | any
#   , min, max, minlength, maxlength, required, regexes
#   , keys, values, unknown
#   }

sub _merge_type {
  my($c, $o) = @_;
  my $n = $c->{name}||'';

  return if $o->{type} eq 'int' || $o->{type} eq 'bool';
  $o->{type} = 'int'    if $n eq 'int'     || $n eq 'uint';
  $o->{type} = 'bool'   if $n eq 'anybool' || $n eq 'jsonbool';
  $o->{type} = 'num'    if $n eq 'num';
}


sub _merge {
  my($c, $o) = @_;

  _merge_type $c, $o;

  $o->{required} = 1 if ($c->{name}||'') eq 'anybool';

  $o->{values} = _merge_toplevel($c->{schema}{values}, $o->{values}||{}) if $c->{schema}{values};

  if($c->{schema}{keys}) {
      $o->{keys} ||= {};
      $o->{keys}{$_} = _merge_toplevel($c->{schema}{keys}{$_}, $o->{keys}{$_}||{}) for keys %{$c->{schema}{keys}};
  }

  $o->{minlength} = $c->{schema}{_analyze_minlength} if defined $c->{schema}{_analyze_minlength} && (!defined $o->{minlength} || $o->{minlength} < $c->{schema}{_analyze_minlength});
  $o->{maxlength} = $c->{schema}{_analyze_maxlength} if defined $c->{schema}{_analyze_maxlength} && (!defined $o->{maxlength} || $o->{maxlength} > $c->{schema}{_analyze_maxlength});
  $o->{min}       = $c->{schema}{_analyze_min}       if defined $c->{schema}{_analyze_min}       && (!defined $o->{min}       || $o->{min}       < $c->{schema}{_analyze_min}      );
  $o->{max}       = $c->{schema}{_analyze_max}       if defined $c->{schema}{_analyze_max}       && (!defined $o->{max}       || $o->{max}       > $c->{schema}{_analyze_max}      );
  push @{$o->{regexes}}, $c->{schema}{_analyze_regex} if defined $c->{schema}{_analyze_regex};

  _merge($_, $o) for @{$c->{validations}};
}


sub _merge_toplevel {
  my($c, $o) = @_;
  $o->{required} ||= $c->{schema}{required};
  $o->{unknown}  ||= $c->{schema}{unknown};
  $o->{default}  = $c->{schema}{default} if exists $c->{schema}{default};
  $o->{type} = $c->{schema}{type} if !$o->{type} || $o->{type} eq 'any';

  _merge $c, $o;
  bless $o, __PACKAGE__;
}


sub analyze {
  my $c = shift;
  $c->{analysis} ||= _merge_toplevel $c, {};
  $c->{analysis}
}


# Assumes that $obj already has the required format/structure, odd things may
# happen if this is not the case.
#   unknown => remove|reject|pass
sub coerce_for_json {
  my($o, $obj, %opt) = @_;
  $opt{unknown} ||= $o->{unknown};
  return undef if !defined $obj;
  return $obj+0 if $o->{type} eq 'num';
  return int $obj if $o->{type} eq 'int';
  return $obj ? \1 : \0 if $o->{type} eq 'bool';
  return "$obj" if $o->{type} eq 'scalar';
  return [map $o->{values}->coerce_for_json($_, %opt), @$obj] if $o->{type} eq 'array' && $o->{values};
  return {map {
        $o->{keys}{$_}            ? ($_, $o->{keys}{$_}->coerce_for_json($obj->{$_}, %opt)) :
        $opt{unknown} eq 'pass'   ? ($_, $obj->{$_}) :
        $opt{unknown} eq 'remove' ? ()
                                  : croak "Unknown key '$_' in hash in coerce_for_json()"
  } keys %$obj} if $o->{type} eq 'hash' && $o->{keys};
  $obj
}


# Returns a Cpanel::JSON::XS::Type; Behavior is subtly different compared to coerce_for_json():
# - Unknown keys in hashes will cause Cpanel::JSON::XS to die()
# - Numbers are always formatted as floats (e.g. 10.0) even if it's a round nunmber
sub json_type {
  my $o = shift;
  require Cpanel::JSON::XS::Type;
  return Cpanel::JSON::XS::Type::JSON_TYPE_FLOAT_OR_NULL()  if $o->{type} eq 'num';
  return Cpanel::JSON::XS::Type::JSON_TYPE_INT_OR_NULL()    if $o->{type} eq 'int';
  return Cpanel::JSON::XS::Type::JSON_TYPE_BOOL_OR_NULL()   if $o->{type} eq 'bool';
  return Cpanel::JSON::XS::Type::JSON_TYPE_STRING_OR_NULL() if $o->{type} eq 'scalar';
  return Cpanel::JSON::XS::Type::json_type_null_or_anyof(Cpanel::JSON::XS::Type::json_type_arrayof($o->{values} ? $o->{values}->json_type : undef)) if $o->{type} eq 'array';
  return Cpanel::JSON::XS::Type::json_type_null_or_anyof({ map +($_, $o->{keys}{$_}->json_type), keys %{$o->{keys}} }) if $o->{type} eq 'hash' && $o->{keys};
  return Cpanel::JSON::XS::Type::json_type_null_or_anyof(Cpanel::JSON::XS::Type::json_type_hashof(undef)) if $o->{type} eq 'hash';
  undef
}


# Attempts to convert a stringified Perl regex into something that is compatible with JS.
# - @ should not be escaped
# - (?^: is a perl alias for (?d-imnsx:
# - Javascript doesn't officially support embedded modifiers in the first place, so these are removed
# Regexes compiled with any of /imsx will not work properly.
sub _re_compat {
  local $_ = $_[0];
  s/\\@/@/g;
  s{\(\?\^?[alupimnsx]*(?:-[imnsx]+)?(?=[:\)])}{(?}g;
  $_
}


sub _join_regexes {
  my %r = map +($_,1), @{$_[0]};
  my @r = sort keys %r;
  _re_compat join('', map "(?=$_)", @r[0..$#r-1]).$r[$#r]
}


# Returns a few HTML5 validation properties. Doesn't include the 'type'
sub html5_validation {
  my $o = shift;
  +(
    $o->{required} ? (required => 'required') : (),
    defined $o->{minlength} ? (minlength => $o->{minlength}) : (),
    defined $o->{maxlength} ? (maxlength => $o->{maxlength}) : (),
    defined $o->{min}       ? (min       => $o->{min}      ) : (),
    defined $o->{max}       ? (max       => $o->{max}      ) : (),
    $o->{regexes} ? (pattern => _join_regexes $o->{regexes}) : (),
  );
}



# The elm_ are experimental, unstable, not very well-tested and for Elm 0.19

# Options: required any array values keys indent level
sub elm_type {
  my($o, %opt) = @_;
  my $par = delete $opt{_need_parens} ? sub { "($_[0])" } : sub { $_[0] };
  return $par->('Maybe ' . $o->elm_type(%opt, required => 1, _need_parens => 1)) if !$o->{required} && !defined $o->{default} && !$opt{required};
  delete $opt{required};
  return 'String' if $o->{type} eq 'scalar';
  return 'Bool'   if $o->{type} eq 'bool';
  return 'Float'  if $o->{type} eq 'num';
  return 'Int'    if $o->{type} eq 'int';
  return $opt{any} if $o->{type} eq 'any' && $opt{any};
  return $par->( ($opt{array} || 'List') . ' ' . ($opt{values} || $o->{values}->elm_type(%opt, _need_parens => 1)) )
    if $o->{type} eq 'array' && ($opt{values} || $o->{values});

  if($o->{type} eq 'hash' && ($o->{keys} || $opt{keys})) {
    $opt{indent} //= 2;
    $opt{level}  //= 1;
    my $len = 0;
    $len = length $_ > $len ? length $_ : $len for keys %{$o->{keys}};

    my $r = "\n{ " . join("\n, ", map {
      sprintf "%-*s : %s", $len, $_, $opt{keys}{$_} || $o->{keys}{$_}->elm_type(%opt, level => $opt{level}+1);
    } sort keys %{$o->{keys}}) . "\n}";;

    $r =~ s/\n/$opt{indent} ? "\n" . (' 'x($opt{indent}*$opt{level})) : ''/eg;
    return $r;
  }

  croak "Unknown type '$o->{type}' or missing option";
}


# Elm JSON encoder for values of elm_type()
# options: elm_type() options + json_encode var_prefix
sub elm_encoder {
  my($o, %opt) = @_;
  $opt{json_encode} //= '';
  $opt{var_prefix} //= 'e';
  $opt{var_num} //= 0;

  return sprintf '(Maybe.withDefault %snull << Maybe.map %s)',
    $opt{json_encode}, $opt{values} || $o->elm_encoder(%opt, required => 1)
    if !$o->{required} && !defined $o->{default} && !$opt{required};

  delete $opt{required};
  return "$opt{json_encode}string" if $o->{type} eq 'scalar';
  return "$opt{json_encode}bool"   if $o->{type} eq 'bool';
  return "$opt{json_encode}float"  if $o->{type} eq 'num';
  return "$opt{json_encode}int"    if $o->{type} eq 'int';
  return $opt{any}                 if $o->{type} eq 'any' && $opt{any};
  return sprintf '(%slist %s)', $opt{json_encode}, $opt{values} || $o->{values}->elm_encoder(%opt)
    if $o->{type} eq 'array' && ($opt{values} || $o->{values});

  if($o->{type} eq 'hash' && ($o->{keys} || $opt{keys})) {
    $opt{indent} //= 2;
    $opt{level}  //= 1;
    my $len = 0;
    $len = length $_ > $len ? length $_ : $len for keys %{$o->{keys}};

    my $var = $opt{var_prefix}.$opt{var_num};
    my $r = sprintf "(\\%s -> %sobject\n[ %s\n])", $var, $opt{json_encode}, join "\n, ", map {
      sprintf '("%s",%s %s %s.%1$s)', $_,
        ' 'x($len-(length $_)),
        $opt{keys}{$_} || $o->{keys}{$_}->elm_encoder(%opt, level => $opt{level}+1, var_num => $opt{var_num}+1),
        $var;
    } sort keys %{$o->{keys}};

    $r =~ s/\n/$opt{indent} ? "\n" . (' 'x($opt{indent}*$opt{level})) : ''/eg;
    return $r;
  }

  croak "Unknown type '$o->{type}' or missing option";
}

1;
