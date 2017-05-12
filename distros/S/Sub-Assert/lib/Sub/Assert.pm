package Sub::Assert;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
  assert
);
our $VERSION = '1.23';

use Carp qw/croak carp/;

sub assert {
  my %params = @_;
  my $sub    = $params{sub};
  defined $sub or croak("assert missing the subroutine to work with");

  my $package;
  my $subref;
  if (ref $sub eq 'CODE') {
    $subref = $sub;
  }
  elsif (ref $sub eq '') {
    ($package, undef, undef) = caller();
    defined $package
      or croak("assert could not determine caller package");
    no strict 'refs';
    $subref = *{"${package}::$sub"}{CODE};
    use strict 'refs';
    defined $subref and ref($subref) eq 'CODE'
      or croak("assert finds that there is no '$sub' subroutine in package '$package'");
  }
  else {
    croak("Subroutine argument to assert is invalid");
  }

  $params{action} = 'croak' unless defined $params{action};
  my $action = $package . '::' . $params{action};

  my $precond = _normalize_conditions($params{pre}, 'precondition');

  my $postcond = _normalize_conditions($params{post}, 'postcondition');

  my $context;
  if (exists $params{context}) {
    unless (defined $params{context} and
      $params{context} eq 'list' ||
      $params{context} eq 'scalar' ||
      $params{context} eq 'void' ||
      $params{context} eq 'novoid' ||
      $params{context} eq 'any'
    ) {
      croak("Invalid context specified for assertion");
    }
    $context = $params{context};
  }
  else {
    $context = 'any';
  }
  
  my $new_sub_text = "sub {\nmy \@PARAM = \@_;\n";

  if ($context eq 'list') {
    $new_sub_text .= "unless (wantarray()) {\n" .
         "my \$context = (defined wantarray() ?\n" .
          "      'scalar' : 'void');\n" .
         "$action(\"" .
         (ref($sub) eq 'CODE' ?
           'C' :
           "${package}::$sub c"
         ) .
         'alled in $context context.")' .
         "}\n";
  }
  elsif ($context eq 'scalar') {
    $new_sub_text .= "unless (defined(wantarray()) and not " .
         "wantarray()) {\n" .
         "my \$context = (wantarray() ?\n" .
          "      'list' : 'void');\n" .
         "$action(\"" .
         (ref($sub) eq 'CODE' ?
           'C' :
           "${package}::$sub c"
         ) .
         'alled in $context context.")' .
         "}\n";
  }
  elsif ($context eq 'novoid') {
    $new_sub_text .= "unless (defined wantarray()) {\n" .
         "$action(\"" .
         (ref($sub) eq 'CODE' ?
           'C' :
           "${package}::$sub c"
         ) .
         'alled in void context.")' .
         "}\n";
  }
  elsif ($context eq 'void') {
    $new_sub_text .= "unless (not defined wantarray()) {\n" .
         "my \$context = (wantarray() ?\n" .
          "      'list' : 'scalar');\n" .
         "$action(\"" .
         (ref($sub) eq 'CODE' ?
           'C' :
           "${package}::$sub c"
         ) .
         'alled in $context context.")' .
         "}\n";
  }

  foreach my $pre_name (keys %$precond) {
    if ($pre_name eq '_') {
      my $pre_array = $precond->{'_'};
      foreach my $pre_no (1..@$pre_array) {
        $new_sub_text .= 
             "do{\n".$pre_array->[$pre_no-1]
             . "\n}\nor $action(\"Precondition "
             . "$pre_no "
             . (ref($sub) eq 'CODE' ? '' : "for ${package}::$sub ")
             . "failed.\");\n\n";
      }
    }
    else {
      $new_sub_text .= 
           "do{\n".$precond->{$pre_name}
           . "\n}\nor $action(\"Precondition "
           . "'$pre_name' "
           . (ref($sub) eq 'CODE' ? '' : "for ${package}::$sub ")
           . "failed.\");\n\n";
    }
  }
  $new_sub_text .= <<'HERE';
my @RETURN;
my $RETURN;
my $VOID;
if (wantarray()) {
  @RETURN = $SUBROUTINEREF->(@PARAM);
  $RETURN = $RETURN[0] if @RETURN;
}
elsif (defined wantarray()) {
  $RETURN = $SUBROUTINEREF->(@PARAM);
  @RETURN = ($RETURN);
}
else {
  $VOID = 1;
  $SUBROUTINEREF->(@PARAM);
}
HERE

  foreach my $post_name (keys %$postcond) {
    if ($post_name eq '_') {
      my $post_array = $postcond->{'_'};
      foreach my $post_no (1..@$post_array) {
        $new_sub_text .= 
             "do{\n".$post_array->[$post_no-1]
             . "\n}\nor $action(\"Postcondition "
             . "$post_no "
             . (ref($sub) eq 'CODE' ? '' : "for ${package}::$sub ")
             . "failed.\");\n\n";
      }
    }
    else {
      $new_sub_text .= 
           "do{\n".$postcond->{$post_name}
           . "\n}\nor $action(\"Postcondition "
           . "'$post_name' "
           . (ref($sub) eq 'CODE' ? '' : "for ${package}::$sub ")
           . "failed.\");\n\n";
    }
  }
  
  $new_sub_text .= ($context eq 'list' ?
        "return \@RETURN;\n}\n" :
        "return \$RETURN;\n}\n"
       );
  my ($new_sub_ref, $error) =
    _generate_assertion_subroutine($subref, $new_sub_text);
  
  if ($error) {
    croak("Compilation of assertions failed: $error.\n$new_sub_text");
  }
  if (ref($sub) eq 'CODE') {
    return $new_sub_ref;
  }
  else {
    no strict;
    no warnings;
    *{"${package}::$sub"} = $new_sub_ref;
    use strict;
    use warnings;
  }
  return $new_sub_ref;
}

