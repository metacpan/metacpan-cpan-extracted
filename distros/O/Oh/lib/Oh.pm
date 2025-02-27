use strict;
use warnings;

package Oh;

our $VERSION = 0.06;

use subs qw/error env listp evaluate_element evaluate_list evaluate_function evaluate_builtin evaluate_macro evaluate_lambda find search progn read_element read_string read_list reft/;

use Term::ANSIColor 'colored';
use Scalar::Util qw/reftype blessed/;
use List::Util;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

my $env = env;

my $root = $env;

my $source;

my $out = *STDOUT;

my %operator = (progn => \&progn,
                quote => sub { shift },
                setq => \&setq,
                unquote => \&evaluate_element, 
                quasiquote => \&quasiquote);

my %read = ('"' => \&read_string,
            '(' => \&read_list,
            ';' => sub { $source->getline; 'nop' },
            ')' => sub { ')' },
            '@' => sub { ['flatten', read_element] },
            "'" => sub { ['quote', read_element] },
            '`' => sub { ['quasiquote', read_element] },
            ',' => sub { ['unquote', read_element] });


sub pr { print $out @_ }
sub read_list
{
  my @list;
  while ((my $element = read_element) ne ')')
  {
    error '( without a terminating )' if $element eq '';
    push @list, $element;
  }
  \@list;
}

sub read_string
{
  my $string = '';
  my $char = $source->getc;
  error '" at the end of source code' unless defined $char;

  while ($char ne '"')
  {
    if ($char eq '\\')
    {
      $char = $source->getc;
      error '\\ escape sequence at the end of "' unless defined $char;
      if ($char eq 'a')
      {
        $string .= "\a";
      }
      elsif ($char eq 't')
      {
        $string .= "\t";
      }
      elsif ($char eq 'e')
      {
        $string .= "\e";
      }
      elsif ($char eq 'r')
      {
        $string .= "\r";
      }
      elsif ($char eq '0')
      {
        $string .= "\0";
      }
      elsif ($char eq 'n')
      {
        $string .= "\n";
      }
      else
      {
        $string .= $char;
      }
    }
    else
    {
      $string .= $char;
    }

    $char = $source->getc;
    error '" did not find a terminating "' unless defined $char;
  }
  bless \$string, 'string';
}
  
  
  
  
  
  
  
  


sub error { die "@_\n" }

sub env
{
  { parent => shift(), map { $_ => {} } qw/function symbol macro/ };
}

sub listp ($) { $_[0] eq 'ARRAY' }

sub find
{
  my ($type, $name) = @_;
  
  if (exists $env->{$type}->{$name})
  {
    $env->{$type}->{$name};
  }
  elsif ($env->{parent})
  {
    my $e = $env;
    while ($e = $e->{parent})
    {
      if (exists $e->{$type}->{$name})
      {
        return $e->{$type}->{$name};
      }
    }
  }
}

sub search
{
  my ($type, $name) = @_;
  
  if (exists $env->{$type}->{$name})
  {
    $env;
  }
  elsif ($env->{parent})
  {
    my $e = $env;
    while ($e = $e->{parent})
    {
      if (exists $e->{$type}->{$name})
      {
        return $e;
      }
    }
  }
}
#els
sub evaluate_element
{
  my $element = shift;

  return undef unless defined $element;

  my $type = ref $element;

  if ($type)
  {
    if (listp $type)
    {
      evaluate_list $element;
    }
    else
    {
      $element;
    }
  }
  else
  {
    if ($element =~ /^-?\d+\.?\d*$/ or $element =~ /^:/)
    {
      $element;
    }
    else
    {
      my $symbol = search 'symbol', $element;

      if ($symbol)
      {
        $symbol->{symbol}->{$element};
      }
      else
      {
        if ($element eq 'root')
        {
          $root;
        }
        elsif ($element eq 'nop')
        {

        }
        else
        {
          error 'unbound symbol', $element;
        }
      }
    }
  }
}

