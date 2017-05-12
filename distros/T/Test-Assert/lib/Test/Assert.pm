#!/usr/bin/perl -c

package Test::Assert;

=head1 NAME

Test::Assert - Assertion methods for those who like JUnit.

=head1 SYNOPSIS

  # Use as imported methods
  #
  package My::Test;

  use Test::Assert ':all';

  assert_true(1, "pass");
  assert_true(0, "fail");

  use Test::More;
  assert_test(sub { require_ok($module) });

  # Use for debugging purposes
  # Assertions are compiled only if Test::Assert was used
  # from the main package.
  #
  package My::Package;

  use Test::Assert ':assert';

  my $state = do_something();
  assert_true($state >= 1 && $state <=2) if ASSERT;
  if ($state == 1) {
      # 1st state
      do_foo();
  } elsif ($state == 2) {
      # 2nd and last state
      do_bar();
  }

  my $a = get_a();
  my $b = get_b();
  assert_num_not_equals(0, $b) if ASSERT;
  my $c = $a / $b;

  # Clean the namespace
  no Test::Assert;

  # From command line
  $ perl -MTest::Assert script.pl  # sets Test::Assert::ASSERT to 1

=head1 DESCRIPTION

This class provides a set of assertion methods useful for writing tests.  The
API is based on JUnit4 and L<Test::Unit::Lite> and the methods die on failure.

These assertion methods might be not useful for common L<Test::Builder>-based
(L<Test::Simple>, L<Test::More>, etc.) test units.

The assertion methods can be used in class which is derived from
C<Test::Assert> or used as standard Perl functions after importing them into
user's namespace.

C<Test::Assert> can also wrap standard L<Test::Simple>, L<Test::More> or other
L<Test::Builder>-based tests.

The assertions can be also used for run-time checking.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0504';


use Exception::Base (
    'ignore_class' => [ __PACKAGE__, 'Test::Builder' ],
    'Exception::Assertion',
);


# TRUE and FALSE
use constant::boolean;


# Debug mode is disabled by default
## no critic (ProhibitConstantPragma)
use constant ASSERT => FALSE;


# Export ASSERT flag, all assert_* methods and fail method
use Symbol::Util qw( export_package unexport_package stash );


# Variable required for assert_deep_equal
my $DNE = bless [], 'Test::Assert::Does::Not::Exist';


# Enable debug mode
sub import {
    my ($package, @names) = @_;
    my $caller = caller();

    # Enable only if called from main
    if ($caller eq 'main') {
        undef *ASSERT;
        *ASSERT = sub () { TRUE; };
    };

    my @export_ok = ( 'ASSERT', grep { /^(assert_|fail)/ } keys %{ stash(__PACKAGE__) } );
    my %export_tags = (
        all => [ @export_ok ],
        assert => [ grep { /^(assert_|ASSERT$)/ } @export_ok ],
    );

    return export_package($caller, $package, {
        OK   => \@export_ok,
        TAGS => \%export_tags,
    }, @names);
};


# Disable debug mode
sub unimport {
    my ($package, @names) = @_;
    my $caller = caller();

    # Disable only if called from main
    if ($caller eq 'main') {
        undef *ASSERT;
        *ASSERT = sub () { FALSE; };
    };

    return unexport_package($caller, $package);
};


## no critic (ProhibitNegativeExpressionsInUnlessAndUntilConditions)
## no critic (ProhibitSubroutinePrototypes)
## no critic (RequireArgUnpacking)
## no critic (RequireCheckingReturnValueOfEval)

# Fails a test with the given name.
sub fail (;$$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($message, $reason) = @_;

    Exception::Assertion->throw(
        message   => $message,
        reason    => $reason,
    );

    assert_false("Should never occured") if ASSERT;
    return FALSE;
};


# Asserts that a condition is true.
sub assert_true ($;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($boolean, $message) = @_;

    $self->fail($message, "Expected true value, got undef") unless defined $boolean;
    $self->fail($message, "Expected true value, got '$boolean'") unless $boolean;
    return TRUE;
};


