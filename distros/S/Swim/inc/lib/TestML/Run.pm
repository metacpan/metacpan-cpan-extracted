use strict; use warnings;
package TestMLFunction;

sub new {
  my ($class, $func) = @_;
  return bless {func => $func}, $class;
}

package TestML::Run;

use JSON::PP;

use utf8;
use TestML::Boolean;
use Scalar::Util;

# use XXX;

my $vtable = {
  '=='    => 'assert_eq',
  '~~'    => 'assert_has',
  '=~'    => 'assert_like',
  '!=='   => 'assert_not_eq',
  '!~~'   => 'assert_not_has',
  '!=~'   => 'assert_not_like',

  '.'     => 'exec_dot',
  '%'     => 'each_exec',
  '%<>'   => 'each_pick',
  '<>'    => 'pick_exec',
  '&'     => 'call_func',

  '"'     => 'get_str',
  ':'     => 'get_hash',
  '[]'    => 'get_list',
  '*'     => 'get_point',

  '='     => 'set_var',
  '||='   => 'or_set_var',
};

my $types = {
  '=>' => 'func',
  '/' => 'regex',
  '!' => 'error',
  '?' => 'native',
};

#------------------------------------------------------------------------------
sub new {
  my ($class, %params) = @_;

  my $testml = $params{testml};

  return bless {
    file => $params{file},
    ast => $params{testml},

    bridge => $params{bridge},
    stdlib => $params{stdlib},

    vars => {},
    block => undef,
    warned_only => false,
    error => undef,
    thrown => undef,
  }, $class;
}

sub from_file {
  my ($self, $file) = @_;

  $self->{file} = $file;

  open INPUT, $file
    or die "Can't open '$file' for input";

  $self->{ast} = decode_json do { local $/; <INPUT> };

  return $self;
}

sub test {
  my ($self) = @_;

  $self->testml_begin;

  for my $statement (@{$self->{ast}{code}}) {
    $self->exec_expr($statement);
  }

  $self->testml_end;

  return;
}

#------------------------------------------------------------------------------
sub exec {
  my ($self, $expr) = @_;

  $self->exec_expr($expr)->[0];
}

sub exec_expr {
  my ($self, $expr, $context) = @_;

  $context = [] unless defined $context;

  return [$expr] unless $self->type($expr) eq 'expr';

  my @args = @$expr;
  my @ret;
  my $name = shift @args;
  my $opcode = $name;
  if (my $call = $vtable->{$opcode}) {
    $call = $call->[0] if ref($call) eq 'ARRAY';
    @ret = $self->$call(@args);
  }
  else {
    unshift @args, $_ for reverse @$context;

    if (defined(my $value = $self->{vars}{$name})) {
        if (@args) {
          die "Variable '$name' has args but is not a function"
            unless $self->type($value) eq 'func';
          @ret = $self->exec_func($value, \@args);
        }
        else {
          @ret = ($value);
        }
    }
    elsif ($name =~ /^[a-z]/) {
      @ret = $self->call_bridge($name, @args);
    }
    elsif ($name =~ /^[A-Z]/) {
      @ret = $self->call_stdlib($name, @args);
    }
    else {
      die "Can't resolve TestML function '$name'";
    }
  }

  return [@ret];
}

sub exec_func {
  my ($self, $function, $args) = @_;
  $args = [] unless defined $args;

  my ($op, $signature, $statements) = @$function;

  if (@$signature > 1 and @$args == 1 and $self->type($args) eq 'list') {
    $args = $args->[0];
  }

  die "TestML function expected '${\scalar @$signature}' arguments, but was called with '${\scalar @$args}' arguments"
    if @$signature != @$args;

  my $i = 0;
  for my $v (@$signature) {
    $self->{vars}{$v} = $self->exec($args->[$i++]);
  }

  for my $statement (@$statements) {
    $self->exec_expr($statement);
  }

  return;
}