#lss
sub evaluate_list
{
  my @list = @{shift()};

  return undef unless @list;

  my $car = shift @list;

  error 'evaluating list with nil car' unless defined $car;

  my $type = ref $car;

  if ($type)
  {
    if (listp $type)
    {
      evaluate_list [evaluate_list($car), @list];
    }
    elsif ($type eq 'macro')
    {
      evaluate_macro $car, @list;
    }
    elsif ($type eq 'CODE')
    {
      evaluate_builtin $car, @list;
    }
    elsif ($type eq 'lambda')
    {
      evaluate_lambda $car, @list;
    }
    else
    {
      error 'evaluating list with unknown car', $type, $car;
    }
  }
  else
  {
    if ($operator{$car})
    {
      $operator{$car}->(@list);
    }
    else
    {
      my $macro = find 'macro', $car;

      if ($macro)
      {
        evaluate_macro $macro, @list;
      }
      else
      {
        my $function = find 'function', $car;

        if ($function)
        {
          evaluate_function($function, @list);
        }
        else
        {
          if ($car =~ /::/)
          {
            evaluate_function(get_sub($car), @list);
          }
          else
          {
            my $obj = find 'symbol', $car;
            if (blessed $obj)
            {
              my $method = shift;
              $obj->$method(@_);
            }
            else
            {
              error $car, 'is not an operator, macro or function', @list;
            }
          }
        }
      }
    }
  }
}

sub with_env (&$)
{
  my ($code, $e) = @_;

  my $old = $env;

  $env = $e;

  my $result = $code->();
  
  $env = $old;

  $result;
}

sub progn
{
  if (@_)
  {
    my $last = pop;
    for my $element (@_)
    {
      evaluate_element $element;
    }
    evaluate_element $last;
  }
  else
  {
    undef;
  }
}

sub evaluate_lambda
{
  my $lambda = shift;

  $lambda->{env}->{symbol}->{args} = [@_];

  with_env { progn @{$lambda->{code}} } $lambda->{env};
}

sub convert_values
{
  map
  {
    if (defined)
    {
      my $type = ref;
      if ($type)
      {
        if ($type eq 'string')
        {
          $$_;
        }
        else
        {
          $_;
        }
      }
      else
      {
        if (/^:/)
        {
          substr $_, 1;
        }
        else
        {
          $_;
        }
      }
    }
    else
    {
      undef;
    }
  } @_;
}

sub evaluate_builtin
{
  my $builtin = shift;
  
  $builtin->(convert_values @_);
}

sub evaluate_function
{
  my $fun = shift;
  
  my $type = ref $fun;

  @_ = map { evaluate_element($_) } @_ if @_;

  if ($type eq 'lambda')
  {
    evaluate_lambda $fun, @_;
  }
  elsif ($type eq 'CODE')
  {
    evaluate_builtin $fun, @_;
  }
  else
  {
    error 'wrong function to evaluate', $type, $fun;
  }
}

sub evaluate_macro
{
  my $macro = shift;
  
  my $type = ref $macro;

  if ($type eq 'macro')
  {
    evaluate_element evaluate_lambda $macro, @_;
  }
  elsif ($type eq 'CODE')
  {
    evaluate_element evaluate_builtin $macro, @_;
  }
  else
  {
    error 'wrong macro to evaluate', $type, $macro;
  }
}


sub quasiquote
{
  my $element = shift;
  if (listp ref $element)
  {
    if ($element->[0] and $element->[0] eq 'unquote')
    {
      evaluate_element $element->[1];
    }
    else
    {
      [map { quasiquote($_) } @$element];
    }
  }
  else
  {
    $element;
  }
}

sub read_element
{
  my $char = $source->getc;

  my $atom = '';

  while (defined $char and $char =~ /\s/s)
  {
    $char = $source->getc;
  }
  while (defined $char and $char !~ /\s/s)
  {
    if ($read{$char})
    {
      if ($atom eq '')
      {
        return $read{$char}->();
      }
      else
      {
        $source->ungetc(ord $char);
        return $atom;
      }
    }
    $atom .= $char;
    $char = $source->getc;
  }
  $atom;
}

