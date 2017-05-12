package Test::Bits;
{
  $Test::Bits::VERSION = '0.02';
}
BEGIN {
  $Test::Bits::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;

use List::AllUtils qw( all any min );
use Scalar::Util qw( blessed reftype );

use parent qw( Test::Builder::Module );

our @EXPORT = qw( bits_is );

our $Builder;

my $UsageErrorBase
    = 'bits_is() should be passed a scalar of binary data and an array reference of numbers.';


sub bits_is ($$;$) {
    my $got    = shift;
    my $expect = shift;
    my $name   = shift;

    local $Builder = __PACKAGE__->builder();

    _check_got($got);
    _check_expect($expect);

    $got = [ map { ord($_) } split //, $got ];

    my $got_length    = @{$got};
    my $expect_length = @{$expect};

    my @errors;
    push @errors,
        'The two pieces of binary data are not the same length'
        . " (got $got_length, expected $expect_length)."
        unless $got_length eq $expect_length;

    my $length = min( $got_length, $expect_length );

    for my $i ( 0 .. $length - 1 ) {
        next if $got->[$i] == $expect->[$i];

        push @errors,
            sprintf(
            "Binary data begins differing at byte $i.\n"
                . "  Got:    %08b\n"
                . "  Expect: %08b",
            $got->[$i],
            $expect->[$i],
            );

        last;
    }

    if (@errors) {
        $Builder->ok( 0, $name );
        $Builder->diag( join "\n", @errors );
    }
    else {
        $Builder->ok( 1, $name );
    }

    return;
}

sub _check_got {
    my $got = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $error;
    if ( !defined $got ) {
        $error
            = $UsageErrorBase . ' You passed an undef as the first argument';
    }
    elsif ( ref $got ) {
        $error
            = $UsageErrorBase
            . ' You passed a '
            . reftype($got)
            . ' reference as the first argument';
    }
    else {
        if ( any { ord($_) > 255 } split //, $got ) {
            $error = $UsageErrorBase
                . ' You passed a string with UTF-8 data as the first argument';
        }
    }

    $Builder->croak($error)
        if $error;
}

sub _check_expect {
    my $expect = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $error;
    if ( !defined $expect ) {
        $error
            = $UsageErrorBase . ' You passed an undef as the second argument';
    }
    elsif ( !ref $expect ) {
        $error = $UsageErrorBase
            . ' You passed a plain scalar as the second argument';
    }
    elsif ( reftype($expect) eq 'ARRAY' ) {
        unless (
            all {
                defined $_
                    && !ref $_
                    && $_ =~ /^\d+$/
                    && $_ >= 0
                    && $_ <= 255;
            }
            @{$expect}
            ) {

            $error = $UsageErrorBase
                . q{ The second argument contains a value which isn't a number from 0-255};
        }
    }
    else {
        $error
            = $UsageErrorBase
            . ' You passed a '
            . reftype($expect)
            . ' reference as the second argument';
    }

    $Builder->croak($error)
        if $error;
}

1;

# ABSTRACT: Provides a bits_is() subroutine for testing binary data

__END__

=pod

=head1 NAME

Test::Bits - Provides a bits_is() subroutine for testing binary data

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Test::Bits;

  bits_is(
      $binary_data,
      [ 0b0010101, 0b01111100 ],
      'binary data contains expected values'
  );

=head1 DESCRIPTION

This module provides a single subroutine, C<bits_is()>, for testing binary
data.

This module is quite similar to L<Test::BinaryData> and L<Test::HexString> in
concept. The difference is that this module shows failure diagnostics in a
different way, and has a slightly different calling style. Depending on the
nature of the data you're working with, this module may be easier to work with.

In particular, when you're doing a lot of bit twiddling, this module's
diagnostic output may make it easier to diagnose failures. A typical failure
diagnostic will look like this:

   The two pieces of binary data are not the same length (got 2, expected 3).
   Binary data begins differing at byte 1.
     Got:    01111000
     Expect: 01111001

Note that the bytes are numbered starting from 0 in the diagnostic output.

=for Pod::Coverage bits_is

=head1 USAGE

The C<bits_is()> subroutine takes two required arguments and an optional test
name.

The first argument should be a plain scalar containing I<binary> data. If it
contains any UTF-8 characters an error will be thrown.

The second argument should be an array reference of numbers from 0-255
representing the expected value of each byte in the first argument.

This allows you write the numbers out in binary format (0bXXXXXXXX) for test
cases if you wish to.

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-bits@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