#------------------------------------------------------------------------------
sub call_bridge {
  my ($self, $name, @args) = @_;

  if (not $self->{bridge}) {
    my $bridge_module = $ENV{TESTML_BRIDGE} || 'TestMLBridge';

    if (my $code = $self->{ast}{bridge}{perl5}) {
      eval <<"..." or die $@;
use strict; use warnings;
package TestMLBridge;
use base 'TestML::Bridge';
$code;
1;
...
    }
    else {
      eval "require $bridge_module; 1" or die $@;
    }

    $self->{bridge} = $bridge_module->new;
  }

  (my $call = $name) =~ s/-/_/g;

  die "Can't find bridge function: '$name'"
    unless $self->{bridge} and $self->{bridge}->can($call);

  @args = map {$self->uncook($self->exec($_))} @args;

  my @ret = $self->{bridge}->$call(@args);

  return unless @ret;

  $self->cook($ret[0]);
}

sub call_stdlib {
  my ($self, $name, @args) = @_;

  if (not $self->{stdlib}) {
    require TestML::StdLib;
    $self->{stdlib} = TestML::StdLib->new($self);
  }

  my $call = lc $name;
  die "Unknown TestML Standard Library function: '$name'"
    unless $self->{stdlib}->can($call);

  @args = map {$self->uncook($self->exec($_))} @args;

  $self->cook($self->{stdlib}->$call(@args));
}

#------------------------------------------------------------------------------
sub assert_eq {
  my ($self, $left, $right, $label, $not) = @_;
  my $got = $self->{vars}{Got} = $self->exec($left);
  my $want = $self->{vars}{Want} = $self->exec($right);
  my $method = $self->get_method('assert_%s_eq_%s', $got, $want);
  $self->$method($got, $want, $label, $not);
  return;
}

sub assert_str_eq_str {
  my ($self, $got, $want, $label, $not) = @_;
  $self->testml_eq($got, $want, $self->get_label($label), $not);
}

sub assert_num_eq_num {
  my ($self, $got, $want, $label, $not) = @_;
  $self->testml_eq($got, $want, $self->get_label($label), $not);
}

sub assert_bool_eq_bool {
  my ($self, $got, $want, $label, $not) = @_;
  $self->testml_eq($got, $want, $self->get_label($label), $not);
}


sub assert_has {
  my ($self, $left, $right, $label, $not) = @_;
  my $got = $self->exec($left);
  my $want = $self->exec($right);
  my $method = $self->get_method('assert_%s_has_%s', $got, $want);
  $self->$method($got, $want, $label, $not);
  return;
}

sub assert_str_has_str {
  my ($self, $got, $want, $label, $not) = @_;
  $self->{vars}{Got} = $got;
  $self->{vars}{Want} = $want;
  $self->testml_has($got, $want, $self->get_label($label), $not);
}

sub assert_str_has_list {
  my ($self, $got, $want, $label, $not) = @_;
  for my $str (@{$want->[0]}) {
    $self->assert_str_has_str($got, $str, $label, $not);
  }
}

sub assert_list_has_str {
  my ($self, $got, $want, $label, $not) = @_;
  $self->{vars}{Got} = $got;
  $self->{vars}{Want} = $want;
  $self->testml_list_has($got->[0], $want, $self->get_label($label), $not);
}

sub assert_list_has_list {
  my ($self, $got, $want, $label, $not) = @_;
  for my $str (@{$want->[0]}) {
    $self->assert_list_has_str($got, $str, $label, $not);
  }
}


sub assert_like {
  my ($self, $left, $right, $label, $not) = @_;
  my $got = $self->exec($left);
  my $want = $self->exec($right);
  my $method = $self->get_method('assert_%s_like_%s', $got, $want);
  $self->$method($got, $want, $label, $not);
  return;
}

sub assert_str_like_regex {
  my ($self, $got, $want, $label, $not) = @_;
  $self->{vars}{Got} = $got;
  $self->{vars}{Want} = "/${\ $want->[1]}/";
  $want = $self->uncook($want);
  $self->testml_like($got, $want, $self->get_label($label), $not);
}

sub assert_str_like_list {
  my ($self, $got, $want, $label, $not) = @_;
  for my $regex (@{$want->[0]}) {
    $self->assert_str_like_regex($got, $regex, $label, $not);
  }
}

sub assert_list_like_regex {
  my ($self, $got, $want, $label, $not) = @_;
  for my $str (@{$got->[0]}) {
    $self->assert_str_like_regex($str, $want, $label, $not);
  }
}

sub assert_list_like_list {
  my ($self, $got, $want, $label, $not) = @_;
  for my $str (@{$got->[0]}) {
    for my $regex (@{$want->[0]}) {
      $self->assert_str_like_regex($str, $regex, $label, $not);
    }
  }
}