# Asserts that a condition is false.
sub assert_false ($;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($boolean, $message) = @_;

    $self->fail($message, "Expected false value, got '$boolean'") unless not $boolean;
    return TRUE;
};


# Asserts that a value is null.
sub assert_null ($;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($value, $message) = @_;

    $self->fail($message, "'$value' is defined") unless not defined $value;
    return TRUE;
};


# Asserts that a value is not null.
sub assert_not_null ($;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($value, $message) = @_;

    $self->fail($message, 'undef unexpected') unless defined $value;
    return TRUE;
};


# Assert that two values are equal
sub assert_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($value1, $value2, $message) = @_;

    return TRUE if (not defined $value1 and not defined $value2);
    $self->fail(
        $message, 'Expected value was undef; should be using assert_null?'
    ) unless defined $value1;
    $self->fail($message, "Expected '$value1', got undef") unless defined $value2;
    if ($value1 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/ and
        $value2 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/)
    {
        no warnings 'numeric';
        $self->fail($message, 'Expected ' . (0+$value1) . ', got ' . (0+$value2)) unless $value1 == $value2;
    }
    else {
        $self->fail($message, "Expected '$value1', got '$value2'") unless $value1 eq $value2;
    };
    return TRUE;
};


# Assert that two values are not equal
sub assert_not_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($value1, $value2, $message) = @_;

    if (not defined $value1 and not defined $value2) {
        $self->fail($message, 'Both values were undefined');
    };
    return TRUE if (not defined $value1 xor not defined $value2);
    if ($value1 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/ and
           $value2 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/)
    {
        no warnings 'numeric';
        $self->fail($message, (0+$value1) . ' and ' . (0+$value2) . ' should differ') unless $value1 != $value2;
    }
    else {
        $self->fail($message, "'$value1' and '$value2' should differ") unless $value1 ne $value2;
    };
    return TRUE;
};


# Assert that two values are numerically equal
sub assert_num_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($value1, $value2, $message) = @_;
    return TRUE if (not defined $value1 and not defined $value2);
    no warnings 'numeric';
    $self->fail($message, 'Expected undef, got ' . (0+$value2)) if not defined $value1;
    $self->fail($message, 'Expected ' . (0+$value1) . ', got undef') if not defined $value2;
    $self->fail($message, 'Expected ' . (0+$value1) . ', got ' . (0+$value2)) unless $value1 == $value2;
    return TRUE;
};


# Assert that two values are numerically not equal
sub assert_num_not_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($value1, $value2, $message) = @_;
    if (not defined $value1 and not defined $value2) {
        $self->fail($message, 'Both values were undefined');
    };
    return TRUE if (not defined $value1 xor not defined $value2);
    no warnings 'numeric';
    $self->fail($message, (0+$value1) . ' and ' . (0+$value2) . ' should differ') unless $value1 != $value2;
    return TRUE;
};


# Assert that two strings are equal
sub assert_str_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($value1, $value2, $message) = @_;
    return TRUE if (not defined $value1 and not defined $value2);
    $self->fail(
        $message, 'Expected value was undef; should be using assert_null?'
    ) unless defined $value1;
    $self->fail($message, "Expected '$value1', got undef") unless defined $value2;
    $self->fail($message, "Expected '$value1', got '$value2'") unless "$value1" eq "$value2";
    return TRUE;
};


# Assert that two strings are not equal
sub assert_str_not_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($value1, $value2, $message) = @_;
    if (not defined $value1 and not defined $value2) {
        $self->fail($message, 'Both values were undefined');
    };
    return TRUE if (not defined $value1 xor not defined $value2);
    $self->fail($message, "'$value1' and '$value2' should differ") unless "$value1" ne "$value2";
    return TRUE;
};


# Assert that string matches regexp
sub assert_matches ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($regexp, $value, $message) = @_;
    $self->fail(
        $message, 'Expected value was undef; should be using assert_null?'
    ) unless defined $regexp;
    $self->fail(
        $message, 'Argument 1 to assert_matches() must be a regexp'
    ) unless ref $regexp eq 'Regexp';
    $self->fail($message, "Expected /$regexp/, got undef") unless defined $value;
    $self->fail($message, "'$value' didn't match /$regexp/") unless $value =~ $regexp;
    return TRUE;
};