sub repl
{
  my $line;
  print colored('> ', 'green bold');
  while (defined($line = <STDIN>) and $line ne "\n")
  {
    open my $str, '<', \$line;
    my $old = $source;
    $source = $str;
    while ((my $element = read_element) ne '')
    {
      eval { print dumper(evaluate_element $element), "\n" }; 
      print "$@\n" if $@;
      print colored('> ', 'green bold');
    }
    $source = $old;
  }
}

sub fun (&$)
{
  $env->{function}->{$_[1]} = $_[0];
}

sub op (&$)
{
  $operator{$_[1]} = $_[0];
}

sub set
{
  my $type = reft $_[0];
  if ($type)
  {
    if (listp $type)
    {
      my ($element, $index, $value) = @_;
      $element->[$index] = $value;
    }
    elsif ($type eq 'HASH')
    {
      my ($element, $key, $value) = @_;
      $element->{$key} = $value;
    }
    else
    {
      error 'cannot set type', $type, $_[0];
    }
  }
  else
  {
    my ($element, $value) = @_;
    (search 'symbol', $element or $env)->{symbol}->{$element} = $value;
  }
}

sub setq
{
  my ($element, $value) = @_;
  (search 'symbol', $element or $env)->{symbol}->{$element} = $value;
}

sub scheme_args
{
  my $arguments = shift;
  if (listp ref $arguments)
  {
    @_ = @$arguments;
    if (@_)
    {
      my @args = @{$env->{symbol}->{args}};
      while (@_)
      {
        my $arg = shift;
        if ($arg eq '.')
        {
          my $name = shift;
          $env->{symbol}->{$name} = \@args;
          last;
        }
        else
        {
          $env->{symbol}->{$arg} = shift @args;
        }
      }
    }
  }
  elsif ($arguments)
  {
    $env->{symbol}->{$arguments} = [@{$env->{symbol}->{args}}];
  }
}

sub interpret_file
{
  my $file = shift;
  open my $fh, '<', $file or error 'cannot load file', $file;
  my $char = $fh->getc;
  if ($char eq '#')
  {
    $fh->getline;
  }
  else
  {
    $fh->ungetc(ord $char);
  }
  my $old = $source;
  $source = $fh;
  my $result;
  while ((my $word = read_element) ne '')
  {
    $result = evaluate_element($word);
  }
  $source = $old;
  $result;
} 

sub interpret_string
{
  my $string = shift;
  open my $fh, '<', \$string or error 'cannot read string', $string;
  my $old = $source;
  $source = $fh;
  my $result;
  while ((my $word = read_element) ne '')
  {
    $result = evaluate_element($word);
  }
  $source = $old;
  $result;
} 

sub reft ($) { reftype($_[0]) or '' }
sub get
{
  my ($element, $key) = @_;
  my $type = reft $element;
  if ($type eq 'HASH')
  {
    $element->{$key};
  }
  elsif ($type eq 'ARRAY')
  {
    $element->[$key];
  }
}

sub get_sub
{
  no strict 'refs';
  \&{shift()};
}


sub oh { print "oh...@_\n" }

sub process_args
{
  my @args;
  if (@ARGV)
  {
    my $flag;
    my @commands = grep
    {
      if ($flag)
      {
        push @args, $_;
      }
      else
      {
        if ($_ eq '-')
        {
          $flag = 1;
        }
      }
      not $flag;
    } @ARGV;

    $env->{symbol}->{arguments} = \@args;
    if (@commands)
    {
      while (@commands)
      {
        my $command = shift @commands;
        if ($command eq 'e')
        {
          interpret_string shift @commands;
        }
        elsif ($command eq 'f')
        {
          interpret_file shift @commands;
        }
        elsif ($command eq 'v')
        {
          print "oh $VERSION\n";
        }
        elsif ($command eq 'i')
        {
          repl;
        }
        elsif (-e $command)
        {
          interpret_file $command;
        }
        else
        {
          error 'command not recognized', $command;
        }
      }
    }
    else
    {
      repl;
    }
  }
  else
  {
    repl;
  }
}