sub _generate_assertion_subroutine {
  local $@;
  my $SUBROUTINEREF = $_[0];
  return eval($_[1]), "$@";
}

sub _normalize_conditions {
  my $conditions = shift;
  my $type = shift;

  if (not defined $conditions) {
    # no conditions
    $conditions = {};
  }
  elsif (ref($conditions) eq '') {
    # a single, unnamed condition
    $conditions = {'_' =>[$conditions]};
  }
  elsif (ref($conditions) eq 'ARRAY') {
    # an array of unnamed conditions
    my $ary = $conditions;
    $conditions = {'_' => [@$ary]};
  }
  elsif (ref($conditions) eq 'HASH') {}
  else {
    croak("Invalid type of $type");
  }

  foreach my $name (keys %$conditions) {
    if ($name eq '_') {
      foreach my $cond (@{$conditions->{'_'}}) {
        croak("Invalid unnamed $type")
          if ref($cond) ne '';
      }
    }
    else {
      croak("Invalid $type '$name'")
        if ref($conditions->{$name}) ne '';
    }
  }
  
  return $conditions;
}

1;
__END__

=head1 NAME

Sub::Assert - Subroutine pre- and postconditions, etc.

=head1 SYNOPSIS

  use Sub::Assert;
  
  sub squareroot {
      my $x = shift;
      return $x**0.5;
  }
  
  assert
         pre     => {
            # named assertion:
           'parameter larger than one' => '$PARAM[0] >= 1',
         },
         post    => '$VOID or $RETURN <= $PARAM[0]', # unnamed assertion
         sub     => 'squareroot',
         context => 'novoid',
         action  => 'carp';
  
  print squareroot(2), "\n";  # prints 1.41421 and so on
  print squareroot(-1), "\n"; # warns
                              # "Precondition 1 for main::squareroot failed."
  squareroot(2);              # warns
                              # "main::squareroot called in void context."
  
  sub faultysqrt {
      my $x = shift;
      return $x**2;
  }

  assert
         pre    => '$PARAM[0] >= 1',
         post   => '$RETURN <= $PARAM[0]',
         sub    => 'faultysqrt';
  
  print faultysqrt(2), "\n";  # dies with 
                              # "Postcondition 1 for main::squareroot failed."

