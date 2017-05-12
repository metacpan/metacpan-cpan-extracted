package Sub::Args;
use strict;
use warnings;
use 5.008001;
use Exporter 'import';
our @EXPORT = qw( args args_pos );
use Carp ();

our $VERSION = '0.08';

sub args {
    my $rule = shift;
    
    if (ref $rule ne 'HASH') {
        Carp::croak "args method require hashref's rule.";
    }
    
    my $invocant = caller(0);

    my $caller_args = ref($_[0]) eq 'HASH' ? $_[0] : {@_};
    unless (keys %$caller_args) {
        package DB;
        () = caller(1);

        shift @DB::args if $invocant eq (ref($DB::args[0])||$DB::args[0]);

        if (ref($DB::args[0]) eq 'HASH') {
            $caller_args = $DB::args[0];
        } else {
            if (scalar(@DB::args) % 2 == 1 ) {
                Carp::confess "arguments not allow excluding hash or hashref";
            }
            $caller_args = {@DB::args};
        }
    }

    map {($rule->{$_} && not defined $caller_args->{$_}) ? Carp::confess "Mandatory parameter '$_' missing.": () } keys %$rule;

    map {(not defined $rule->{$_}) ? Carp::confess "not listed in the following parameter: $_.": () } keys %$caller_args;

    map {$caller_args->{$_} = undef unless exists $caller_args->{$_}} keys %$rule;

    Internals::SvREADONLY %$caller_args, 1;
    $caller_args;
}

sub args_pos {
    my $invocant = caller(0);
    {
        package DB;
        () = caller(1);
        shift @DB::args if $invocant eq (ref($DB::args[0])||$DB::args[0]);
    }
    my @args = @DB::args;

    my @expected;
    for(my $i = 0; $i < @_; $i++){
        if ($_[$i] && not defined $args[0]) {
           Carp::confess "missing mandatory parameter. pos: $i"; 
        }
        $expected[$i] = shift @args;
    }
    if (scalar(@args) > 0) {
        Carp::confess 'too much arguments. This function requires only ' . scalar(@_) . ' arguments.';
    }

    wantarray ? @expected : \@expected;
}

1;
__END__

=head1 NAME

Sub::Args - Simple check/get arguments.

=head1 SYNOPSIS

  package Your::Class;
  use Sub::Args;
  sub foo {
      my $class = shift;
      my $args = args(
          {
              name => 1,
              age  => 0,
          }
      );
      $args;
  }
  sub bar {
      my $class = shift;
      my $args = args(
          {
              name => 1,
              age  => 0,
          }
      );
      $args->{email}; # die: email is not defined hash key.
  }
  sub baz {
      my $class = shift;
      my ($var1, $var2) = args_pos(1,0);
  }
  
  # got +{name => nekokak, age => undef}
  Your::Class->foo(
      {
          name => 'nekokak',
      }
  );
  
  # got +{name => 'nekokak', age => 32}
  Your::Class->foo(
      {
          name => 'nekokak',
          age  => 32,
      }
  );
  
  # die: nick parameter don't defined for args method.
  Your::Class->foo(
      {
          name => 'nekokak',
          age  => 32,
          nick => 'inukaku',
      }
  );
  
  # die: name arguments must required.
  Your::Class->foo(
      {
          age => 32,
      }
  );

  Your::Class->baz('val1');

or

  package Your::Class;
  use Sub::Args;
  sub foo {
      my $class = shift;
      my $args = args(
          {
              name => 1,
              age  => 0,
          }, @_
      );
      $args;
  }
  
  # got +{name => nekokak}
  Your::Class->foo(
      {
          name => 'nekokak',
      }
  );

or

  package Your::Class;
  use Sub::Args;
  sub foo {
      my $args = args(
          {
              name => 1,
              age  => 0,
          }, @_
      );
      $args;
  }
  # got +{name => nekokak, age => undef}
  foo(
      {
          name => 'nekokak',
      }
  );

=head1 DESCRIPTION

This module makes your module more readable, and writable =p

and restrict a argument's hash. =(

When it accesses the key that doesn't exist, the exception is generated.

=head1 FUNCTIONS

=head2 my $hash_ref = args(\%rule, [@_]);

Check parameter and return read only hash-ref.

=head2 my @vals = args_pos(@rule);

Check parameter and return array or array-ref.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 CONTRIBUTORS

hirobanex : Hiroyuki Akabane

=head1 SEE ALSO

L<Params::Validate>

L<Smart::Args>

L<Data::Validator>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