# Assert that string matches regexp
sub assert_not_matches ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($regexp, $value, $message) = @_;
    $self->fail(
        $message, 'Expected value was undef; should be using assert_null?'
    ) unless defined $regexp;
    return TRUE if not defined $value;
    $self->fail(
        $message, 'Argument 1 to assert_not_matches() must be a regexp'
    ) unless ref $regexp eq 'Regexp';
    $self->fail($message, "'$value' matched /$regexp/") unless $value !~ $regexp;
    return TRUE;
};


# Assert that data structures are deeply equal
sub assert_deep_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($value1, $value2, $message) = @_;
    $self->fail($message, 'Both arguments were not references') unless ref $value1 or ref $value2;
    $self->fail($message, 'Argument 1 to assert_deep_equals() must be a reference') unless ref $value1;
    $self->fail($message, 'Argument 2 to assert_deep_equals() must be a reference') unless ref $value2;

    my $data_stack = [];
    my $seen_refs = {};

    $self->fail(
        $message, $self->_format_stack($data_stack)
    ) unless $self->_deep_check($value1, $value2, $data_stack, $seen_refs);

    return TRUE;
};


# Assert that data structures are deeply equal
sub assert_deep_not_equals ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($value1, $value2, $message) = @_;
    $self->fail($message, 'Both arguments were not references') unless ref $value1 or ref $value2;
    $self->fail($message, 'Argument 1 to assert_deep_equals() must be a reference') unless ref $value1;
    $self->fail($message, 'Argument 2 to assert_deep_equals() must be a reference') unless ref $value2;

    my $data_stack = [];
    my $seen_refs = {};

    $self->fail(
        $message, 'Both structures should differ'
    ) unless not $self->_deep_check($value1, $value2, $data_stack, $seen_refs);

    return TRUE;
};


# Assert that object is a class
sub assert_isa ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($class, $value, $message) = @_;

    $self->fail(
        $message, 'Class name was undef; should be using assert_null?'
    ) unless defined $class;
    $self->fail($message, "Expected '$class' object or class, got undef") unless defined $value;
    if (not __isa($value, $class)) {
        $self->fail($message, "Expected '$class' object or class, got '" . ref($value) . "' reference") if ref $value;
        $self->fail($message, "Expected '$class' object or class, got '$value' value");
    };
    return TRUE;
};


# Assert that object is not a class
sub assert_not_isa ($$;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($class, $value, $message) = @_;

    $self->fail(
        $message, 'Class name was undef; should be using assert_null?'
    ) unless defined $class;
    if (__isa($value, $class)) {
        $self->fail($message, "'$value' is a '$class' object or class");
    };
    return TRUE;
};


# Assert that code throws an exception
sub assert_raises ($&;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($expected, $code, $message) = @_;

    eval {
        $code->();
    };
    if ($@) {
        my $e = $@;
        if (ref $e and __isa($e, 'Exception::Base')) {
            return TRUE if $e->matches($expected);
        }
        else {
            if (ref $expected eq 'Regexp') {
                return TRUE if "$e" =~ $expected;
            }
            elsif (ref $expected eq 'ARRAY') {
                return TRUE if grep { __isa($e, $_) } @{ $expected };
            }
            elsif (not ref $expected) {
                my $caught_message = "$e";
                while ($caught_message =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { }
                $caught_message =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.)?\n$//s;
                return TRUE if $caught_message eq $expected;
            };
        };
        # Rethrow an exception
        ## no critic (RequireCarping)
        die $e;
    }
    else {
        $self->fail(
            $message, 'Expected exception was not raised'
        );
    };
    return TRUE;
};


