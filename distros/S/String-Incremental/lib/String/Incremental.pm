package String::Incremental;
use 5.008005;
use strict;
use warnings;
use Mouse;
use MouseX::Types::Mouse qw( Str ArrayRef is_Str );
use String::Incremental::Types qw( Char );
use String::Incremental::FormatParser;
use String::Incremental::Char;
use Data::Validator;
use Try::Tiny;

use overload (
    '""' => \&as_string,
    '++' => \&increment,
    '--' => \&decrement,
    '='  => sub { $_[0] },
);

extends qw( Exporter Tie::Scalar );

our $VERSION = "0.01";

our @EXPORT_OK = qw( incremental_string );

has 'format' => ( is => 'ro', isa => Str );
has 'items'  => ( is => 'ro', isa => ArrayRef );
has 'chars'  => ( is => 'ro', isa => ArrayRef['String::Incremental::Char'] );

sub BUILDARGS {
    my ($class, %args) = @_;
    my $v = Data::Validator->new(
        format => { isa => Str },
        orders => { isa => ArrayRef, default => [] },
    );
    %args = %{$v->validate( \%args )};

    my $p = String::Incremental::FormatParser->new( $args{format}, @{$args{orders}} );

    return +{
        format => $p->format,
        items  => $p->items,
        chars  => [ grep $_->isa( __PACKAGE__ . '::Char' ), @{$p->items} ],
    };
}

sub incremental_string {
    my ($format, @orders) = @_;
    return __PACKAGE__->new( format => $format, orders => \@orders );
}

sub char {
    my ($self, $i) = @_;
    my $ch;
    unless ( defined $i ) {
        die 'index to set must be specified';
    }
    unless ( $i =~ /^\d+$/ ) {
        die 'must be specified as Int';
    }
    unless ( defined ( $ch = $self->chars->[$i] ) ) {
        die 'out of index';
    }
    return $ch;
}

sub as_string {
    my ($self) = @_;
    my @vals = map "$_", @{$self->items};
    return sprintf( $self->format, @vals );
}

sub set {
    my $v = Data::Validator->new(
        val => { isa => Str },
    )->with( 'Method', 'StrictSequenced' );
    my ($self, $args) = $v->validate( @_ );

    my @ch = $self->_extract_incremental_chars( $args->{val} );
    for ( my $i = 0; $i < @ch; $i++ ) {
        my $char = $self->char( $i );
        $char->set( $ch[$i] );
    }

    return "$self";
}

sub increment {
    my ($self) = @_;
    my ($last_ch) = grep $_->isa( __PACKAGE__ . '::Char' ), reverse @{$self->items};
    if ( defined $last_ch ) {
        $last_ch++;
    }
    return "$self";
}

sub decrement {
    my ($self) = @_;
    my ($last_ch) = grep $_->isa( __PACKAGE__ . '::Char' ), reverse @{$self->items};
    if ( defined $last_ch ) {
        $last_ch--;
    }
    return "$self";
}

sub re {
    my ($self) = @_;
    my ($re, @re);

    @re = map {
        my $i = $_;
        my $_re = $i->re();
        my $ref = ref $_;
        $ref eq __PACKAGE__ . '::Char' ? "(${_re})" : $_re;
    } @{$self->items};

    (my $fmt = $self->format) =~ s/%(?:\d+(?:\.?\d+)?)?\S/\%s/g;
    $re = sprintf $fmt, @re;

    return qr/^(${re})$/;
}

sub _extract_incremental_chars {
    my $v = Data::Validator->new(
        val => { isa => Str },
    )->with( 'Method', 'StrictSequenced' );
    my ($self, $args) = $v->validate( @_ );
    my @ch;

    (my $match, @ch) = $args->{val} =~ $self->re();
    unless ( defined $match ) {
        my $msg = 'specified value does not match with me';
        die $msg;
    }

    return wantarray ? @ch : \@ch;
}

sub TIESCALAR {
    my ($class, @args) = @_;
    return $class->new( @args );
}

sub FETCH { $_[0] }

sub STORE {
    my ($self, @args) = @_;
    if ( ref( $args[0] ) eq '' ) {  # ignore when ++/--
        $self->set( @args );
    }
}

__PACKAGE__->meta->make_immutable();
__END__

=encoding utf-8

=head1 NAME

String::Incremental - incremental string with your rule

=head1 SYNOPSIS

    use String::Incremental;

    my $str = String::Incremental->new(
        format => 'foo-%2=-%=',
        orders => [
            [0..2],
            'abcd',
        ],
    );

    # or

    use String::Incremental qw( incremental_string );

    my $str = incremental_string(
        'foo-%2=-%=',
        [0..2],
        'abcd',
    );

    print "$str";  # prints 'foo-00-a'

    $str++; $str++; $str++;
    print "$str";  # prints 'foo-00-d'

    $str++;
    print "$str";  # prints 'foo-01-a'

    $str->set( 'foo-22-d' );
    print "$str";  # prints 'foo-22-d';
    $str++;  # dies, cannot ++ any more

=head1 DESCRIPTION

String::Incremental provides generating string that can increment in accordance with your format and rule.

=head1 CONSTRUCTORS

=over 4

=item new( %args ) : String::Incremental

format: Str

orders: ArrayRef

=back

=head1 METHODS

=over 4

=item as_string() : Str

returns "current" string.

following two variables are equivalent:

    my $a = $str->as_string();
    my $b = "$str";

=item set( $val : Str ) : String::Incremental

sets to $val.

tying with String::Incremental, assignment syntax is available as synonym of this method:

    tie my $str, 'String::Incremental', (
        format => 'foo-%2=-%=',
        orders => [ [0..2], 'abcd' ],
    );

    $str = 'foo-22-d';  # same as `$str->set( 'foo-22-d' )`
    print "$str";  # prints 'foo-22-d';

=item increment() : Str

increases positional state of order and returns its character.

following two operation are equivalent:

    $str->increment();
    $str++;

=item decrement() : Str

decreases positional state of order and returns its character.

following two operation are equivalent:

    $str->decrement();
    $str--;

=back

=head1 FUNCTIONS

=over 4

=item incremental_string( $format, @orders ) : String::Incremental

another way to construct String::Incremental instance.

this function is not exported automatically, you need to export manually:

    use String::Incremental qw( incremental_string );

=back

=head1 LICENSE

Copyright (C) issm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=cut