sub lisp_args
{
  my $state = 0;
  my $rest;
  my @optionals;
  my %keywords;
  my @required;
  my @arguments = @{$env->{symbol}->{args}};

  @_ = @{shift()};
  while (@_)
  {
    my $arg = shift;
    if ($arg eq '&optional')
    {
      $state = 'optional';
    }
    elsif ($arg eq '&key')
    {
      $state = 'keyword';
    }
    elsif ($arg eq '&rest')
    {
      $rest = shift;
      last
    }
    elsif ($state eq 'keyword')
    {
      if (listp ref $arg)
      {
        $keywords{$arg->[0]} = $arg->[1];
      }
      else
      {
        $keywords{$arg} = undef;
      }
    }
    elsif ($state eq 'optional')
    {
      push @optionals, $arg;
    }
    else
    {
      push @required, $arg;
    }
  }

  while (@arguments)
  {
    my $arg = shift @arguments;

    my $keyword_name = substr $arg, 1 if defined $arg;

    if (@required)
    {
      $env->{symbol}->{shift(@required)} = $arg;
    }
    elsif (@optionals)
    {
      $env->{symbol}->{shift(@optionals)} = $arg;
    }
    elsif (defined $arg and $arg =~ /^:/ and exists $keywords{$keyword_name})
    {
      $env->{symbol}->{$keyword_name} = shift @arguments;
      delete $keywords{$keyword_name};
    }
    elsif ($rest)
    {
      $env->{symbol}->{$rest} = [$arg, @arguments];
      last;
    }
    else
    {
      error 'extra argument not being bound', $arg;
    }
  }

  error 'required arguments not supplied', @required if @required;

  for my $optional (@optionals)
  {
    if (listp ref $optional)
    {
      $env->{symbol}->{$optional->[0]} = evaluate_element $optional->[1];
    }
    else
    {
      $env->{symbol}->{$optional} = undef;
    }
  }

  for my $keyword (keys %keywords)
  {
    $env->{symbol}->{$keyword} = evaluate_element $keywords{$keyword};
  }
}

sub dumper
{
  join(' ', map { if (ref eq 'lambda' or ref eq 'macro') { '#lambda' } else { Dumper $_ } } @_);
}


#sbs



#ops

&op(\&lisp_args, 'lisp-args');
&op(\&scheme_args, 'scheme-args');
op
{
  my $name = shift;
  my @code = @_;
  $env->{function}->{$name} = bless { code => \@code, env => env($env) }, 'lambda';
} 'sub';

op
{
  my @code = @_;
  bless { code => \@code, env => env($env) }, 'lambda';
} 'anon';

op
{
  my ($name, $args, @code) = @_;
  $env->{macro}->{$name} = bless { code => [['scheme-args', $args], @code], env => env($env) }, 'macro';
} 'macro';

op
{
  my ($name, $args, @code) = @_;
  $env->{macro}->{$name} = bless { code => [['lisp-args', $args], @code], env => env($env) }, 'macro';
} 'defmacro';

op
{
  my $e = env $env;
  my $old = $env;
  $env = $e;
  my @args = @{shift()};
  if (@args)
  {
    while (@args)
    {
      my ($name, $value) = splice @args, 0, 2;
      $env->{symbol}->{$name} = evaluate_element $value;
    }
  }
  my $result = progn(@_);
  $env = $old;
  $result;
} 'let';

op { @{evaluate_element $_[0]} } 'flatten';

op { @_ } 'qw';
op { scalar evaluate_element shift } 'scalar';
op { @{$_[0]} } 'deref';
op { eval "use @_"; $@ if $@ } 'use';

op
{
  my $name = shift;
  no strict 'refs';
  push @{$name . '::ISA'}, @_;
} 'parent';

op
{
  my ($module, $name, @code) = @_;
  no strict 'refs';
  my $lambda = bless { code => \@code, env => env($env) }, 'lambda';
  *{$module . '::' . $name} = sub { evaluate_lambda $lambda, @_ };
} 'perl-sub';

op
{
  my ($value, $true, $false) = @_;
  if (evaluate_element $value)
  {
    evaluate_element $true;
  }
  else
  {
    evaluate_element $false;
  }
} 'if';

op
{
  if (not evaluate_element shift)
  {
    progn @_;
  }
  else
  {
    undef;
  }
} 'unless';