# Assert that Test::Builder method is ok
sub assert_test (&;$) {
    # check if called as function
    my $self = __isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    my ($code, $message) = @_;

    my $diag_message = '';
    my $ok_message = '';
    my $ok_return = TRUE;

    no warnings 'once', 'redefine';
    local *Test::Builder::diag = sub {
        $diag_message .= $_[1] if defined $_[1];
    };
    local *Test::Builder::ok = sub {
        $ok_message .= $_[2] if defined $_[2];
        return $ok_return = $_[1];
    };

    $code->();
    if (not $ok_return) {
        my $new_message = (defined $message ? $message : '')
                        . (defined $message && $message ne '' && $ok_message ne '' ? ': ' : '')
                        . ($ok_message =~ /\n/s ? "\n" : '')
                        . $ok_message
                        . ($ok_message ne '' && $diag_message ne '' ? ': ' : '')
                        . ($diag_message =~ /\n/s ? "\n" : '')
                        . $diag_message;
        $self->fail(
            $new_message, 'assert_test failed'
        ) unless $ok_return;
    };
    return TRUE;
};


# Checks if deep structures are equal
sub _deep_check {
    my ($self, $e1, $e2, $data_stack, $seen_refs) = @_;

    if ( ! defined $e1 || ! defined $e2 ) {
        return TRUE if !defined $e1 && !defined $e2;
        push @$data_stack, { vals => [$e1, $e2] };
        return FALSE;
    };

    return TRUE if $e1 eq $e2;

    if ( ref $e1 && ref $e2 ) {
        my $e2_ref = "$e2";
        return TRUE if defined $seen_refs->{$e1} && $seen_refs->{$e1} eq $e2_ref;
        $seen_refs->{$e1} = $e2_ref;
    };

    if (ref $e1 eq 'ARRAY' and ref $e2 eq 'ARRAY') {
        return $self->_eq_array($e1, $e2, $data_stack, $seen_refs);
    }
    elsif (ref $e1 eq 'HASH' and ref $e2 eq 'HASH') {
        return $self->_eq_hash($e1, $e2, $data_stack, $seen_refs);
    }
    elsif (ref $e1 eq 'REF' and ref $e2 eq 'REF') {
        push @$data_stack, { type => 'REF', vals => [$e1, $e2] };
        my $ok = $self->_deep_check($$e1, $$e2, $data_stack, $seen_refs);
        pop @$data_stack if $ok;
        return $ok;
    }
    elsif (ref $e1 eq 'SCALAR' and ref $e2 eq 'SCALAR') {
        push @$data_stack, { type => 'REF', vals => [$e1, $e2] };
        return $self->_deep_check($$e1, $$e2, $data_stack, $seen_refs);
    }
    else {
        push @$data_stack, { vals => [$e1, $e2] };
    };

    return FALSE;
};


# Checks if arrays are equal
sub _eq_array  {
    my ($self, $a1, $a2, $data_stack, $seen_refs) = @_;

    return TRUE if $a1 eq $a2;

    my $ok = TRUE;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;

    foreach (0..$max) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

        push @$data_stack, { type => 'ARRAY', idx => $_, vals => [$e1, $e2] };
        $ok = $self->_deep_check($e1, $e2, $data_stack, $seen_refs);
        pop @$data_stack if $ok;

        last unless $ok;
    };

    return $ok;
};


# Checks if hashes are equal
sub _eq_hash {
    my ($self, $a1, $a2, $data_stack, $seen_refs) = @_;

    return TRUE if $a1 eq $a2;

    my $ok = TRUE;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    foreach my $k (keys %$bigger) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;

        push @$data_stack, { type => 'HASH', idx => $k, vals => [$e1, $e2] };
        $ok = $self->_deep_check($e1, $e2, $data_stack, $seen_refs);
        pop @$data_stack if $ok;

        last unless $ok;
    };

    return $ok;
};


