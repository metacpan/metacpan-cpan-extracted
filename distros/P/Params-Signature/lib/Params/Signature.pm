package Params::Signature;

# TODO:
#    *  write documentation
#    *  test
#       test in "real" app
#       if it works, put on CPAN & github

# TODO: test
#   + exported functions
#     - update documentation
#   + coercion
#     - update documentation
#
use strict;
use warnings;

use Exporter;

use Carp;
use Scalar::Util;
use Class::Inspector;

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(validate check hash_param_ok kv_param_ok strict_param positional_style named_style mixed_style);
our %EXPORT_TAGS = (all => [qw(validate check hash_param_ok kv_param_ok strict_param positional_style named_style mixed_style)]);

our $VERSION = "0.05";

my $OPTIONAL_SYMBOL = "optional:";
my $CUTOFF_SYMBOL   = "named:";
my $EXTRA_SYMBOL    = "...";

my $ASSIGN_PARAM_SYMBOL = "<=";
my $ASSIGN_SYMBOL       = "=";
my $DEPENDS_SYMBOL      = "<<";

my $ASSIGN_NONE    = 0;
my $ASSIGN_PARAM   = 1;
my $ASSIGN_LITERAL = 2;
my $ASSIGN_SUB     = 3;

my $POSITIONAL          = "positional";
my $NAMED               = "named";
my $MIXED               = "mixed";
my $DEFAULT_PARAM_STYLE = $POSITIONAL;
sub positional_style { $POSITIONAL; }
sub named_style      { $NAMED; }
sub mixed_style      { $MIXED; }

# values for fuzzy
my $FUZZY_OFF     = 0;
my $FUZZY_HASH_OK = 1;    # ok to pass a hash of named parameters
my $FUZZY_KV_OK   = 2;    # ok to pass a hash of named parameters, also ok to pass raw key/value pairs
sub strict_param  { $FUZZY_OFF; }
sub hash_param_ok { $FUZZY_HASH_OK; }
sub kv_param_ok   { $FUZZY_KV_OK; }

my $FAILED = 0;
my $OK     = 1;

#my $FIELD_SEPARATOR = 0x1c;
my $FIELD_SEPARATOR = chr(28);

my %type_cache;
my $debug = 0;

if ($debug)
{
   # 'use' tucked inside 'eval' so it happens at runtime
   # otherwise the 'if' doesn't really do what I want
   eval "use Data::Dumper";
}

my $class_default = undef;

# singleton for use with class methods
*class_default = sub {
   ($class_default) ? $class_default : (
                                        $class_default = new Params::Signature(
                                                                               param_style => $DEFAULT_PARAM_STYLE,
                                                                               fuzzy       => $FUZZY_OFF,
                                                                               coerce      => 1,
                                                                               on_fail     => \&confess,
                                                                               called      => "Params::Signature:"
                                          )
                                          );
};

my $new_validator = {
   param_style => sub {
      ($_[0] eq $POSITIONAL || $_[0] eq $NAMED || $_[0] eq $MIXED);
   },
   on_fail        => sub { (!defined($_[0])     || ref $_[0] eq "CODE") },
   normalize_keys => sub { (!defined($_[0])     || ref $_[0] eq "CODE") },
   fuzzy          => sub { ($_[0] == $FUZZY_OFF || $_[0] == $FUZZY_HASH_OK) || $_[0] == $FUZZY_KV_OK },
   coerce         => sub { ($_[0] == 0          || $_[0] == 1) },
   called         => sub { 1 },
   };

sub new
{

   # can't use our own validate() because that would result in recursion
   # new() requires named parameters; positional are not supported
   my $param;
   my $class  = shift;
   my %params = (ref($_[0]) eq "HASH") ? %{$_[0]} : @_;
   my $self   = {};
   my $on_fail;
   bless $self, $class;

   if (defined($self->{on_fail}))
   {
      $on_fail = $self->{on_fail};
   }
   elsif (defined($class_default))
   {
      $on_fail = $class_default->{on_fail};
   }
   else
   {

      # we may be in the process of defining $class_default, so no default
      # on_fail actually exists yet
      $on_fail = \&confess;
   }
   $params{called} = (defined($params{called})) ? $params{called} : '';

   foreach $param (keys %params)
   {

      #_print_debug("new: validate $param ($params{$param})");
      if (!defined($new_validator->{$param}))
      {
         $on_fail->("$param: $params{$param} is an unknown option");
         return;
      }
      if (!$new_validator->{$param}->($params{$param}))
      {
         $on_fail->("$param: $params{$param} is invalid");
         return;
      }
      $self->{$param} = $params{$param};
   }

   # if a param is not set, override with class default
   if ($class_default)
   {
      foreach $param (keys %$new_validator)
      {
         if (!defined($self->{$param}))
         {
            $self->{$param} = $class_default->{$param};
         }
      }
   }

   return $self;
}

sub check
{
   my $self;
   my $self_ref = ref($_[0]);    # determine how sub was called (obj,class,sub?)

   my (
       $type_spec,
       $value,
       @all_types,
       $type_passed,
       $type,
       $tc,           # type constraint
       $coerce_tc,    # first type constraint that'll coerce the value
       $tc_name,
       $msg,
       $cfg,
       $caller,
       $coerce,
       %params,
       );

   $self =
     ($self_ref && $self_ref ne "ARRAY" && $self_ref ne "HASH") ?
     shift @_ :
     (($_[0] eq "Params::Signature") ? (shift @_ and class_default()) : class_default());

   # basic support for positional parameters
   $type_spec   = shift;
   $value       = shift;
   $cfg         = shift;
   $caller      = $cfg->{caller} || caller;
   $coerce      = (exists($cfg->{coerce})) ? $cfg->{coerce} : $self->{coerce};
   $type_passed = 0;

   # check object for object-specific types
   foreach $type (split(/\|/, $type_spec))
   {
      no strict 'refs';

      # must re-declare variable because reference to it will be saved in
      # generated sub. If not re-declared, all subs will use last value
      # assigned to $tc.
      my $tc_name = $caller . "::" . $type;
      my $tc      = $type_cache{$tc_name}{tc};

      if (!defined($tc))
      {
         # turn off strict refs inside of the enclosing braces
         # since we're monkeying around with strings & sub references
         no strict 'refs';

         #$tc = (ref(${$tc_name}) &&  ${$tc_name}->can('check')) ? ${$tc_name} : eval { $tc_name->() };
         $tc = (ref(${$tc_name})) ? ${$tc_name} : eval { $tc_name->() };
         if (!defined($tc))
         {
            $tc = eval { Mouse::Util::TypeConstraints::find_type_constraint($type) };
         }
         if (!defined($tc))
         {
            $tc = eval { Moose::Util::TypeConstraints::find_type_constraint($type) };
         }

         if (!defined($tc))
         {
            # weird, $type is not defined as a type constraint
            return (wantarray ? (0, 0, "Failed to locate type: $type", undef) : 0);
         }
         $type_cache{$tc_name}{type}    = $type;
         $type_cache{$tc_name}{tc_name} = $tc_name;
         $type_cache{$tc_name}{tc}      = $tc;
         if (ref($tc) eq "CODE")
         {
            # MOO?
            $type_cache{$tc_name}{check} = sub {
               eval { $tc->($_[0]) };
               return 0 if $@;
               1;
            };
            $type_cache{$tc_name}{has_coercion} = 0;
         }
         else
         {
            if (ref($tc) =~ /Type::Tiny/)
            {
               $type_cache{$tc_name}{check} = $tc->compiled_check;
            }
            else
            {
               if (!$tc->can("check"))
               {
                  return (wantarray ? (0, undef, "$tc_name does not implement 'check'") : 0);
               }

               $type_cache{$tc_name}{check} = sub { $tc->check($_[0]) };
            }
            if ($tc->can('has_coercion') && $tc->has_coercion)
            {
               $type_cache{$tc_name}{has_coercion} = 1;
            }
         }
      }

      if ($tc)
      {
         $type_passed = $type_cache{$tc_name}{check}->($value);
      }

      if (!$type_passed && $type_cache{$tc_name}{'has_coercion'} && $coerce)
      {
         $value       = $tc->coerce($value);
         $type_passed = $type_cache{$tc_name}{check}->($value);
      }

      # type_passed may contain an object's class, a numeric value,
      # or who knows what, depending on the type that passed the
      # test; forcing type_passed to a 1 so tests pass/fail properly
      if ($type_passed) { $type_passed = 1; $msg = "$tc_name"; last; }
   }
   if (!$type_passed)
   {
      $msg = "Value failed validation";
   }

   (wantarray ? ($type_passed, $value, $msg, $tc) : $type_passed);
}