sub assert_not_eq {
  my ($self, $got, $want, $label) = @_;
  $self->assert_eq($got, $want, $label, true);
}

sub assert_not_has {
  my ($self, $got, $want, $label) = @_;
  $self->assert_has($got, $want, $label, true);
}

sub assert_not_like {
  my ($self, $got, $want, $label) = @_;
  $self->assert_like($got, $want, $label, true);
}

#------------------------------------------------------------------------------
sub exec_dot {
  my ($self, @args) = @_;

  my $context = [];

  delete $self->{error};
  for my $call (@args) {
    if (not $self->{error}) {
      eval {
        if ($self->type($call) eq 'func') {
          $self->exec_func($call, $context->[0]);
          $context = [];
        }
        else {
          $context = $self->exec_expr($call, $context);
        }
      };
      if ($@) {
        if ($ENV{TESTML_DEVEL}) {
            require Carp;
            Carp::cluck($@);
        }
        $self->{error} = $self->call_stdlib('Error', "$@");
      }
      elsif ($self->{thrown}) {
        $self->{error} = $self->cook(delete $self->{thrown});
      }
    }
    else {
      if ($call->[0] eq 'Catch') {
        $context = [delete $self->{error}];
      }
    }
  }

  die "Uncaught Error: ${\ $self->{error}[1]{msg}}"
    if $self->{error};

  return @$context;
}

sub each_exec {
  my ($self, $list, $expr) = @_;
  $list = $self->exec($list);
  $expr = $self->exec($expr);

  for my $item (@{$list->[0]}) {
    $self->{vars}{_} = [$item];
    if ($self->type($expr) eq 'func') {
      if (@{$expr->[1]} == 0) {
        $self->exec_func($expr);
      }
      else {
        $self->exec_func($expr, [$item]);
      }
    }
    else {
      $self->exec_expr($expr);
    }
  }
}

sub each_pick {
  my ($self, $list, $expr) = @_;

  for my $block (@{$self->{ast}{data}}) {
    $self->{block} = $block;

    $self->exec_expr(['<>', $list, $expr]);
  }

  delete $self->{block};

  return;
}

sub pick_exec {
  my ($self, $list, $expr) = @_;

  my $pick = 1;
  if (my $when = $self->{block}{point}{WHEN}) {
    if ($when =~ /^Env:(\w+)$/) {
      $pick = 0 unless $ENV{$1};
    }
  }

  if ($pick) {
    for my $point (@$list) {
      if (
        ($point =~ /^\*/ and
          not exists $self->{block}{point}{substr($point, 1)}) or
        ($point =~ /^!*/) and
          exists $self->{block}{point}{substr($point, 2)}
      ) {
        $pick = 0;
        last;
      }
    }
  }

  if ($pick) {
    if ($self->type($expr) eq 'func') {
      $self->exec_func($expr);
    }
    else {
      $self->exec_expr($expr);
    }
  }

  return;
}

sub call_func {
  my ($self, $func) = @_;
  my $name = $func->[0];
  $func = $self->exec($func);
  die "Tried to call '$name' but is not a function"
    unless defined $func and $self->type($func) eq 'func';
  $self->exec_func($func);
}

sub get_str {
  my ($self, $string) = @_;
  $self->interpolate($string);
}

sub get_hash {
  my ($self, $hash, $key) = @_;
  $hash = $self->exec($hash);
  $key = $self->exec($key);
  $self->cook($hash->[0]{$key});
}

sub get_list {
  my ($self, $list, $index) = @_;
  $list = $self->exec($list);
  return [] if not @{$list->[0]};
  $self->cook($list->[0][$index]);
}

sub get_point {
  my ($self, $name) = @_;
  $self->getp($name);
}

sub set_var {
  my ($self, $name, $expr) = @_;

  $self->setv($name, $self->exec($expr));

  return;
}

sub or_set_var {
  my ($self, $name, $expr) = @_;
  return if defined $self->{vars}{$name};

  if ($self->type($expr) eq 'func') {
    $self->setv($name, $expr);
  }
  else {
    $self->setv($name, $self->exec($expr));
  }
  return;
}

