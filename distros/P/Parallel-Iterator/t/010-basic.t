# $Id: 010-basic.t 2701 2007-10-04 20:31:37Z andy $
use strict;
use warnings;
use Test::More tests => 13;
use Parallel::Iterator qw( iterate iterate_as_array iterate_as_hash );

sub array_iter {
    my @ar  = @_;
    my $pos = 0;
    return sub {
        return if $pos >= @ar;
        my @r = ( $pos, $ar[$pos] );
        $pos++;
        return @r;
    };
}

sub fill_array_from_iter {
    my $iter = shift;
    my @ar   = ();
    while ( my ( $pos, $value ) = $iter->() ) {
        # die "Value for $pos is undef!\n" unless defined $value;
        $ar[$pos] = $value;
    }

    return @ar;
}

{
    my @ar   = ( 1 .. 5 );
    my $iter = array_iter( @ar );
    my @got  = fill_array_from_iter( $iter );
    is_deeply \@got, \@ar, 'iterators';
}

for my $workers ( 0, 1, 2, 10 ) {
    my @nums        = ( 1 .. 100 );
    my @double      = map $_ * 2, @nums;
    my $done        = 0;
    my $double_iter = iterate(
        {
            workers => $workers,
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            return $job * 2;
        },
        array_iter( @nums )
    );

    my @got = fill_array_from_iter( $double_iter );
    is_deeply \@got, \@double, "double, $workers workers";
}

# Array iterator
{
    my @input     = ( 1 .. 5 );
    my @quad      = map $_ * 4, @input;
    my $quad_iter = iterate(
        {
            workers => 1,
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            return $job * 4;
        },
        \@input
    );

    my @got = fill_array_from_iter( $quad_iter );
    is_deeply \@got, \@quad, "array iterator";
}

# iterate_as_array
{
    my @input = ( 1 .. 5 );
    my @quad  = map $_ * 4, @input;
    my @got   = iterate_as_array(
        {
            workers => 1,
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            return $job * 4;
        },
        \@input
    );

    is_deeply \@got, \@quad, "array iterator";
}

# Hash iterator
{
    my %input = (
        one   => 1,
        three => 3,
        five  => 5,
        seven => 7,
        nine  => 9
    );
    my $treble_iter = iterate(
        {
            workers => 1,
            nowarn  => 1
        },
        sub {
            my ( $key, $job ) = @_;
            return $job * 3;
        },
        \%input
    );

    my %expect = %input;
    $_ *= 3 for values %expect;
    my %output;

    while ( my ( $k, $v ) = $treble_iter->() ) {
        $output{$k} = $v;
    }

    is_deeply \%output, \%expect, "iterate_as_array";
}

# iterate_as_hash
{
    my %input = (
        one   => 1,
        three => 3,
        five  => 5,
        seven => 7,
        nine  => 9
    );
    my %output = iterate_as_hash(
        {
            workers => 1,
            nowarn  => 1
        },
        sub {
            my ( $key, $job ) = @_;
            return $job * 3;
        },
        \%input
    );

    my %expect = %input;
    $_ *= 3 for values %expect;

    is_deeply \%output, \%expect, "iterate_as_hash";
}

# Empty input
{
    my @input = ();
    my @got   = iterate_as_array(
        {
            workers => 1,
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            return $job * 5;
        },
        \@input
    );

    is_deeply \@got, \@input, "array iterator";
}

# Die
{
    my @input = ( 1 .. 5 );
    my $iter  = iterate(
        {
            workers => 1,
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            die "Oops";
        },
        \@input
    );

    eval { $iter->() };
    like $@, qr{Oops}, "died OK";
}

# Warn
{
    my @input = ( 1 .. 5 );
    my $iter  = iterate(
        {
            workers => 1,
            onerror => 'warn',
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            die "Oops";
        },
        \@input
    );

    my @warning;
    local $SIG{__WARN__} = sub {
        push @warning, @_;
    };

    $iter->();
    like $warning[0], qr{Oops}, "warned OK";
}

# Callback
{
    my @input = ( 1 .. 5 );
    my @warning;
    my $iter = iterate(
        {
            workers => 1,
            onerror => sub { push @warning, @_ },
            nowarn  => 1
        },
        sub {
            my ( $id, $job ) = @_;
            die "Oops";
        },
        \@input
    );

    $iter->();
    like $warning[1], qr{Oops}, "warned OK";
}

1;
