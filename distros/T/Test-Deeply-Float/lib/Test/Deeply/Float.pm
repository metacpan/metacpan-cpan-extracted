## no critic (Subroutines::ProhibitSubroutinePrototypes BuiltinFunctions::RequireBlockGrep)

package Test::Deeply::Float;

our $DATE = '2018-08-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.006;
use strict;
use warnings;

use Scalar::Util::Numeric qw(isint isfloat);

# Can't use Carp because it might cause C<use_ok()> to accidentally succeed
# even though the module being used forgot to use Carp.  Yes, this
# actually happened.
sub _carp {
    my( $file, $line ) = ( caller(1) )[ 1, 2 ];
    return warn @_, " at $file line $line\n";
}

use Test::Builder::Module;
our @ISA    = qw(Test::Builder::Module);
our @EXPORT = qw(
  is_deeply_float
);
our $EPSILON = 1e-6;

sub _eval {
    my( $code, @args ) = @_;

    # Work around oddities surrounding resetting of $@ by immediately
    # storing it.
    my( $sigdie, $eval_result, $eval_error );
    {
        local( $@, $!, $SIG{__DIE__} );    # isolate eval
        $eval_result = eval $code;              ## no critic (BuiltinFunctions::ProhibitStringyEval)
        $eval_error  = $@;
        $sigdie      = $SIG{__DIE__} || undef;
    }
    # make sure that $code got a chance to set $SIG{__DIE__}
    $SIG{__DIE__} = $sigdie if defined $sigdie;

    return( $eval_result, $eval_error );
}

our( @Data_Stack, %Refs_Seen );
my $DNE = bless [], 'Does::Not::Exist';

sub _dne {
    return ref $_[0] eq ref $DNE;
}

sub is_deeply_float {
    my $tb = __PACKAGE__->builder;

    unless( @_ == 2 or @_ == 3 ) {
        my $msg = <<'WARNING';
is_deeply_float() takes two or three args, you gave %d.
This usually means you passed an array or hash instead
of a reference to it
WARNING
        chop $msg;    # clip off newline so carp() will put in line/file

        _carp sprintf $msg, scalar @_;

        return $tb->ok(0);
    }

    my( $got, $expected, $name ) = @_;

    $tb->_unoverload_str( \$expected, \$got );

    my $ok;
    if( !ref $got and !ref $expected ) {    # neither is a reference
        if (defined $got && (isint($got) || isfloat($got)) &&
                defined $expected && (isint($expected) || isfloat($expected))) {
            my $test = abs($got - $expected) < $EPSILON;
            $ok = $tb->ok($test, $name);
            if (!$ok) {
                $tb->diag(<<DIAG);
         got: $got
    expected: $expected
     epsilon: $EPSILON
DIAG
            }
        } else {
            $ok = $tb->is_eq( $got, $expected, $name );
        }
    }
    elsif( !ref $got xor !ref $expected ) {    # one's a reference, one isn't
        $ok = $tb->ok( 0, $name );
        $tb->diag( _format_stack({ vals => [ $got, $expected ] }) );
    }
    else {                                     # both references
        local @Data_Stack = ();
        if( _deep_check( $got, $expected ) ) {
            $ok = $tb->ok( 1, $name );
        }
        else {
            $ok = $tb->ok( 0, $name );
            $tb->diag( _format_stack(@Data_Stack) );
        }
    }

    return $ok;
}

sub _format_stack {
    my(@Stack) = @_;

    my $var       = '$FOO';
    my $did_arrow = 0;
    foreach my $entry (@Stack) {
        my $type = $entry->{type} || '';
        my $idx = $entry->{'idx'};
        if( $type eq 'HASH' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "{$idx}";
        }
        elsif( $type eq 'ARRAY' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "[$idx]";
        }
        elsif( $type eq 'REF' ) {
            $var = "\${$var}";
        }
    }

    my @vals = @{ $Stack[-1]{vals} }[ 0, 1 ];
    my @vars = ();
    ( $vars[0] = $var ) =~ s/\$FOO/     \$got/;
    ( $vars[1] = $var ) =~ s/\$FOO/\$expected/;

    my $out = "Structures begin differing at:\n";
    foreach my $idx ( 0 .. $#vals ) {
        my $val = $vals[$idx];
        $vals[$idx]
          = !defined $val ? 'undef'
          : _dne($val)    ? "Does not exist"
          : ref $val      ? "$val"
          :                 "'$val'";
    }

    $out .= "$vars[0] = $vals[0]\n";
    $out .= "$vars[1] = $vals[1]\n";

    $out =~ s/^/    /msg;
    return $out;
}

sub _type {
    my $thing = shift;

    return '' if !ref $thing;

    for my $type (qw(Regexp ARRAY HASH REF SCALAR GLOB CODE VSTRING)) {
        return $type if UNIVERSAL::isa( $thing, $type );
    }

    return '';
}

sub _eq_array {
    my( $a1, $a2 ) = @_;

    if( grep _type($_) ne 'ARRAY', $a1, $a2 ) {
        warn "eq_array passed a non-array ref";
        return 0;
    }

    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for( 0 .. $max ) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

        next if _equal_nonrefs($e1, $e2);

        push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [ $e1, $e2 ] };
        $ok = _deep_check( $e1, $e2 );
        pop @Data_Stack if $ok;

        last unless $ok;
    }

    return $ok;
}

