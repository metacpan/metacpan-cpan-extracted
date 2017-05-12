package String::Incremental::Char;
use 5.008005;
use warnings;
use Mouse;
use Data::Validator;
use MouseX::Types::Mouse qw( Bool Int );
use String::Incremental::Types qw( Char CharOrderStr CharOrderArrayRef is_CharOrderStr );
use Try::Tiny;

use overload (
    '""' => \&as_string,
    '++' => \&increment,
    '--' => \&decrement,
    '='  => sub { $_[0] },
);

has 'order'  => ( is  => 'ro', isa => CharOrderArrayRef );
has 'upper'  => ( is  => 'ro', isa => __PACKAGE__, predicate => 'has_upper' );
has '__i'    => ( is => 'rw', isa => Int );
has '__size' => ( is => 'ro', isa => Int );

sub BUILDARGS {
    my ($class, %args) = @_;
    my $v = Data::Validator->new(
        order => { isa => CharOrderStr|CharOrderArrayRef },
        upper => { isa => __PACKAGE__, optional => 1 },
        set   => { isa => Char, optional => 1 },
        __i   => { isa => Int, default => 0 },  # for internal use
    );
    %args = %{$v->validate( \%args )};

    if ( is_CharOrderStr( $args{order} ) ) {
        $args{order} = [ split //, $args{order} ];
    }

    %args = (
        %args,
        __size => 0 + @{$args{order}},
    );

    if ( $args{__i} >= $args{__size} ) {
        my $msg = '__i: should be less than size of "order"';
        die $msg;
    }

    return \%args;
}

sub BUILD {
    my ($self, $args) = @_;
    if ( exists $args->{set} ) {
        $self->set( $args->{set} );
    }
}

sub as_string {
    my ($self) = @_;
    return $self->order->[ $self->__i ];
}

sub set {
    my ($self, $ch, $opts) = @_;
    my $v_opts = Data::Validator->new(
        test => { isa => Bool, default => 0 },
    );
    $opts = $v_opts->validate( %{$opts || {}} );

    unless ( defined $ch ) {
        die 'value to set must be specified';
    }
    unless ( $ch =~ /^.$/ ) {
        die 'must be specified as a character';
    }
    my ($i, $found) = ( 0, 0 );
    for ( @{$self->order} ) {
        if ( $_ eq $ch ) {
            $found = 1;
            last;
        }
        $i++;
    }
    unless ( $found ) {
        my $msg = srintf( '"%s" is not in order', $ch );
        die $msg;
    }
    unless ( $opts->{test} ) {
        $self->__i( $i );
    }
    return "$self";
}

sub increment {
    my ($self) = @_;
    my ($i_try, $ch);
    $i_try = $self->__i + 1;

    if ( $i_try >= $self->__size ) {
        if ( $self->has_upper() ) {
            my $upper = $self->upper;
            try {
                $upper->increment();
                $i_try = 0;
            } catch {
                my ($msg) = @_;
                die $msg;
            };
        }
        else {
            my $msg = 'cannot increment';
            die $msg;
        }
    }

    $self->__i( $i_try );
    return $self->as_string();
}

sub decrement {
    my ($self) = @_;
    my ($i_try, $ch);
    $i_try = $self->__i - 1;

    if ( $i_try < 0 ) {
        if ( $self->has_upper() ) {
            my $upper = $self->upper;
            try {
                $upper->decrement();
                $i_try = $self->__size - 1;
            } catch {
                my ($msg) = @_;
                die $msg;
            };
        }
        else {
            my $msg = 'cannot decrement';
            die $msg;
        }
    }

    $self->__i( $i_try );
    return $self->as_string();
}

sub re {
    my ($self) = @_;
    my $re = join '', map {
        my $i = $_;
        #  ref: http://search.cpan.org/perldoc?perlrecharclass#Special_Characters_Inside_a_Bracketed_Character_Class
        ( $i =~ m/[\\\^\-\[\]]/ ) ? "\\${i}" : $i;
    } @{$self->order};
    return qr/[$re]/;
}

__PACKAGE__->meta->make_immutable();
__END__

=encoding utf-8

=head1 NAME

String::Incremental::Char

=head1 SYNOPSIS

    use String::Incremental::Char;

    my $ch = String::Incremental::Char->new( order => 'abcd' );

    print "$ch";  # -> 'a';

    $ch++; $ch++; $ch++;
    print "$ch";  # -> 'd';

    $ch++;  # dies

    my $ch1 = String::Incremental::Char->new( order => ['a'..'c'] );
    my $ch2 = String::Incremental::Char->new( order => ['x'..'z'], upper => $ch1 );

    print "${ch1}${ch2}";  # -> ax

    $ch2++; $ch2++;
    print "${ch1}${ch2}";  # -> az

    $ch2++;
    print "${ch1}${ch2}";  # -> bx

    $ch1++;
    print "${ch1}${ch2}";  # -> cx

    ...

    print "${ch1}${ch2}";  # -> cz
    $ch2++;  # dies


=head1 DESCRIPTION

String::Incremental::Char is ...

=head1 CONSTRUCTORS

=over 4

=item new( %args ) : String::Incremental::Char

%args:

order : Str|ArrayRef

  incrementation rule

upper : String::Incremental::Char

  upper-digit char as String::Incremental::Char instance

=back

=head1 METHODS

=over 4

=item as_string() : Str

returns "current" character.

following two variables are equivalent:

    my $a = $ch->as_string();
    my $b = "$ch";

=item set( $val, \%opts ) : String::Incremental::Char

sets "current" state as $val.

if $opts->{test} is true, "current" state is not update, only returns or dies.

=item increment() : Str

increases position of order and returns its character.

following two operation are equivalent:

    $ch->increment();
    $ch++;

=item decrement() : Str

decreases position of order and returns its character.

following two operation are equivalent:

    $ch->decrement();
    $ch--;

=back


=head1 LICENSE

Copyright (C) issm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=cut
