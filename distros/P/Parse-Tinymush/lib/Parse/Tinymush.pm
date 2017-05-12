package Parse::Tinymush;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.01';

use constant FN_VARARG => -1;

use constant CODE_REF => 0;
use constant ARG_COUNT => 1;
use constant FNC_FLAGS => 2;

use constant FNC_NO_FLAGS => 0;
use constant FNC_PASS_NAME => 1;

my $options = {
  debug => 0,
  space_compresion => 1,
};

sub new {
  my ($class, %args) = @_;

  my $self = {
    brace_depth => 0,
    func_depth => 0,
    functions => $args{functions} || {},
    options => $options,
    output => '',
    string => '',
    temp => '',
    variables => $args{variables} || {},
  };

  if ( exists $args{options} ) {
    foreach my $key ( keys %{ $args{options} } ) {
      return if !exists $self->{options}->{$key};
      $self->{options}->{$key} = $args{options}->{$key};
    }
  }

  bless $self, $class;
}

sub pop {
  my ($self, $count) = @_;
  $count = 1 if !defined $count;
  $count = length($self->{string}) if $count > length($self->{string});

  my $popped = substr($self->{string}, 0, $count);
  substr($self->{string}, 0, $count) = '';

  return $popped;
}

sub peek {
  my ($self, $count) = @_;
  $count = 1 if !defined $count;
  $count = length($self->{string}) if $count > length($self->{string});

  my $peeked = substr($self->{string}, 0, $count);

  return $peeked;
}

sub push {
  my ($self, $string) = @_;

  $self->{string} = $string . $self->{string};
}

sub temp : lvalue {
  shift->{temp};
}

sub flush {
  my ($self, $var) = @_;

  if ( $self->{options}->{debug} ) {
    print STDERR "Flushing: $self->{temp}\n";
  }

  if ( $var ) {
    $$var .= $self->{temp};
  } else {
    $self->{output} .= $self->{temp};
  }
  $self->{temp} = '';
}

sub output : lvalue {
  shift->{output};
}

sub eval {
  my ($self, $string) = @_;

  $self->parse($string);
}

sub parse {
  my ($self, $string) = @_;
  return "" if !defined($string) || length($string) == 0;
  $self->output = '';
  $self->temp = '';
  $self->{func_depth} = 0;
  $self->{brace_depth} = 0;
  $self->{string} = $string;

  my $current = '';
  my $previous = '';

  OUTER: while (1) {
    $current = $self->pop;
    last if (!defined $current || length($current) == 0);

    SWITCH: {
      if ( defined(my $parse = $self->parse_character($current, $previous)) ) {
        $self->temp .= $parse;
        if ( $parse =~ /\s/o ) {
          $self->flush;
        }
        last SWITCH;
      }

      if ( $current eq '[' ) {
        $self->flush;
        $self->temp .= $self->parse_function;
        if ( $self->peek eq ']' ) {
          $self->pop;
        }
        last SWITCH;
      }

      if ( $current eq '(' && $self->output eq '' ) {
        $self->push($self->temp . '(');
        $self->temp = '';
        $self->temp = $self->parse_function;
        $self->flush;
        last SWITCH;
      }

      $self->temp .= $current;
    }

    $previous = $current;
  }
  $self->flush;

  return $self->output;
}

sub parse_variable {
  my ($self, $char) = @_;

  if ( defined(my $variable = $self->{variables}->{$char}) ) {
    if ( ref($variable) eq 'CODE' ) {
      return $variable->($char, $self);
    } elsif ( ref($variable) eq 'ARRAY' ) {
      return $variable->[$char];
    } elsif ( ref($variable) eq 'HASH' ) {
      return $variable->{$char};
    } elsif ( ref($variable) eq 'SCALAR' ) {
      return $$variable;
    } elsif ( ref($variable) && UNIVERSAL::can($variable, "eval") ) {
      return $variable->eval($char, $self);
    } else {
      return $variable;
    }
  }

  return $char;
}