# Dumps the differences for deep structures
sub _format_stack {
    my ($self, $data_stack) = @_;

    my $var = '$FOO';
    my $did_arrow = 0;
    foreach my $entry (@$data_stack) {
        my $type = $entry->{type} || '';
        my $idx  = $entry->{'idx'};
        if ($type eq 'HASH') {
            $var .= "->" unless $did_arrow++;
            $var .= "{$idx}";
        }
        elsif ($type eq 'ARRAY') {
            $var .= "->" unless $did_arrow++;
            $var .= "[$idx]";
        }
        elsif ($type eq 'REF') {
            $var = "\${$var}";
        };
    };

    my @vals = @{$data_stack->[-1]{vals}}[0,1];

    my @vars = ();
    ($vars[0] = $var) =~ s/\$FOO/  \$a/;
    ($vars[1] = $var) =~ s/\$FOO/  \$b/;

    my $out = "Structures begin differing at:\n";
    foreach my $idx (0..$#vals) {
        my $val = $vals[$idx];
        $vals[$idx] = !defined $val ? 'undef' :
                      $val eq $DNE  ? 'Does not exist'
                                    : "'$val'";
    };

    $out .= "$vars[0] = $vals[0]\n";
    $out .= "$vars[1] = $vals[1]";

    return $out;
};


# Better, safe "isa" function
sub __isa {
    my ($object, $class) = @_;
    local $@ = '';
    local $SIG{__DIE__} = '';
    return eval { $object->isa($class) };
};


no constant::boolean;
no Symbol::Util;


1;


=begin umlwiki

= Component Diagram =

[ Test::Assert |
  [Test::Assert {=}]
  [Exception::Assertion {=}] ]

= Class Diagram =

[                                 <<utility>>
                                 Test::Assert
 ----------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------
 fail( message : Str = undef, reason : Str = undef )
 assert_true( boolean : Bool, message : Str = undef )
 assert_false( boolean : Bool, message : Str = undef )
 assert_null( value : Any, message : Str = undef )
 assert_not_null( value : Any, message : Str = undef )
 assert_equals( value1 : Defined, value2 : Defined, message : Str = undef )
 assert_not_equals( value1 : Defined, value2 : Defined, message : Str = undef )
 assert_num_equals( value1 : Defined, value2 : Defined, message : Str = undef )
 assert_num_not_equals( value1 : Defined, value2 : Defined, message : Str = undef )
 assert_str_equals( value1 : Defined, value2 : Defined, message : Str = undef )
 assert_str_not_equals( value1 : Defined, value2 : Defined, message : Str = undef )
 assert_matches( regexp : RegexpRef, value : Str, message : Str = undef )
 assert_not_matches( regexp : RegexpRef, value : Str, message : Str = undef )
 assert_deep_equals( value1 : Ref, value2 : Ref, message : Str = undef )
 assert_deep_not_equals( value1 : Ref, value2 : Ref, message : Str = undef )
 assert_isa( class : Str, object : Defined, message : Str = undef )
 assert_not_isa( class : Str, object : Defined, message : Str = undef )
 assert_raises( expected : Any, code : CodeRef, message : Str = undef )
 assert_test( code : CodeRef, message : Str = undef )
 <<constant>> ASSERT() : Bool                                                        ]

[Test::Assert] ---> <<exception>> [Exception::Assertion]

[Exception::Assertion] ---|> [Exception::Base]

=end umlwiki

=head1 EXCEPTIONS

=over

=item Exception::Assertion

Thrown whether an assertion failed.

=back

=head1 USAGE

By default, the class does not export its symbols.

=over

=item use Test::Assert;

Enables debug mode if it is used in C<main> package.

  package main;
  use Test::Assert;    # Test::Assert::ASSERT is set to TRUE

  $ perl -MTest::Assert script.pl    # ditto

=item use Test::Assert 'assert_true', 'fail', ...;

Imports some methods.

=item use Test::Assert ':all';

Imports all C<assert_*> methods, C<fail> method and C<ASSERT> constant.

=item use Test::Assert ':assert';

Imports all C<assert_*> methods and C<ASSERT> constant.

=item no Test::Assert;

Disables debug mode if it is used in C<main> package.

=back

=head1 CONSTANTS

=over

=item ASSERT

This constant is set to true value if C<Test::Assert> module is used from
C<main> package.  It allows to enable debug mode globally from command line.
The debug mode is disabled by default.

  package My::Test;
  use Test::Assert ':assert';
  assert_true( 0 ) if ASSERT;  # fails only if debug mode is enabled

  $ perl -MTest::Assert script.pl  # enable debug mode