op
{
  if (evaluate_element shift)
  {
    progn @_;
  }
  else
  {
    undef;
  }
} 'when';

op
{
  my $result;
  while (@_)
  {
    $result = evaluate_element shift;
    last if $result;
  }
  $result;
} 'or';

op
{
  my $str = '';
  open my $fh, '>', \$str;
  my $old = $out;
  $out = $fh;
  progn @_;
  $out = $old;
  $str;
} 'buffer';

op
{
  my ($code, $catch) = @_;
  eval { evaluate_element $code };
  evaluate_element $catch if $@;
} 'try';

op
{
  error 'hash did not receive a number of arguments multiple of two' if @_ % 2;
  my %hash;
  while (@_)
  {
    my ($key, $value) = splice @_, 0, 2;
    $hash{$key} = evaluate_element $value;
  }
  \%hash;
} 'hash';
    
fun { listp ref $_[0] } 'listp';
fun { my ($obj, $method, @args) = @_; $obj->$method(@args) } 'method';

op
{
  $env->{symbol}->{$_[0]} = evaluate_element $_[1];
} 'setq-current-env';




#funs

&fun(\&List::Util::sum0, '+');
&fun(\&evaluate_function, 'funcall');
&fun(\&set, 'set');
&fun(\&get, 'get');
&fun(\&interpret_file, 'load');
&fun(\&interpret_string, 'eval-string');

fun { $@ } 'get-error';
fun { die "@_\n" } 'error';
fun { pr(dumper(@_),"\n") } 'dump';

fun
{
  my ($str, $limit) = @_;
  if (defined $str)
  {
    if (length($str) > $limit)
    {
      substr $str, 0, $limit;
    }
    else
    {
      $str;
    }
  }
} 'cut-string';
fun
{
  my ($regex, $string) = @_;
  my @values = $string =~ /$regex/;
  error $@ if $@;
  @values;
} 'match';

fun 
{
  my ($regex, $string) = @_;
  $string =~ s/$regex//;
  $string;
} 'remove-match';

fun 
{
  my ($regex, $string) = @_;
  $string =~ s/$regex//g;
  $string;
} 'remove-matches';

fun 
{
  my ($regex, $subs, $string) = @_;
  $string =~ s/$regex/$subs/;
  $string;
} 'substitute-match';

fun 
{
  my ($regex, $subs, $string) = @_;
  $string =~ s/$regex/$subs/g;
  $string;
} 'substitute-matches';

fun
{
  error 'make-hash did not receive a number of arguments multiple of two' if @_ % 2;
  +{ @_ }; 
} 'make-hash';
fun { $_[0] eq $_[1] } 'eq';
fun { progn(@_) } 'eval';
fun { \@_ } 'list';
fun { pr(@_) } 'pr';
fun { pr("@_\n") } 'print';
fun { $_[0]->[0] } 'car';
fun
{
  my @list = @{$_[0]};
  shift @list;
  \@list;
} 'cdr';

fun
{
  my $package = shift;
  for my $name (@_)
  {
    if (listp ref $name)
    {
      print "binding $name\n";
      my ($lisp_name, $perl_name) = @$name;
      &fun(get_sub($package . '::' . $perl_name), $lisp_name);
    }
    else
    {
      print "binding $name\n";
      &fun(get_sub($package . '::' . $name), $name);
    }
  }
} 'bindings';

interpret_string <<'oh';
(macro fun (name args . code)
 `(sub ,name (scheme-args ,args) ,@code))

(macro defun (name args . code)
 `(sub ,name (lisp-args ,args) ,@code))

(macro lambda (args . code)
 `(anon (lisp-args ,args) ,@code))

(macro perl-fun (module name args . code)
 `(perl-sub ,module ,name (scheme-args ,args) ,@code))

(macro perl-defun (module name args . code)
 `(perl-sub ,module ,name (lisp-args ,args) ,@code))

(macro define (name . value)
  (if (listp name)
   `(fun ,(car name) ,(cdr name) ,@value)
   `(setq-current-env ,name ,(car value))))

oh

  



1;