sub parse_character {
  my ($self, $char, $prev) = @_;

  if ( $self->{options}->{space_compression}
  &&   ($prev =~ /\s/o
  ||    ($self->{func_depth} && $prev eq ',')) ) {
    return '' if ( $char =~ /\s/o );
  }

  if ( $prev eq '\\' ) {
# The previous character was a literal \, so we take the current character
# with no parsing.
    return $char;
  }

  if ( $prev eq '%' ) {
    return $self->parse_variable($char);
  }

  if ( $self->{brace_depth} && $char eq '}' ) {
    $self->{brace_depth}--;
    return '';
  }

  if ( $self->{brace_depth} || $char =~ /\s/o ) {
    return $char;
  }

  if ( $char eq '{' ) {
    $self->{brace_depth}++;
    return '';
  }

  if ( $char eq '%' ) {
    return '';
  }

  if ( $char eq '\\' ) {
    return '';
  }

  return;
}

sub parse_function {
  my ($self) = @_;

  my $current = "";
  my $previous = "";
  my @funcargs = ( );
  my $argc = 0;
  my $output = undef;

  $self->{func_depth}++;
  if ( $self->{options}->{debug} ) {
    print STDERR "Function call: depth: $self->{func_depth}\n";
    print STDERR "Function call: stack: $self->{string}\n";
  }

  OUTER: while ( 1 ) {
# Get the next character from the workspace and study it for regex
# testing.
    $current = $self->pop;
    last if (!defined $current || length($current) == 0);
    study $current;

    $output = \$funcargs[$argc];
    $$output = '' if ( !defined $$output );
    SWITCH: {
      if ( defined(my $parse = $self->parse_character($current, $previous)) ) {
        $self->temp .= $parse;
        last SWITCH;
      }

      if ( $current eq '(' ) {
# If we're currently changing the function name ($argc == 0), then this
# marks the end of the name and the beginning of the function arguments.
# So, we simply set $argc = 0 and move on.
        if ( $argc == 0 ) {
          $self->flush($output);
          $argc++;
          last SWITCH;
        }

# ( marks a function call.  We check to see if OUTPUT is empty.  If it is,
# then this is the first word of the statement and is passed as a function
# call.  If it isn't, then we just print a ( and move on.
        if ( $$output ne "" ) {
          $self->temp .= $current;
        } else {
          $self->push($self->temp . "(");
          $self->temp = '';
          $$output .= $self->parse_function;
        }
        last SWITCH;
      }

      if ( $current eq ',' ) {
        if ( $argc == 0 ) {
          $self->temp .= $current;
          last SWITCH;
        }

        $self->flush($output);
        $argc++;
        last SWITCH;
      }

      if ( $current eq ')' || $current eq ']' ) {
# Things get sexy here.  ) marks the end of the function call.  But ] does
# as well.  So, how do we handle )] or )blah]?  Easy!
# First, send output to OUTPUT.  This will REALLY hose your stack if you
# do )blah].  I want that (consider it a feature).
        $self->flush($output);
        last OUTER;
      }

      if ( $current eq '[' ) {
        $self->flush;
        $self->temp .= $self->parse_function;
        if ( $self->peek eq ']' ) {
          $self->pop;
        }
        last SWITCH;
      }

# Default case
      $self->temp .= $current;
    }

    $previous = $current;
  }

  if ( $self->{options}->{debug} ) {
    print STDERR "Function return: depth: $self->{func_depth}\n";
  }

  $self->{func_depth}--;

  my $func_info;
  my $func_name = lc shift @funcargs;
  if ( !defined($func_info = $self->{functions}->{$func_name}) ) {
    return "#-1 FUNCTION (\U$func_name\E) NOT FOUND";
  }

# Clean out empty arguments
  while ( $argc && $funcargs[$argc - 1] eq '' ) {
    CORE::pop @funcargs;
    $argc--;
  }

  my $min_arg = FN_VARARG;
  my $max_arg = FN_VARARG;
  if ( ref($func_info->[ARG_COUNT]) eq 'ARRAY' ) {
    ($min_arg, $max_arg) = @{ $func_info->[ARG_COUNT] };
  } else {
    $min_arg = $max_arg = $func_info->[ARG_COUNT];
  }

  if ( $func_info->[ARG_COUNT] != FN_VARARG
  &&   ($min_arg > $argc || $max_arg < $argc) ) {
    my $error = "#-1 FUNCTION (\U$func_name\E) EXPECTS ";
    if ( $min_arg == $max_arg ) {
      $error .= "$min_arg ARGUMENT" . ($min_arg == 1 ? "" : "S");
    } else {
      $error .= "BETWEEN $min_arg AND $max_arg ARGUMENTS";
    }
    $error .= ", GOT $argc";

    return $error;
  }

  my $flags = $func_info->[FNC_FLAGS] || 0;
  if ( $flags & FNC_PASS_NAME ) {
    unshift @funcargs, $func_name;
  }
  my $retval = $func_info->[CODE_REF]->(@funcargs);
  if ( $self->{options}->{debug} ) {
    print STDERR "Function return: value: $retval\n";
  }

  return $retval;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Parse::Tinymush - A simple tinymush parser

=head1 SYNOPSIS

  use Parse::Tinymush;
  my $functions = {
    cat => [sub { "@_" }, -1],
    add => [sub { $_[0] + $_[1] }, 2],
  };
  my $parser = Parse::Tinymush->new(functions => $functions);
  print $parser->parse("add(1,2)");

=head1 DESCRIPTION

The Parse::Tinymush module is an implemenation of the tinymush parser 
written in perl.  This implementation comes with no built-in %-variables 
or functions, but they can be easily added by passing arguments to the 
constructor.

=head2 new(OPTIONS)

C<new> is the constructor.  It sets up various instance variables.  The 
constructor takes a number of optional arguments:

=over 4

=item functions

This must be a reference to a hash with the form:

  { function_name => [code_ref, argument_count, flags] }

C<function_name> must be lowercase for the parser to work correctly.  
C<argument_count> can be one of the following:

* -1, which means any number of arguments

* A number, which means that exact number of arguments

* An array ref, whose first entry is the minimum number of arguments 
and second entry is the maximum number of arguments.

The C<flags> field is optional.  The possible values for it are:

* FNC_NO_FLAGS (0) - Same as not having any flags

* FNC_PASS_NAME (1) - Pass the function name as the first argument to the 
function.  This allows the same code to have different function names.  
This is useful if you wish two functions to have similar features, but do 
not want to repeat code.

Example:

  my $functions = {
    "add" => [ \&fnc_add, 2, ],
    "cat" => [ \&fnc_cat, -1, FNC_NO_FLAGS ],
    "lcon" => [ \&fnc_lcon, [1, 2], FNC_PASS_NAME ],
  };

=item variables

The C<variables> hash is used to handle evaluation of the %-variables.  It 
must be a reference to a hash with the form:

  { var_name => var_eval }

C<var_name> is case-sensitive.  For both "C" and "c" to mean the same 
thing, they must both be in the table.  C<var_eval> can be one of the 
following:

* A simple scalar

* An array ref, in which case the current character is used as the index

* A hash ref, in which case the current character is used as the key

* A code ref, in which case the code is called, passing it the current 
character and the Parse::Tinymush object as $_[0] and $_[1]

* An object with an C<eval> method, in which case the method is called and 
passed the current character and the Parse::Tinymush object

Example:

  my @array = ( 0 .. 9 );
  my %hash = ( y => "z" );

  my $variables = {
    "!" => $$,
    "0" => \@array,
    "y" => \%hash,
    "l" => sub { getcwd; ),
    "o" => HTML::Parser->new(),
  };

=item options

C<options> is a hash reference of various parser options.  Currently, the 
only supported option is C<space_compression>.

* C<space_compression> - default: on - When on, multiple spaces will be 
compressed into one space.

Example:

my $parser = Parse::Tinymush->new(options => {space_compression => 0});

=back 4

=head2 parse(STRING)

C<parse> parses the given string, returning a string as the result.

Example:

my $output = $parser->parse("cat(1,2,3,4,5)");

# $output = 12345

=head2 EXPORT

None

=head1 SEE ALSO

The tinymush project: E<lt>http://www.godlike.com/tm3/E<gt>

=head1 AUTHOR

Eric Kidder, E<lt>kageneko.at.evilkitten.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Eric Kidder

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