=head1 DESCRIPTION

The Sub::Assert module implements
subroutine pre- and postconditions. Furthermore, it allows restricting
the subroutine's calling context.

There's one big gotcha with this: It's slow. For every call to
subroutines you use assert() with, you pay for the error checking
with an extra subroutine call, some memory and some additional code
that's executed.

Fortunately, there's a workaround for mature software
which does not require you to edit a lot of your code. Instead of
use()ing Sub::Assert, you simply use Sub::Assert::Nothing and leave
the assertions intact. While you still suffer the calls to assert()
once, you won't pay the run-time penalty usually associated with
subroutine pre- and postconditions. Of course, you lose the benefits,
too, but as stated previously, this is a workaround in case you
want the verification at development time, but prefer speed in
production without refactoring your code.

=head2 assert

The assert subroutine takes a key/value list of named parameters.

=over 4

=item sub

The only required parameter is the 'sub' parameter that specifies
which subroutine (in the current package) to replace with the
assertion wrapper. The 'sub' parameter may either be a string
in which case the current packages subroutine of that name is
replaced, or it may be a subroutine reference. In the latter case,
assert() returns the assertion wrapper as a subroutine reference.

=item pre

This parameter specifies one or more preconditions that the data
passed to the transformed subroutine must match. The preconditions
may either be a string in case there's only one, unnamed precondition,
an array (reference) of strings in case there's many unnamed preconditions,
or a hash reference of name/condition pairs for named preconditions.

There are several special variables in the scope in which these
preconditions are evaluated. Most importantly, @PARAM will hold
the list of arguments as passed to the subroutine. Furthermore,
there is the scalar $SUBROUTINEREF which holds the reference to
the subroutine that does the actual work. I am mentioning this
variable because I don't want you to muck with it.

=item post

This parameter specifies one or more postconditions that the data
returned from the subroutine must match. Syntax is identical to
that of the preconditions except that there are more special vars:

In scalar context, $RETURN holds the return value of the subroutine
and $RETURN[0] does, too. $VOID is undefined.

In list context, @RETURN holds all return values of the subroutine
and $RETURN holds the first. $VOID is undefined.

In void context, $RETURN is undefined and @RETURN is empty.
$VOID, however, is true.

Note the behaviour in void context. May be a bug or a feature. I'd
appreciate feedback and suggestions on how to solve is more elegantly.

=item context

Optionally, you may restrict the calling context of the subroutine.
The context parameter may be any of the following and defaults to
no restrictions ('any'):

=over 4

=item any

This means that there is no restriction on the calling context of
the subroutine. Please refer to the documentation of the 'post'
parameter for a gotcha with void context.

=item scalar

This means that the assertion wrapper will throw an error of the
calling context of the subroutine is not scalar context.

=item list

This means that the assertion wrapper will throw an error of the
calling context of the subroutine is not list context.

=item void

This means that the assertion wrapper will throw an error of the
calling context of the subroutine is not void context. Please refer
to the documentation of the 'post' parameter for a gotcha with void
context.

=item novoid

This restricts the calling context to any but void context.

=back

=item action

By default, the assertion wrapper croaks when encountering an error.
You may override this behaviour by supplying an action parameter.
This parameter is to be the name of a function to handle the
error. This function will then be passed the error string.
Please note that the immediate predecessor of the subroutine on
the call stack is the code evaluation. Thus, for a helpful error
message, you'd want to use 'carp' and 'croak' instead of the
analogeous 'warn' and 'die'. Your own error handling functions
need to be aware of this, too. Please refer to the documentation
of the Carp module and the caller() function. Examples:

  action => 'carp',
  action => 'my_function_that_handles_the_error',
  action => '$anon_sub->',  # works only in the lexical scope of $anon_sub!

=back

=head2 EXPORT

Exports the 'assert' subroutine to the caller's namespace.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2009 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<Sub::Assert::Nothing>

Look for new versions of this module on CPAN or at
http://steffen-mueller.net

=cut