=back

=head1 METHODS

=over

=item fail( I<message> : Str = undef, I<reason> : Str = undef )

Immediate fail the test.  The L<Exception::Assertion> object will have set
I<message> and I<reason> attribute based on arguments.

=item assert_true( I<boolean> : Bool, I<message> : Str = undef )

Checks if I<boolean> expression returns true value.

=item assert_false( I<boolean> : Bool, I<message> : Str = undef )

Checks if I<boolean> expression returns false value.

=item assert_null( I<value> : Any, I<message> : Str = undef )

=item assert_not_null( I<value> : Any, I<message> : Str = undef )

Checks if I<value> is defined or not defined.

=item assert_equals( I<value1> : Defined, I<value2> : Defined, I<message> : Str = undef )

=item assert_not_equals( I<value1> : Defined, I<value2> : Defined, I<message> : Str = undef )

Checks if I<value1> and I<value2> are equals or not equals.  If I<value1> and
I<value2> look like numbers then they are compared with '==' operator,
otherwise the string 'eq' operator is used.

=item assert_num_equals( I<value1> : Defined, I<value2> : Defined, I<message> : Str = undef )

=item assert_num_not_equals( I<value1> : Defined, I<value2> : Defined, I<message> : Str = undef )

Force numeric comparation.

=item assert_str_equals( I<value1> : Defined, I<value2> : Defined, I<message> : Str = undef )

=item assert_str_not_equals( I<value1> : Defined, I<value2> : Defined, I<message> : Str = undef )

Force string comparation.

=item assert_matches( I<regexp> : RegexpRef, I<value> : Str, I<message> : Str = undef )

=item assert_not_matches( I<regexp> : RegexpRef, I<value> : Str, I<message> : Str = undef )

Checks if I<value> matches I<pattern> regexp.

=item assert_deep_equals( I<value1> : Ref, I<value2> : Ref, I<message> : Str = undef )

=item assert_deep_not_equals( I<value1> : Ref, I<value2> : Ref, I<message> : Str = undef )

Checks if reference I<value1> is a deep copy of reference I<value2> or not.
The references can be deep structure.  If they are different, the message will
display the place where they start differing.

=item assert_isa( I<class> : Str, I<object> : Defined, I<message> : Str = undef )

=item assert_not_isa( I<class> : Str, I<object> : Defined, I<message> : Str = undef )

Checks if I<value> is a I<class> or not.

  assert_isa( 'My::Class', $obj );

=item assert_raises( I<expected> : Any, I<code> : CodeRef, I<message> : Str = undef )

Runs the I<code> and checks if it raises the I<expected> exception.

If raised exception is an L<Exception::Base> object, the assertion passes if
the exception C<matches> I<expected> argument (via
C<L<Exception::Base>-E<gt>matches> method).

If raised exception is not an L<Exception::Base> object, several conditions
are checked.  If I<expected> argument is a string or array reference, the
assertion passes if the raised exception is a given class.  If the argument is
a regexp, the string representation of exception is matched against regexp.

  use Test::Assert 'assert_raises';

  assert_raises( 'foo', sub { die 'foo' } );
  assert_raises( ['Exception::Base'], sub { Exception::Base->throw } );

=item assert_test( I<code> : CodeRef, I<message> : Str = undef )

Wraps L<Test::Builder> based test function and throws L<Exception::Assertion>
if the test is failed.  The plan test have to be disabled manually.  The
L<Test::More> module imports the C<fail> method by default which conflicts
with C<Test::Assert> C<fail> method.

  use Test::Assert ':all';
  use Test::More ignore => [ '!fail' ];

  Test::Builder->new->no_plan;
  Test::Builder->new->no_ending(1);

  assert_test( sub { cmp_ok($got, '==', $expected, $test_name) } );

=back

=head1 SEE ALSO

L<Exception::Assertion>, L<Test::Unit::Lite>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Assert>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