sub _eq_float {
    my ($e1, $e2) = @_; # both must be defined
    if ((isint($e1) || isfloat($e1)) &&
            (isint($e2) || isfloat($e2))) {
        return abs($e1 - $e2) < $EPSILON;
    } else {
        return $e1 eq $e2;
    }
}

sub _equal_nonrefs {
    my( $e1, $e2 ) = @_;

    return if ref $e1 or ref $e2;

    if ( defined $e1 ) {
        return 1 if defined $e2 and _eq_float($e1, $e2);
    }
    else {
        return 1 if !defined $e2;
    }

    return;
}

sub _deep_check {
    my( $e1, $e2 ) = @_;
    my $tb = __PACKAGE__->builder;

    my $ok = 0;

    # Effectively turn %Refs_Seen into a stack.  This avoids picking up
    # the same referenced used twice (such as [\$a, \$a]) to be considered
    # circular.
    local %Refs_Seen = %Refs_Seen;

    {
        $tb->_unoverload_str( \$e1, \$e2 );

        # Either they're both references or both not.
        my $same_ref = !( !ref $e1 xor !ref $e2 );
        my $not_ref = ( !ref $e1 and !ref $e2 );

        if( defined $e1 xor defined $e2 ) {
            $ok = 0;
        }
        elsif( !defined $e1 and !defined $e2 ) {
            # Shortcut if they're both undefined.
            $ok = 1;
        }
        elsif( _dne($e1) xor _dne($e2) ) {
            $ok = 0;
        }
        elsif( $same_ref and( $e1 eq $e2 ) ) {
            $ok = 1;
        }
        elsif($not_ref) {
            push @Data_Stack, { type => '', vals => [ $e1, $e2 ] };
            $ok = 0;
        }
        else {
            if( $Refs_Seen{$e1} ) {
                return $Refs_Seen{$e1} eq $e2;
            }
            else {
                $Refs_Seen{$e1} = "$e2";
            }

            my $type = _type($e1);
            $type = 'DIFFERENT' unless _type($e2) eq $type;

            if( $type eq 'DIFFERENT' ) {
                push @Data_Stack, { type => $type, vals => [ $e1, $e2 ] };
                $ok = 0;
            }
            elsif( $type eq 'ARRAY' ) {
                $ok = _eq_array( $e1, $e2 );
            }
            elsif( $type eq 'HASH' ) {
                $ok = _eq_hash( $e1, $e2 );
            }
            elsif( $type eq 'REF' ) {
                push @Data_Stack, { type => $type, vals => [ $e1, $e2 ] };
                $ok = _deep_check( $$e1, $$e2 );
                pop @Data_Stack if $ok;
            }
            elsif( $type eq 'SCALAR' ) {
                push @Data_Stack, { type => 'REF', vals => [ $e1, $e2 ] };
                $ok = _deep_check( $$e1, $$e2 );
                pop @Data_Stack if $ok;
            }
            elsif($type) {
                push @Data_Stack, { type => $type, vals => [ $e1, $e2 ] };
                $ok = 0;
            }
            else {
                _whoa( 1, "No type in _deep_check" );
            }
        }
    }

    return $ok;
}

sub _whoa {
    my( $check, $desc ) = @_;
    if($check) {
        die <<"WHOA";
WHOA!  $desc
This should never happen!  Please contact the author immediately!
WHOA
    }
}

sub _eq_hash {
    my( $a1, $a2 ) = @_;

    if( grep _type($_) ne 'HASH', $a1, $a2 ) {
        warn "eq_hash passed a non-hash ref";
        return 0;
    }

    return 1 if $a1 eq $a2;

    my $ok = 1;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    foreach my $k ( keys %$bigger ) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;

        next if _equal_nonrefs($e1, $e2);

        push @Data_Stack, { type => 'HASH', idx => $k, vals => [ $e1, $e2 ] };
        $ok = _deep_check( $e1, $e2 );
        pop @Data_Stack if $ok;

        last unless $ok;
    }

    return $ok;
}

1;
# ABSTRACT: Test equality of data structure, compare numbers with tolerance

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deeply::Float - Test equality of data structure, compare numbers with tolerance

=head1 VERSION

This document describes version 0.001 of Test::Deeply::Float (from Perl distribution Test-Deeply-Float), released on 2018-08-07.

=head1 SYNOPSIS

 use Test::More; # exports is_deeply(), etc
 use Test::Deeply::Float; # exports is_deeply_float()

 is_deeply      ({a => 1, b => 1.1234567}, {a => 1, b => 1.1234568}); # fail
 is_deeply_float({a => 1, b => 1.1234567}, {a => 1, b => 1.1234568}); # pass
 is_deeply_float({a => 1, b => 1.12345  }, {a => 1, b => 1.12346  }); # fail

To customize tolerance level:

 $Test::Deeply::Float::EPSILON = 1e-9; # default is 1e-6

=head1 DESCRIPTION

This module exports C<is_deeply_float()> which is just like L<Test::More>'s
C<is_deeply()>, except that when comparing two numbers (ints or floats) a
tolerance is allowed to work around floating point rounding problem.

=head1 FUNCTIONS

=head2 is_deeply_float

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Deeply-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Deeply-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Deeply-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Based on L<Test::More>'s C<is_deeply()>.

L<Test::Number::Delta> and L<Test::Deep>'s C<num()> can also compare floats with
tolerance, but not in data structures.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