# get signature info
sub _get_signature_info
{
   my $signature = $_[1];
   my $self_ref  = ref($_[0]);    # determine how sub was called (obj,class,sub?)
   my $self =
     ($self_ref && $self_ref ne "ARRAY" && $self_ref ne "HASH") ?
     shift @_ :
     (($_[0] eq "Params::Signature") ? (shift @_ and $class_default) : $class_default);
   my $cache_key;
   my $caller = caller;
   my $called = "$caller:";
   my $msg;
   my $on_fail = \&carp;
   my $ok;
   my $signature_info;
   $cache_key = $caller . join("$FIELD_SEPARATOR", @{$signature});

   if (exists($self->{cache}{$cache_key}))
   {

      #_print_debug("Use cache key: $cache_key");
      $signature_info = $self->{cache}{$cache_key};
   }
   else
   {
      ($signature_info, $ok, $msg) = $self->_build_signature_info($signature, $caller);
      if (!$ok)
      {
         $on_fail->("$called $msg");
         return;
      }
      $self->{cache}{$cache_key} = $signature_info;
   }
   return $signature_info;
}

#spec("Str name!",  "Str alias < name", "ArrayRef options = []", "HashRef h = { call_a_sub }", "CustomRelationType relation = '1-N'")

# @types = [
#    {
#         type => 'ArrayRef',
#         tc_name => 'DefinedInPackage::ArrayRef',
#         tc => $tc,
#         check => $check_sub,    # for Moose and Mouse, sub { $tc->check($_[0]) }, Type::Tiny save ref to compiled_check
#         has_coercion => [0|1],  # WARNING: $tc checked only once, when signature is compiled
#         coerce => $coerce_sub,
#    }
# ]
sub _build_signature_info
{
   my $ARG_MAX = 4;
   my $self    = shift;
   my $caller  = $_[1];
   my $arg;
   my @parts;
   my $alias;
   my @aliases;
   my $type;
   my $name;
   my $optional;
   my $indicator;
   my $indicator_value;
   my $type_info;
   my $tc_name;
   my $tc;
   my $spec;
   my $idx            = -1;
   my @signature_spec = ();
   my @required_names = ();
   my @optional_names = ();
   my @all_names      = ();
   my %signature_info = ();
   my $ok             = 1;
   my $msg;
   my $cutoff;
   my $regex = "";
   my $flag;
   my $force_optional;

   foreach $arg (@{$_[0]})
   {
      $spec = {};

      # put whitespace around indicator (=, <=, <<)
      $arg =~ s/([\<\=]{1,2})/ $1 /;
      ($type, $name, $indicator, $indicator_value) =
        split(/\s+/, $arg, $ARG_MAX);

#_print_debug("Process arg: ", "arg: $arg", "type: $type", "name: $name", "indicator: $indicator", "indicator_value: $indicator_value");
      $idx++;
      $spec->{type} = $type;

      #@{$spec->{types}}        = split(/\|/, $type);
      @{$spec->{types}} = ();
      $spec->{idx}             = $idx;
      $spec->{name}            = $name;
      $spec->{indicator}       = $indicator;
      $spec->{indicator_value} = $indicator_value;

      if ($type eq $CUTOFF_SYMBOL)
      {

         #_print_debug("is cutoff");
         $signature_info{positional_cutoff} = $idx;
         $idx--;
         next;
      }
      elsif ($type eq $EXTRA_SYMBOL)
      {

         #_print_debug("is extra");
         $signature_info{extra_cutoff} = $idx;
         $idx--;
         next;
      }
      elsif ($type eq $OPTIONAL_SYMBOL)
      {
         $force_optional = 1;
         $idx--;
         next;
      }

      # perl6-ish variable name
      if (((index($name, ":\$") == 0) || (index($name, ":") == 0)) &&
          (!exists($signature_info{positional_cutoff})))
      {
         $signature_info{positional_cutoff} = $idx;
      }

      # TODO: ambiguous names (no sigils) are not caught
      #       fields are assumed 'named' if any preceding field is named
      if ((index($name, "\$") == 0) &&
          (exists($signature_info{positional_cutoff})))
      {
         $ok  = 0;
         $msg = "Positional parameter $name cannot appear after a named parameter";
         last;
      }
      $name =~ s/^[:\$]*//;

      $name =~ s/([\!\?])$//;
      $flag = $1;
      $spec->{has_alias} = 0;
      if ($name =~ /[:\$\!\?\{\}]/)
      {
         $ok  = 0;
         $msg = "Invalid character(s) in '$name'";
         last;
      }
      if (index($name, "|") != -1)
      {
         $spec->{has_alias} = 1;
         my @aliases = split(/\|/, $name);
         $name = shift @aliases;
         foreach $alias (@aliases)
         {
            $signature_info{map}{$alias} = $spec;
         }
         $spec->{aliases} = \@aliases;
      }

      # only actual argument specifications get processed below
      if ($force_optional || (defined($flag) && $flag eq "?"))
      {
         $spec->{optional} = 1;
         push(@optional_names, $name);
         if (!exists($signature_info{pos_optional_start}))
         {
            $signature_info{pos_optional_start} = $idx;
         }
      }
      else
      {

         # required by default
         $spec->{optional} = 0;
         $signature_info{required}{$name} = $spec;
         push(@required_names, $name);
         if (!$signature_info{positional_cutoff})
         {
            $signature_info{positional_last_required} = $idx;
         }
      }
      push(@all_names, $name);
      $spec->{name} = $name;

      foreach $type (split(/\|/, $type))
      {
         no strict 'refs';

         # must re-declare variable because reference to it will be saved in
         # generated sub. If not re-declared, all subs will use last value
         # assigned to $tc.
         my $tc_name = $caller . "::" . $type;

         my $tc = $type_cache{$tc_name}{tc};

         if (!defined($tc))
         {
            # turn off strict refs inside of the enclosing braces
            # since we're monkeying around with strings & sub references
            no strict 'refs';

            #$tc = (ref(${$tc_name}) &&  ${$tc_name}->can('check')) ? ${$tc_name} : eval { $tc_name->() };
            $tc = (ref(${$tc_name})) ? ${$tc_name} : eval { $tc_name->() };
            if (!defined($tc))
            {
               $tc = eval { Mouse::Util::TypeConstraints::find_type_constraint($type) };
            }
            if (!defined($tc))
            {
               $tc = eval { Moose::Util::TypeConstraints::find_type_constraint($type) };
            }

            if (!defined($tc))
            {
               # weird, $type is not defined as a type constraint
               return (undef, 0, "Failed to locate type: $type");
               next;
            }
            $type_cache{$tc_name}{type}    = $type;
            $type_cache{$tc_name}{tc_name} = $tc_name;
            $type_cache{$tc_name}{tc}      = $tc;
            if (ref($tc) eq "CODE")
            {
               # MOO?
               $type_cache{$tc_name}{check}        = $tc;
               $type_cache{$tc_name}{has_coercion} = 0;
            }
            else
            {
               if (ref($tc) =~ /Type::Tiny/)
               {
                  $type_cache{$tc_name}{check} = $tc->compiled_check;
               }
               else
               {
                  if (!$tc->can("check"))
                  {
                     return (undef, 1, "$tc_name does not implement 'check'");
                  }
                  $type_cache{$tc_name}{check} = sub { $tc->check($_[0]) };
               }
               if ($tc->can('has_coercion') && $tc->has_coercion)
               {
                  $type_cache{$tc_name}{has_coercion} = 1;
               }
            }
         }
         push(@{$spec->{types}}, \$type_cache{$tc_name});
      }

      #_print_debug("Normal arg: $name");

      if (defined($indicator))
      {
         if ($indicator eq $ASSIGN_SYMBOL)
         {
            if ($indicator_value =~ /[\&\{\[]/)
            {

               #_print_debug("Assign sub for default: $indicator_value");
               $spec->{default_type} = $ASSIGN_SUB;
               $spec->{default}      = eval "sub { $indicator_value }";

            }
            else
            {

               #_print_debug("Assign literal for default: $indicator_value");
               $spec->{default_type} = $ASSIGN_LITERAL;
               $spec->{default}      = eval "$indicator_value;";
            }
         }
         elsif ($indicator eq $ASSIGN_PARAM_SYMBOL)
         {

            #_print_debug("Assign param for default: $indicator_value");
            $spec->{default_type} = $ASSIGN_PARAM;
            $spec->{default}      = $indicator_value;    # src field name
            if (!exists($signature_info{map}{$indicator_value}))
            {
               $ok  = 0;
               $msg = "$indicator_value must appear before $name in signature";
               last;
            }
         }
         elsif ($indicator eq $DEPENDS_SYMBOL)
         {

            # NOTE: this should really only be set for an optional value;
            #       something that is required (or has a default value) will
            #       always cause the 'depends' fields to be required
            #       which makes defining this dependency redundant
            #       and unnecessary; optional fields should depend on
            #       an optional field
            $spec->{default_type} = $ASSIGN_NONE;
            my $iv = $indicator_value;
            $iv =~ s/,/ /;
            $iv =~ s/^\[(.*)\]$/qw($1)/;
            @{$spec->{depends}} = eval $iv;
            if (ref($spec->{depends}) ne "ARRAY")
            {
               $ok  = 0;
               $msg = "Dependency $indicator_value for $name must be an array";
               last;
            }

            #_print_debug("Configure dependency: $indicator_value");
         }
         elsif (length($indicator))
         {
            $ok  = 0;
            $msg = "$indicator not understood after $name in signature. Missing space?";
            last;
         }
      }
      $signature_spec[$idx] = $spec;
      $signature_info{map}{$name} = $spec;
   }
   $signature_info{signature_spec} = \@signature_spec;

   if (exists($signature_info{extra_cutoff}) &&
       ($signature_info{extra_cutoff} != scalar @signature_spec))
   {
      $ok  = 0;
      $msg = "Extra parameter indicator must be the last item in the signature";
   }

   # if we have a positional cutoff in the signature, we can verify
   # that required arguments do no appear after optional ones;
   # otherwise, the sanity of the signature cannot be determined here
   # because there is no way to know if the subroutine will allow positional,
   # named or either style of parameters when it's actually called
   #   ... setting the first arg in signature to "named:" lets us know the sub
   #       will be called with named parameters only
   #   ... setting the last arg in signature to "named:" lets us know the sub
   #       will be called with positional parameters only
   if (defined($signature_info{positional_cutoff}))
   {
      $cutoff = $signature_info{positional_cutoff};
      foreach $idx (0 .. $signature_info{positional_cutoff} - 1)
      {
         if ($signature_spec[$idx]->{optional})
         {
            $cutoff = $signature_spec[$idx]->{optional};
         }
         if ((!$signature_spec[$idx]->{optional}) && ($idx > $cutoff))
         {
            $ok  = 0;
            $msg = "A required positional parameter ($signature_spec[$idx]->{name}) cannot appear after an optional one";
            last;
         }
      }
   }
   $signature_info{signature_param_count} = scalar @signature_spec;
   $signature_info{required_names}        = \@required_names;
   $signature_info{optional_names}        = \@optional_names;
   $signature_info{all_names}             = \@all_names;
   $signature_info{required_count}        = scalar @required_names;
   $signature_info{optional_count}        = scalar @optional_names;
   $signature_info{arg_count}             = scalar @all_names;

   foreach $name (@all_names)
   {
      $regex .= "$name|";
   }
   chop $regex;
   $signature_info{name_regex} = qr/$regex/;
   if (exists($signature_info{positional_cutoff}))
   {
      if ($signature_info{positional_cutoff} == 0)
      {
         $signature_info{param_style} = $NAMED;
      }
      else
      {
         $signature_info{param_style} = $MIXED;
      }
   }

   # produce a somewhat optimized validation sub just for this signature
   $signature_info{validate_sub} = $self->_generate_validate_sub(\%signature_info);

   #_print_debug("done: sub _build_signature_info");
   return (\%signature_info, $ok, $msg);
}

sub validate_method
{
   my $self_ref = ref($_[0]);    # determine how sub was called (obj,class,sub?)
   my $self =
     ($self_ref && $self_ref ne "ARRAY" && $self_ref ne "HASH") ?
     shift @_ :
     (($_[0] eq "Params::Signature") ? (shift @_ and $class_default) : $class_default);
   my (
       $caller_args,        $args,          $caller_signature, $signature,       $cfg,         $invocant,
       $invocant_signature, $invocant_type, $invocant_name,    $invocant_passed, @result_list, $result_hash
       );

   # validate params
   # actual params to calling subroutine (\@_ in calling subroutine)
   if (ref($_[0]) ne "ARRAY") { $self->{on_fail}->("$self->{called} Invalid argument list: expected array reference"); return; }

   # signature specification
   if (ref($_[1]) ne "ARRAY")
   {
      $self->{on_fail}->("$self->{called} Invalid signature: expected array reference, got " . ref($_[1]));
      return;
   }

   # validate cfg options
   if ($_[2] && ref($_[2]) ne "HASH")
   {
      $self->{on_fail}->("$self->{called} Invalid validation options: expected hash reference");
      return;
   }
   ($caller_args, $caller_signature, $cfg) = ($_[0], $_[1], ($_[2] || {}));

   # don't mess with @_ in caller, make our own copy
   push(@{$args}, @{$caller_args});

   # don't mess with caller signature, make our own copy
   push(@{$signature}, @{$caller_signature});

   $invocant           = shift(@{$args});
   $invocant_signature = shift(@{$signature});
   ($invocant_type, $invocant_name) = split(/\s+/, $invocant_signature);

   if (!$cfg->{caller})
   {
      # 'check' sub must know who the top level caller is to find the invocant_type in the caller's namespace
      $cfg->{caller} = caller;
   }

   $invocant_passed = $self->check($invocant_type, $invocant, $cfg);

   if (!$invocant_passed)
   {
      $self->{on_fail}->("$self->{called} Invalid method invocant -- $invocant not '$invocant_type'");
      return;
   }

   if (wantarray)
   {
      @result_list = $self->validate($args, $signature, $cfg);
      unshift(@result_list, $invocant);
      return (@result_list);
   }
   else
   {
      $result_hash = $self->validate($args, $signature, $cfg);
      $result_hash->{$invocant_name} = $invocant;
      return ($result_hash);
   }
}

# called as: validate(\@_, [ spec ], { cfg });
# called as: validate(
#        \@_,
#        [ spec ],
#        {
#            normalize_keys => sub{},
#            on_fail => sub{},
#            fuzzy => [0|1|2],
#            called => "msg",
#            caller => "package::name",
#            callbacks => { field => { cb_name => sub{} }
#        }
#        );

sub validate
{
   # params = parameters passed to validate
   # args = parameters passed to caller
   my $self_ref = ref($_[0]);    # determine how sub was called (obj,class,sub?)
   my $self =
     ($self_ref && $self_ref ne "ARRAY" && $self_ref ne "HASH") ?
     shift @_ :
     (($_[0] eq "Params::Signature") ? (shift @_ and $class_default) : $class_default);
   my (
       $cache_key,      $signature_info, $on_fail,   $param_style,    $caller,         $check_only,
       $coerce,         $ok,             $msg,       $called,         $arg_hash,       $max,
       $idx,            $signature_spec, $arg_count, $field,          $type_passed,    $tc,
       $type,           $spec,           $value,     $fuzzy,          %name_lookup,    $key,
       $normalize_keys, $args,           $signature, $cfg,            @depends_fields, @extra_fields,
       $extra_ok,       $name_regex,     $nr2,       $arg_hash_index, %arg_hash_copy,  $arg_hash_copy_set,
       $how_many
       );

   # validate params
   if (ref($_[0]) ne "ARRAY") { $self->{on_fail}->("$self->{called} Invalid argument list: expected array reference"); return; }
   if (ref($_[1]) ne "ARRAY")
   {
      $self->{on_fail}->("$self->{called} Invalid signature: expected array reference, got " . ref($_[1]));
      return;
   }

   # validate cfg options
   if ($_[2] && ref($_[2]) ne "HASH")
   {
      $self->{on_fail}->("$self->{called} Invalid validation options: expected hash reference");
      return;
   }
   ($args, $signature, $cfg) = ($_[0], $_[1], ($_[2] || {}));

   $fuzzy          = $cfg->{fuzzy}          || $self->{fuzzy} || $FUZZY_OFF;
   $on_fail        = $cfg->{on_fail}        || $self->{on_fail};
   $normalize_keys = $cfg->{normalize_keys} || $self->{normalize_keys};
   $caller         = $cfg->{caller}         || $self->{caller} || caller;
   $called         = $cfg->{called}         || $self->{called} || $caller;
   $arg_hash       = {};
   $arg_count      = scalar @{$args};
   $arg_hash_index = 0;

   # get signature info
   $cache_key = $caller . join("$FIELD_SEPARATOR", @{$signature});
   if (exists($self->{cache}{$cache_key}))
   {

      $signature_info = $self->{cache}{$cache_key};
   }
   else
   {
      ($signature_info, $ok, $msg) = $self->_build_signature_info($signature, $caller);
      if (!$ok)
      {
         $on_fail->("$called $msg");
         return;
      }
      $self->{cache}{$cache_key} = $signature_info;
   }
   $param_style    = $cfg->{param_style} || $signature_info->{param_style} || $self->{param_style};
   $extra_ok       = (exists($signature_info->{extra_cutoff}));
   $signature_spec = $signature_info->{signature_spec};

   $ok = 0;
   if ((($param_style eq $NAMED) || ($fuzzy == $FUZZY_HASH_OK && $param_style ne $NAMED)) &&
       ($arg_count == 1) &&
       ref($args->[$arg_hash_index]) eq "HASH")
   {
      if ($normalize_keys)
      {
         foreach $field (keys %{$args->[$arg_hash_index]})
         {
            # save copy because normalize_keys may alter its arg
            $key   = $field;
            $field = $normalize_keys->($field);
            if ($spec = $signature_info->{map}{$field})
            {
               $arg_hash->{$field} = $args->[$arg_hash_index]->{$key};
               $ok = 1;
            }
            elsif (!$extra_ok)
            {
               # this field doesn't belong in a named arg hash, so
               # this hash should not be treated as a list of named args
               if ($param_style eq $NAMED)
               {
                  # args MUST be named parameters, so the fact that
                  # $field is not valid indicates invalid args
                  $on_fail->("$called Found unexpected named parameter: $field");
                  $ok = 0;
                  return;
               }

               # process (as positional?) below
               $arg_hash = {};
               $ok       = 0;
               last;
            }
            else
            {
               # extra field
               $arg_hash->{$field} = $args->[$arg_hash_index]->{$key};
               $ok = 1;
            }
         }
      }
      else
      {
         $arg_hash_copy_set = 0;
         foreach $field (keys %{$args->[$arg_hash_index]})
         {
            if ($spec = $signature_info->{map}{$field})
            {
               # found a valid field name, so move on
               # NOTE: making a shallow copy of the original hash so we don't mess up
               #       the original, which could have unintended consequences
               #       since we would be making changes to that hash; the original hash could
               #       be something that the caller uses for other purposes
               if (!$arg_hash_copy_set)
               {
                  $arg_hash_copy_set = 1;
                  %arg_hash_copy     = %{$args->[$arg_hash_index]};
                  $arg_hash          = \%arg_hash_copy;
               }

               $ok = 1;
            }
            elsif (!$extra_ok)
            {
               # this field doesn't belong in a named arg hash, so
               # this hash should probably not be treated as a list of named args;
               # this may be a required or optional argument that just happens to be a hash,
               # so we're going to treat it as a positional parameter
               if (($param_style eq $POSITIONAL) || ($param_style eq $MIXED))
               {
                  # process (as positional?) below
                  $arg_hash = {};
                  $ok       = 0;
                  last;
               }
               else
               {
                  # args MUST be named parameters, so the fact that
                  # $field is not valid indicates invalid args
                  $on_fail->("$called Found unexpected named parameter: $field");
                  $ok = 0;
                  return;
               }
            }
            else
            {
               # extra field ... handle degenerate case when only
               # "..." is set in signature
               $arg_hash->{$field} = $args->[$arg_hash_index]->{$field};
               $ok = 1;
            }
         }
      }
      if ($ok)
      {
         $param_style = $NAMED;
      }
   }

   if (
      # supposed to get named args but not using a hash, but it could be raw key/value pairs
      (($param_style eq $NAMED) && (!$ok) && ($arg_count % 2 == 0)) ||

      # it's a mix of positional and named args
      ($param_style eq $MIXED) ||

      # we're not using a named param style, but it's ok for the app to use raw key/value pairs,
      # which is what we might have
      (($fuzzy == $FUZZY_KV_OK && $param_style ne $NAMED) && (!$ok) && ($arg_count % 2 == 0))
     )
   {
      my %h;
      if ($param_style eq $MIXED)
      {
         if (ref($args->[$signature_info->{positional_cutoff}]))
         {
            %h = %{$args->[$signature_info->{positional_cutoff}]};
         }
         else
         {
            # handle ["Int pos", "Str :name_it"]
            # foo(123, name_it => "hey");
            # NOTE: name_it is not inside a hash
            my $end = $#{$args};
            %h         = @$args[$signature_info->{positional_cutoff} .. $end];
            $arg_count = $signature_info->{positional_cutoff} + scalar keys(%h);
         }
      }
      else
      {
         # positional param style, but with an even number of parameters, so this looks like
         # it could be raw key/value pairs
         %h = @$args;
      }

      if ($normalize_keys)
      {
         foreach $field (keys %h)
         {
            # save copy because normalize_keys will alter its arg
            $key   = $field;
            $field = $normalize_keys->($field);
            if ($spec = $signature_info->{map}{$field})
            {
               $arg_hash->{$field} = $h{$key};
               $ok = 1;
            }
            elsif (!$extra_ok)
            {
               # this field doesn't belong in a named arg hash, so
               # this hash should not be treated as a list of named args
               if (($param_style eq $NAMED) || ($param_style eq $MIXED))
               {
                  # args MUST be named parameters, so the fact that
                  # $field is not valid indicates invalid args
                  $on_fail->("$called Found unexpected named parameter: $field");
                  $ok = 0;
                  return;
               }
               $arg_hash = {};
               $ok       = 0;
               last;
            }
            else
            {
               $arg_hash->{$field} = $h{$key};
               $ok = 1;
            }
         }
      }
      else
      {
         foreach $field (keys %h)
         {
            if ($spec = $signature_info->{map}{$field})
            {
               $arg_hash = \%h;
               $ok       = 1;
            }
            elsif (!$extra_ok)
            {
               # this field doesn't belong in a named arg hash or
               # in the "mixed" hash
               if (($param_style eq $NAMED) || ($param_style eq $MIXED))
               {
                  # args MUST be named parameters, so the fact that
                  # $field is not valid indicates invalid args
                  $on_fail->("$called Found unexpected named parameter: $field");
                  $ok = 0;
                  return;
               }

               # process args as positional below
               $arg_hash = {};
               $ok       = 0;
               last;
            }
            else
            {
               $arg_hash->{$field} = $h{$field};
               $ok = 1;
            }
         }
      }
      if ($ok && $param_style ne $MIXED)
      {
         $param_style = $NAMED;
      }
   }

   if (($param_style eq $POSITIONAL) || ($param_style eq $MIXED))
   {
      if ($arg_count > $signature_info->{signature_param_count} &&
          (!$extra_ok))
      {
         $how_many = $arg_count - $signature_info->{signature_param_count};
         if ($field)
         {
            $on_fail->("$called Encountered $how_many unexpected extra parameter(s) like $field [style=$param_style]");
         }
         else
         {
            $on_fail->("$called Encountered $how_many unexpected extra parameter(s) [style=$param_style]");
         }
         return;
      }

      # ... now process args until we reach a cutoff marker or the end

      # ["Int one", "Int two?", "named:", "..."]
      # foo(1);
      # foo(1,2);
      # foo(1,2,3); # 3 should be a named, extra param
      $max = $arg_count;

      # skip extra params after extra_cutoff
      $max = (!$extra_ok || $max < $signature_info->{extra_cutoff}) ? $max : $signature_info->{extra_cutoff};

      # skip anything past positional cutoff
      $max =
        (!exists($signature_info->{positional_cutoff}) || $max < $signature_info->{positional_cutoff}) ? $max :
        $signature_info->{positional_cutoff};

      # args are associated with the corresponding positional argument
      # name in the signature specification
      for ($idx = 0; $idx < $max; $idx++)
      {
         if ($spec = $signature_spec->[$idx])
         {
            $field = $spec->{name};
            $arg_hash->{$field} = $args->[$idx];
         }
      }
      if ($extra_ok && ($param_style eq $POSITIONAL))
      {
         for ($idx = $signature_info->{extra_cutoff}; $idx < $arg_count; $idx++)
         {
            push(@extra_fields, "p_$idx");
            $arg_hash->{"p_$idx"} = $args->[$idx];
         }
      }
   }

   $ok = $signature_info->{validate_sub}->($self, $args, $arg_hash, $signature_info, $cfg, $caller);
   if (!$ok)
   {
      # on_fail should have been called inside validate_sub
      return;
   }

   # if extra fields are not allowed, check if we have any
   if (!$extra_ok)
   {
      foreach $key (keys %{$arg_hash})
      {
         if (!exists($signature_info->{map}{$key}))
         {
            $on_fail->("$called Encountered unexpected extra parameter: $key");
            return;
         }
      }
   }

   if (wantarray)
   {
      if ($extra_ok)
      {
         foreach $key (keys %{$arg_hash})
         {
            if (!exists($signature_info->{map}{$key}))
            {
               push(@extra_fields, $key);
            }
         }
      }

      # building this list is slower than returning arg_hash;
      # building a list of fields "as we go" took too much time in previous
      # version of this sub, so we make @extra_fields at the last
      # minute (if it's actually needed) ...
      # if you want a list, I guess you have to take the performance hit
      return map { $arg_hash->{$_} } (@{$signature_info->{all_names}}, @extra_fields);

   }
   else
   {
      return $arg_hash;
   }
}

sub _generate_validate_sub
{
   my ($self, $signature_info) = @_;
   my $sub;
   my $s;
   my $chunk;
   my $idx;
   my $max = $signature_info->{arg_count};
   my $field;
   my $spec;

   $sub = <<'EOT'
        my ($self, $args, $arg_hash, $signature_info, $cfg, $caller) = @_;
        my $coerce   = (exists($cfg->{coerce})) ? $cfg->{coerce} : $self->{coerce} ;
        my $called   = (exists($cfg->{called})) ? $cfg->{called} : $self->{called} ;
        my $on_fail   = (exists($cfg->{on_fail})) ? $cfg->{on_fail} : $self->{on_fail} ;
        my (
        $value,
        $spec,
        $field,
        $type_passed,
        $type,
        $tc,
        $tc_name
        );

        my $signature_spec = $signature_info->{signature_spec};
        $type_passed = 1;
EOT
     ;

   for ($idx = 0; $idx < $max; $idx++)
   {
      $spec = $signature_info->{signature_spec}->[$idx];
      if (!$spec->{name}) { $self->{on_fail}->("Parameter name is missing"); }
      $field = $spec->{name};
      $chunk = "";

      # %idx% = $idx
      # %field% = $field

      if ($spec->{has_alias})
      {
         foreach my $alias (@{$spec->{aliases}})
         {
            $chunk .= "if (exists(\$arg_hash->{'$alias'})) { \$arg_hash->{%field%} = delete \$arg_hash->{'$alias'}; }";
         }
      }

      if ($spec->{optional})
      {
         $chunk .= 'if (exists($arg_hash->{%field%})) {';
      }
      $chunk .= <<'EOC'

        # validate arg (assign default, check value, coerce&check)
        $spec            = $signature_info->{signature_spec}->[%idx%];
        $value           = $arg_hash->{%field%};
        $field           = $spec->{name};
EOC
        ;
      if (defined($spec->{default_type}) && $spec->{default_type} != $ASSIGN_NONE)
      {
         $chunk .= 'if (!defined($value)) { ';
         if ($spec->{default_type} == $ASSIGN_LITERAL)
         {
            $chunk .= '$arg_hash->{%field%} = $value = $spec->{default};}';
         }
         elsif ($spec->{default_type} == $ASSIGN_SUB)
         {
            $chunk .= '$arg_hash->{%field%} = $value = $spec->{default}->();}';
         }
         elsif ($spec->{default_type} == $ASSIGN_PARAM)
         {
            $chunk .= '$arg_hash->{%field%} = $value      = $arg_hash->{$spec->{default}};}';
         }
         else
         {
            # should not happen!
            $chunk = "} ";
         }
      }

      $chunk .= <<'EOC'
        foreach $type (@{$spec->{types}})
        {
            $type_passed = $$type->{check}->($value);
            #$tc = $$type->{tc};
            if ($type_passed) { last; }

            if (!$type_passed && $$type->{'has_coercion'} && $coerce)
            {
                $value = $$type->{tc}->coerce($value);
                $type_passed = $$type->{check}->($value);
                if ($type_passed)
                {
                    $arg_hash->{%field%} = $value;
                    last;
                }
            }
        }

        if (!$type_passed)
        {
            if (!defined($value)) { $value = 'undef'; }
            $on_fail->("$called %field% failed validation. Expected $spec->{type}, got $value");
            return;
        }
EOC
        ;

      if ($spec->{depends})
      {
         foreach $field (@{$spec->{depends}})
         {
            $chunk .= <<"EOC"
                # set to undef to force validation later
                if (!exists(\$arg_hash->{$field}))
                {
                    \$arg_hash->{$field} = undef;
                }
EOC
              ;
         }
      }

      $chunk .= <<'EOC'
        #     if field has callbacks, run each callback(value, arg_hash)
        if ($cfg->{callbacks})
        {
            my $cbs = $cfg->{callbacks}->{%field%};

            #_print_debug("Callbacks for $spec->{name}:", Dumper($cbs));
            foreach my $c (keys(%{$cbs}))
            {

                #_print_debug("Callback for $spec->{name}:", Dumper($c));
                $type_passed = $cbs->{$c}->($value, $args, $arg_hash);
                if (!$type_passed)
                {
                    $on_fail->("$called %field% failed validation via callback '$c'");
                    last;
                }
            }
        }
EOC
        ;
      if ($spec->{optional})
      {
         $chunk .= "}\n";
      }
      $chunk =~ s/%field%/'$field'/g;
      $chunk =~ s/%idx%/$idx/g;
      $sub .= $chunk;

   }

   $sub .= ' return $type_passed;';

   #print STDERR $sub;

   $s = eval "sub { $sub }";

   # if code in $sub is valid, eval should work
   #if ($@) { print STDERR "uh-oh=$@\n"; } # DEBUG
   return $s;
}

sub _print_debug
{
   if ($debug)
   {
      print STDERR join("\n", @_, "\n");
   }
}

# used to reset class_default during tests;
# should not be used in applications
sub _change_class_default
{
   my $class = shift;
   $class_default = shift;
}

# must initialize $class_default once compilation completes
eval {
   $class_default = Params::Signature->new(
                                           param_style => $DEFAULT_PARAM_STYLE,
                                           fuzzy       => $FUZZY_OFF,
                                           coerce      => 1,
                                           on_fail     => \&confess,
                                           called      => "Params::Signature:"
                                           );
};
1;
__END__

=head1 NAME

Params::Signature - support for parameter validation based on a subroutine signature, including type declaration, default values, optional parameters, and more

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

The examples below do not cover more advanced scenarios which are covered in the L<Params::Signature::Manual>.  This page deals primarily with the class' public methods. 

    use Params::Signature qw(:all);
    use Type::Utils;

    # use built-in types in signature
    my $params_hashref = validate(\@_, ["Str s", "Int i"])

    # register new types to extend default type constraint system
    our $Foo_Bar = class_type Foo_Bar => {class => "Foo::Bar"};
    our $DoesIt = role_type DoesIt => {class => "MyRoles::Does::It"};
    our $is_1_2_or_3 = enum "is_1_2_or_3", [qw(1 2 3)];

    # use a CODE ref as a type constraint
    our $HashRef2 = sub { ref($_[0]) eq "HASH" };

    my $params_hashref = validate(\@_, ["DoesIt doit", "HashRef a_hash"])
    my $params_hashref2 = validate(\@_, ["DoesIt doit", "HashRef2 a_hash"])

    # to magically coerce a hash into a Foo::Bar via validate()
    coerce "Foo_Bar", from "HashRef", via { new Foo::Bar(%{$_[0]}) };

    # if bar is a HashRef in @_ it will be coerced by validate
    # into a Foo::Bar object in @params_array
    my @params_array = validate(\@_, ["is_1_2_or_3 number", "Foo_Bar bar"])

    my $something = Something->new();
    @params_array = $something->method(1);
    # @params_array = (1, 2)

    package Something;
    sub new {...};

    sub method
    {
      # Note: the subroutine called to set the default value MUST be
      #       fully qualified (include the package name)
      ($self, $one, $two) = Params::Signature->validate_method(\@_, ["Object self", "Str one", "Int two = Something::set_two()"]);
      return ($one, $two);
    }
    sub set_two
    {
      return(2)
    }

=head1 DESCRIPTION

In its simplest form, you call Params::Signature's validate method with your parameters and a signature specification:

    $params = $signature->validate(\@_, ["Str x = 'default'", "Undef|Str y?"]);

The signature is a list of parameter definitions.  A basic parameter definition is a string which consists of a type constraint and the name of the parameter.  The actual type constraints are defined via an external module, such as L<Type::Tiny> or L<Moose::Util::TypeConstraints>.  Type constraints can also be implemented as subroutine references.  Parameters are required by default.  A default value may be assigned to a required parameter, but not an optional one.  Parameters may be flagged as optional using the optional flag (trailing question mark).

More advanced scenarios are also supported.  Per-parameter callbacks can be used for advanced parameter validation.  Parameter aliases can be used to call a parameter by different names (e.g., "-param" or "param")  In some cases, instead of using aliases, it may make more sense to use a subroutine to normalize parameter names (i.e., convert "-param" to "param").  Advanced topics such as these are discussed in the L<Params::Signature::Manual>.

=head1 METHODS

All functionality is accessed via methods.  You can use class methods (C<Params::Signature->method()>) or construct a module/application-specific Params::Signature (singleton) object.  Class methods are used to validate parameters using the default global settings.  By default, parameters are positional, fuzzy logic is disabled, and Carp::confess is used to report failures.  Class methods work just like object methods.  The exported subroutines C<validate> and C<check> are actually calls to the class methods with the default settings.

    use Type::Utils;
    use Params::Signature qw(:all);  # exports 'validate', 'check', 'hash_param_ok', 'kv_param_ok', 'strict_param'

    our $EvenInt = declare "EvenInt",
                    as Int,
                    via { $_[0] % 2 == 0 };
    our $EvenNum = declare "EvenNum",
                    as Num,
                    via { $_[0] % 2 == 0 };


    # later ... use new types in a signature 
    Params::Signature->validate(
                    \@_,
                    ["EvenInt one", "EvenNum two", "Str three"]
                    );
    # - same as -
    validate(\@_,
            ["EvenInt one", "EvenNum two", "Str three"]
            );

    #  - or use an object -

    my $signature = new Params::Signature(fuzzy => hash_param_ok);

    # later ... use new type known only to $signature
    $signature->validate(\@_, ["EvenNum one", "EvenInt two", "Str three"]);


=head2 new

    new Params::Signature(
            param_style => positional_style,
            fuzzy => hash_param_ok,
            coerce => 1,
            on_fail => sub { oops($_[0]) },
            normalize_keys => sub { lc $_[0] },
            called => "My::Module"
        );

B<param_style>: Parameter style is one of "positional_style", "named_style" or "mixed_style".  The actual signature passed to L</"validate"> may override the default set in the new signature object.  The default value in the object is used when the actual subroutine signature lacks sufficient information to determine the parameter style.

B<fuzzy>: Allow the L</"validate"> method to use 'fuzzy logic' to determine the parameter passing style used to invoke the caller.  Enable this if you want to be able to call a subroutine with either positional parameters or key/value pairs that match the subroutine signature.  When using named parameters, values should be passed as a hash.  However, "raw" key/value pairs in @_ are supported but are generally not considered a good practice.  If raw key/value pairs are used, the list must be balanced (it must have an even number of values). The fuzzy logic confirms that at least one parameter name from the signature appears as a key (however the key is found). 

=over

=item 0 | strict_param

Fuzzy parameter checking is disabled

=cut

=item 1 | hash_param_ok

Fuzzy parameter checking is enabled, but named parameters MUST be passed in a hash at C<$_[0]>.  At least 1 parameter name from the signature must exist in the hash, otherwise the hash will not be treated specially.

=cut

=item 2 | kv_param_ok

Fuzzy parameter checking is enabled, so named parameters MAY be passed in a hash at C<$_[0]> OR as raw key/value pairs.  If a hash is used, the rules for "fuzzy=1" are used.  Raw key/values must be "balanced" (an even number) in order to be treated as the key/value pairs of a hash.  At least 1 parameter name from the signature must exist in this hash, otherwise the parameters are not given any special treatment.  This form is potentially dangerous because it can be ambiguous.  You've been warned.

=cut

=back


    my $fuzzy_signature = new Params::Signature(fuzzy => kv_param_ok);

    ...

    # ok - positional: all parameters defined in signature are present 
    foo("hi", 2, 3); 

    # ok - named: both parameter names are at correct index 
    foo(one => "hi", two => 2);

    # preferred - named: hash makes it clear that "named" style is in 
    # use and any unbalanced parameters will be caught at compile time
    foo({one => "hi", two => 2});

    # poor: 
    #   fuzzy=1|hash_param_ok: this would be processed as positional
    #   fuzzy=2|kv_param_ok: this would be processed as named
    foo(one => 1);

    # really BAD:
    # is "one" supposed to be a parameter name or
    # an actual value? it's impossible to tell!
    #
    #  fuzzy=1|hash_param_ok: processed as positional
    #         in foo: $param = { "one" => "one", "two" => 2, "p_2" => 3, "p_3" => 4 }
    #
    #  fuzzy=2|kv_param_ok: processed as named
    #         in foo: $param = { "one" => 2, "3" => 4 }
    foo("one", 2, 3, 4);

    # not as bad: the list is uneven, so it will not be treated
    # as key/value pairs; these are handled as positional
    #   in foo: $param = { "one" => "one", "two" => 2, "p_2" => 3 }
    foo("one", 2, 3);

    sub foo
    {
        my $param = $fuzzy_signature->validate(
                        \@_,
                        ["Str one", "Int two?", "..."]
                        );
        ...
    }

If fuzzy is enabled, it is mandatory that you pass named values in one anonymous hash or keys as positional values at the appropriate index position.  That said, you really should use a hash and not raw key/value pairs.  A clash between a raw value and a key name could lead to really bad results.  Consider yourself warned!  Consider fuzzy=1 and a real hash as a "best practice".

B<coerce>:  If a parameter value can be coerced into the type required in a signature, the L</validate> method will automatically coerce it and return the coerced value rather than the original value.  If multiple types are accepted for a parameter, L</validate> will attempt to coerce the parameter value into each of the acceptable types until it finds one that succeeds or all coercion attempts fail.  Coercions are implemented by the type constraint.

    # this will coerce the value for 'even' into an EvenInt first
    # then an EvenNum (assuming coercions for both types have
    # been registered)
    @params = validate(\@_, ["EvenInt|EvenNum even"]);

B<on_fail>:  Set the subroutine to call if an error is encountered.  Carp::confess is called by default.

B<normalize_keys>: A subroutine to normalize named parameters passed in to caller.

    my $signature = new Params::Signature(
                        param_style => named_style,
                        normalize_keys => sub { $_[0] =~ s/^-//; lc $_[0] }
                        );

    sub foo
    {
        my $params = $signature->validate(
                        params => \@_,
                        signature => ["Int one"]
                        );
        ...
    }
    foo({-one => 1});
    foo({-ONE => 1});
    foo({one => 1});

B<called>: String inserted at the beginning of each failure message.  Your module or application name are good candidates for this value.

=cut

=head2 validate

Validate the parameters passed to a subroutine using a subroutine signature.

    # use class method
    my $params = Params::Signature->validate(
                      \@_,
                      [
                          "Int one",
                          "Int two",
                          "Int :$named_param",
                          "Int :$opt_named",
                          "..."
                      ]
                  );

    # use exported subroutine
    my $params = validate(
                      \@_,
                      [
                          "Int one",
                          "Int two",
                          "Int :$named_param",
                          "Int :$opt_named",
                          "..."
                      ]
                  );

    # use object
    my $params = $signature->validate(
                            \@_,
                            [
                                "Int one",
                                "Int two",
                                "Int :$named_param",
                                "Int :$opt_named",
                                "..."
                            ]
                        );

    # use configuration hash (3rd parameter) to override default settings
    my $params = validate(
                    \@_,
                    [
                        "Int one",
                        "Int two",
                        'named:',
                        "Int named_param",
                        "Int opt_named",
                        "..."
                    ],
                    {
                        param_style => mixed_style,
                        normalize_keys => sub { lc $_[0] },
                        fuzzy => hash_param_ok,
                        called => "YourModule",
                        on_fail => \&catch_validation_error,
                        callbacks => {
                            one => {
                                "equals one" => sub { $_[0] == 1 }
                                }
                            },
                    }
                );

You can also validate the parameters passed to a method.

    my $self = shift;
    my $params = $signature->validate_method(
                \@_,
                ["Object self", "Int one", "Int two", "Int :opt_named?"]
                );

    - or -

    my $params = $signature->validate_method(
                \@_,
                ["Object self", "Int one", "Int two"]
                );


B<params>: A reference to an array of parameters passed to the calling subroutine.  Normally this is a reference to C<@_>.

B<signature>: The actual subroutine signature is an array with each element representing one parameter.  Positional parameters are expected to be passed in in the same order as they appear in the signature.

B<Configuration Parameters>: A hash containing any of the following values.  Values set in this hash override default values passed in to the object constructor or pre-defined as a global default.

B<param_style>: Explicitly set the parameter style used to validate parameters.  The definition of the signature itself will (silently) overrule this value if there is a conflict.  For example, setting this value to 'positional_style' while explicitly defining all fields as named values will force the parameter style to "named style".

B<normalize_keys>: A reference to a subroutine.  For named parameters, alters each key passed to the calling subroutine to match the parameter names used in the signature.  The routine is passed one key at a time.  The names in the signature are not passed to this subroutine.

B<fuzzy>: Enable 'fuzzy logic' used to determine what type of parameter style was used.  This overrides the default in the Params::Signature object or the global (class) value.  Values are 'hash_param_ok', 'kv_param_ok' or 'strict_param' (the default).

B<coerce>: Enable (1) or disable (0) automatic coercion of parameter values.  The global (class) default is 'enabled' (value set to 1).

B<called>: A string included at the beginning of any error messages produced.  Normally, the name of the module or application that called validate; however, this can be any string.

B<caller>: The name of the module or application that called validate.  It is the namespace which will be searched for type constraint definitions.  If not set, it will be set to the scalar value returned by C<caller>.

B<on_fail>: Override Carp::confess as the subroutine that gets called when a failure occurs.

B<callbacks>: A hash for fine-grained testing of values which goes beyond type checking.  The hash keys match the parameter names in the signature.  The value of each key is a hash of test names and subroutine references.  This allows per-parameter validation callback routines.  The callback routine receives 3 parameters - the parameter value, the original values passed to the C<validate> method, a hash containing a list of values that have already been validated or will be validated.  Note that values in the third parameter are validated in order of appearance in the signature. The hash is ultimately returned to the caller, if C<validate> is called in scalar context.  As a result, values can be inserted into the hash for eventual use by the caller.

B<Return Value>:

In scalar context, the method returns a hash reference with key/value pairs for each parameter that has a value.  In list context, this method returns a list of parameter values in the order of appearance in the signature.  If extra parameters are passed in (and allowed), they are appended to the list in the order of appearance in C<@_>.  Extra positional parameters are named 'p_#' in the returned hash.  If a mixed parameter style was used, the list contains positional and named parameters in the order they appear in the signature.  If you are using a mixed parameter style, it may be easier to call the validate method in scalar context and use keys to access all parameters.  That said, a (somewhat) sane result is returned in list context.

    mixed_foo(1, undef, {three => 3, four => 4});
    sub mixed_foo
    {
        # get hash in scalar context (and use a perl 6-ish signature)
        my $params = $signature->validate(
                        \@_,
                        ["Int $one", "Int $two = 2", "Int :$three", "..."]
                        );
        # $params = { one => 1, two => 2, three => 3, four => 4 }

        # get a list in list context (signature happens to use
        # the "native" signature style)
        my @params = $signature->validate(
                     \@_,
                     ["Int one", "Int two = 2", "named:", "Int three", "..."]
                     );
        # @params = [ 1, 2, 3, 4]
    }

    bar(1,undef,3)
    sub bar
    {
        # get hash in scalar context (and use a perl 6-ish signature)
        my $params = $signature->validate(
                        \@_,
                        ["Int $one", "Int $two", "Int $three"]
                        );
        # $params = { one => 1, two => undef, three => 3}

        # get a list in list context 
        my @params = $signature->validate(
                            \@_,
                            ["Int one", "Int two", "Int three"]
                            );
        # @params = [ 1, undef, 3 ]
    }

    has_extra(1,2,3,4);
    sub has_extra
    {
        # get hash in scalar context (and use a perl 6-ish signature)
        my $params = $signature->validate(
                        \@_,
                        ["Int one", "Int two", "..."]
                        );
        # $params = { one => 1, two => 2, p_2 => 3, p_3 => 4}

        # get a list in list context 
        my @params = $signature->validate(
                            \@_,
                            ["Int one", "Int two", "..."]
                            );
        # @params = [ 1, 2, 3, 4 ]
    }

=cut

=head2 validate_method

Use C<validate_method> to validate parameters passed to an object method.  The first parameter (the object itself) is validated by C<validate_method>.  If object validation is successful, C<validate> is called with the remaining parameters.

    my $params = $signature->validate_method(
                \@_,
                ["Object self", "Int one", "Int two"]
                );

    my ($self, $one, $two) = $signature->validate_method(
                \@_,
                ["Object self", "Int one", "Int two"]
                );
=cut

=head2 check

This method is used to confirm a value meets a type constraint.  The type constraint string can be made up of multiple types.

    my $is_ok = $signature->check("Int|Num|Undef", $value)

B<type>: the type constraint, which can be multiple types separated by an or bar (pipe symbol)

B<value>: the value to be checked

B<Return Value>:

In scalar context, returns 1 if the value matches at least one type in the type constraint or 0 otherwise.

In list context, returns (passed, value, msg, tc) where passed is a 1 or 0, value is the tested value, msg is an error message (if there is one), and tc is a reference to the matching type constraint.


=cut

=head1 PERFORMANCE

The Params::Signature object caches the parsed form of each signature it validates.  Re-using the same object to validate subroutine parameters eliminates the need to parse the signature every time.  Using a singleton per module or application is recommended for reducing the amount of time it takes to validate parameters.  Based on benchmarks, it runs about as fast as the XS version of L<Params::Validate> but is not as fast as L<Data::Validator>.


=head1 LIMITATIONS AND CAVEATS

Moo is supported indirectly because Params::Signature's methods expect a type constraint to be either a subroutine (which is what Moo uses) or a Moose::Meta::TypeConstraint-like object.  As a happy medium, Type::Tiny can be used to declare type constraints that are objects (which makes Params::Signature happy) which overload C<&()> so that the object can be treated as a subroutine (which makes Moo happy).  So, Params::Signature, Type::Tiny and Moo are happy to work together.  Of course, you can use subroutine references, if you prefer.

If using threads, it's recommended that your module or application define a singleton to use to validate parameters.  Using a separate object per thread should be safe, though this has not been tested. 

When "fuzzy" is enabled, C<validate> attempts to automatically determine whether positional or named arguments were passed to the caller.  This logic is heuristic and can be ambiguous when argument values happen to match parameter names.  C<fuzzy = 1> is strict and only treats a single hash reference as named input, while C<fuzzy = 2> is more permissive and may accept raw key/value pairs.  Using "fuzzy" to decipher intent is powerful but potentially problematic.

The "fuzzy" logic may need to be improved to handle corner cases I did not think of.

There is no XS version of this module at this time.  It's pure perl.  Perhaps that's a feature rather than a limitation?

=cut

=head1 AUTHOR

Sandor Patocs

=head1 BUGS

Please report any bugs or feature requests on GitHub at
L<https://github.com/spatocs/params_signature/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Params::Signature


You can also look for information at:

=over 4

=item * GitHub: source repository and issue tracker

L<https://github.com/spatocs/params_signature>

=item * MetaCPAN

L<https://metacpan.org/release/Params-Signature>

=back


=head1 ACKNOWLEDGEMENTS

Params::Validate, MooseX::Method::Signatures and Method::Signatures all served as inspiration for this module.

=head1 SEE ALSO

L<Params::Signature::Manual>, L<Params::Validate>, L<MooseX::Method::Signatures>, L<Method::Signatures>, L<Perl6::Signature>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sandor Patocs.

This program is distributed under the terms of the Artistic License (2.0)


=cut

1; # End of Params::Signature