#------------------------------------------------------------------------------
sub getp {
  my ($self, $name) = @_;
  return unless $self->{block};
  my $value = $self->{block}{point}{$name};
  $self->exec($value) if defined $value;
}

sub getv {
  my ($self, $name) = @_;
  $self->{vars}{$name};
}

sub setv {
  my ($self, $name, $value) = @_;
  $self->{vars}{$name} = $value;
  return;
}

#------------------------------------------------------------------------------
sub type {
  my ($self, $value) = @_;

  return 'null' if not defined $value;

  if (not ref $value) {
    return 'num' if Scalar::Util::looks_like_number($value);
    return 'str';
  }
  return 'bool' if isBoolean($value);
  if (ref($value) eq 'ARRAY') {
    return 'none' if @$value == 0;
    return $_ if $_ = $types->{$value->[0]};
    return 'list' if ref($value->[0]) eq 'ARRAY';
    return 'hash' if ref($value->[0]) eq 'HASH';
    return 'expr';
  }

  require XXX;
  XXX::ZZZ("Can't determine type of this value:", $value);
}

sub cook {
  my ($self, @value) = @_;

  return [] if not @value;
  my $value = $value[0];
  return undef if not defined $value;

  return $value if not ref $value;
  return [$value] if ref($value) =~ /^(?:HASH|ARRAY)$/;
  return $value if isBoolean($value);
  return ['/', $value] if ref($value) eq 'Regexp';
  return ['!', $value] if ref($value) eq 'TestMLError';
  return $value->{func} if ref($value) eq 'TestMLFunction';
  return ['?', $value];
}

sub uncook {
  my ($self, $value) = @_;

  my $type = $self->type($value);

  return $value if $type =~ /^(?:str|num|bool|null)$/;
  return $value->[0] if $type =~ /^(?:list|hash)$/;
  return $value->[1] if $type =~ /^(?:error|native)$/;
  return TestMLFunction->new($value) if $type eq 'func';
  if ($type eq 'regex') {
    return ref($value->[1]) eq 'Regexp'
    ? $value->[1]
    : qr/${\ $value->[1]}/;
  }
  return () if $type eq 'none';

  require XXX;
  XXX::ZZZ("Can't uncook this value of type '$type':", $value);
}

#------------------------------------------------------------------------------
sub get_method {
  my ($self, $pattern, @args) = @_;

  my $method = sprintf $pattern, map $self->type($_), @args;

  die "Method '$method' does not exist" unless $self->can($method);

  return $method;
}

sub get_label {
  my ($self, $label_expr) = @_;
  $label_expr = '' unless defined $label_expr;

  my $label = $self->exec($label_expr);

  $label ||= $self->getv('Label') || '';

  my $block_label = $self->{block} ? $self->{block}{label} : '';

  if ($label) {
    $label =~ s/^\+/$block_label/;
    $label =~ s/\+$/$block_label/;
    $label =~ s/\{\+\}/$block_label/;
  }
  else {
    $label = $block_label;
    $label = '' unless defined $label;
  }

  return $self->interpolate($label, true);
}

sub interpolate {
  my ($self, $string, $label) = @_;
  # XXX Hack to see input file in label:
  $self->{vars}{File} = $ENV{TESTML_FILEVAR};

  $string =~ s/\{([\-\w]+)\}/$self->transform1($1, $label)/ge;
  $string =~ s/\{\*([\-\w]+)\}/$self->transform2($1, $label)/ge;

  return $string;
}

sub transform {
  my ($self, $value, $label) = @_;
  my $type = $self->type($value);
  if ($label) {
    if ($type =~ /^(?:list|hash)$/) {
      return encode_json($value->[0]);
    }
    if ($type eq 'regex') {
      return "$value->[1]";
    }
    $value =~ s/\n/â¤/g;
    return "$value";
  }
  else {
    if ($type =~ /^(?:list|hash)$/) {
      return encode_json($value->[0]);
    }
    else {
      return "$value";
    }
  }
}

sub transform1 {
  my ($self, $name, $label) = @_;
  my $value = $self->{vars}{$name};
  return '' unless defined $value;
  $self->transform($value, $label);
}

sub transform2 {
  my ($self, $name, $label) = @_;
  return '' unless $self->{block};
  my $value = $self->{block}{point}{$name};
  return '' unless defined $value;
  $self->transform($value, $label);
}

1;
