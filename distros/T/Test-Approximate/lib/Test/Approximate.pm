package Test::Approximate;
# ABSTRACT: Test and deeply test two number is approximate equality
use strict;
use warnings;

our $VERSION = 0.009;

use POSIX qw( strtod );
use Test::Builder;
our $Test = Test::Builder->new;

use base 'Exporter';
our @EXPORT = qw( is_approx approx );

our $DEFAULT_TOLERANCE = '1%';

sub is_approx {
    my ( $got, $expected, $msg, $tolerance ) = @_;

    $tolerance //= $DEFAULT_TOLERANCE;

    # build some diagnostics info
    my $short1 = length($got) > 12 ? substr($got, 0, 8) . '...' : $got;
    my $short2 = length($expected) > 12 ? substr($expected, 0, 8) . '...' : $expected;
    my $msg2 = "'$short1' =~ '$short2'";

    #set default message
    $msg = $msg2 unless defined($msg);

    unless ( $Test->ok(_is_approx($got, $expected, $tolerance), $msg) ) {
        $Test->diag("  test: $msg");

        if ( check_type($got) eq 'str' or check_type($expected) eq 'str' ) {
            $Test->diag(" error: diff between string\n     got: $got\nexpected: $expected");
            return;
        }
        my $diff = $got - $expected;
        if ( $tolerance =~ /^(.+)%$/ ) {
            my $percentage = ( $diff / $expected ) * 100;
            $Test->diag("  error: diff $percentage% is not under tolerance $tolerance");
        }
        else {
            $Test->diag("  error: diff $diff is not under tolerance $tolerance");
        }
    }

}

sub _is_approx {
    my ( $num1, $num2, $tolerance ) = @_;

    # borrowed form Test::Approx
    my $num1_type = check_type($num1);
    my $num2_type = check_type($num2);

    if ( $num1_type eq 'str' or $num2_type eq 'str' ) {
        return $num1 eq $num2;
    }
    # figure out what to use as the threshold
    my $threshold;
    if ( $tolerance =~ /^(.+)%$/ ) {
        my $percent = $1 / 100;

        $threshold = strtod( abs( $num1 * $percent ) );
    } else {
        $threshold = $tolerance;
    }

    my $dist = strtod( abs($num2 - $num1) );
    return $dist <= $threshold ? 1 : 0;
}

# borrowed from Test::Approx
sub check_type {
    my $arg = shift;

    local $! = 0;
    my ( $num, $unparsed ) = strtod($arg);
    return 'str' if ( ($arg eq '') || ($unparsed != 0) || $! );
    return 'num';
}

# deeply test approx
sub approx {
    my ( $structure, $torlerance ) = @_;

    if ( ref $structure eq '' ) {        # value
        return Test::Deep::Approximate->new($structure, $torlerance);
    }
    elsif ( ref $structure eq ref {} ) { # hash

        my $hash = {};
        foreach my $key ( keys %$structure ) {
            $hash->{$key} = approx($structure->{$key}, $torlerance);
        }
        return $hash;
    }
    elsif ( ref $structure eq ref [] ) { # array

        my $array = [];
        for my $item ( @$structure ) {
            push @$array, approx($item, $torlerance);
        }
        return $array;
    }
}

{
    package Test::Deep::Approximate;
    use Test::Deep::Cmp;

    sub init {
        my ( $self, $expect, $torlerance ) = @_;

        $self->{expect} = $expect;
        $self->{torlerance} = $torlerance;
    }

    sub _is_approx {
        shift;
        return  Test::Approximate::_is_approx(@_);
    }

    sub descend {
        my ( $self, $got ) = @_;

        return $self->_is_approx($got, $self->{expect}, $self->{torlerance});
    }

    sub diagnostics {
        my ( $self, $where, $last ) = @_;

        my $got = $last->{got};
        my $diag = <<EOM;
Comparing $where
     got : $got
expected : $self->{expect}
EOM
        return $diag;
    }

}

1;

__END__

=pod

=head1 NAME

Test::Approximate -- compare two number for approximate equality, deeply

=head1 SYNOPSIS

    use Test::Approximate;

    is_approx(1, 1.0001, 'approximate equal', '1%');
    is_approx(0.0001001, '1e-04', 'str vs num', '1%');
    is_approx(1000, 1000.01, 'absolute tolerance', '0.1');


    use Test::Deep;
    use Test::Approximate;

    $got = [ 1.00001, 2, 3, 4 ];
    $expect = [ 1, 2, 3, 4 ];
    cmp_deeply($got, approx($expect, '1%'), 'array');

    $got = { a => 1, b => 1e-3, c => [ 1.1, 2.5, 5, 1e-9 ] };
    $expect = { a => 1.0001, b => 1e-03, c => [ 1.1, 2.5, 5, 1.00001e-9 ] };
    cmp_deeply( $got, approx($expect, '0.01%'), 'hash mix array');

=head1 DESCRIPTION

This module can test two scalar string or number numberic approximate equal, and deeply test two array or hash or array of hash etc.

There is already a nice module do this -- L<Test::Approx>. I wrote this one because L<Test::Approx> can't do a deeply test, and I have not found a module do the same thing.

=head1 FUNCTIONS

=over 2

=item is_approx($got, $expected, [$msg, $tolerance])

Test $got and $expected 's difference.

This function is partly borrowed from L<Test::Approx>, without the string Levenshtein difference.
Only do a numeric difference; If you compare two string, the test will pass only when the two string is equal.

C<$test_name> defaults to C<'got' =~ 'expected'>

C<$tolerance> is used to determine how different the scalars can be, it
defaults to C<1%>.  It can also be set as a number representing a threshold.
To determine which:

  $tolerance = '6%'; # threshold = calculated at 6%
  $tolerance = 0.06; # threshold = 0.06

=item approx($aoh, $tolerance)

This function is used to do a deelpy approximate test, with L<Test::Deep>

    cmp_deeply($got, approx($expected, '1%'), 'test msg')

This will do a approximate compare every element of an array, and every value of a hash with the given tolerance, If the data is an complicate structure like hash of array , array of hash etc, it will walk all the element , and do a deep compare as you wish.

It is useful when you want do a deep approximate compare with a big data.

=back

=head1 EXPORTS

C<is_approx>, C<approx>

=head1 AUTHOR

tadegenban <tadegenban@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014 tadegenban.
Released under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::Approx>,
L<Test::Builder>,
L<Test::Deep::Between>,

=cut
