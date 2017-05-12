package Term::GnuScreen::WindowArrayLike;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my $windows = qx{ screen -Q windows } or die "Your screen doesn't support -Q";

    bless {
        windows => [split "\x20\x20", $windows],
    } => $class;
}

sub windows   { $_[0]->{windows}   }
sub start_number {
    my $self = $_[0];

    if ($_[1]) {
        $self->{start_number} = $_[1];
    }elsif ( !defined $self->{start_number} ) {
        $self->{start_number} = _current_window_number();
    }

    return $self->{start_number};
}

sub _current_window_number {
    my $win = qx{ screen -Q number };
    $win =~ /^(\d+)/ or die 'current window number not found';
    return $1;
}

sub window_numbers_more_than_start {
    my $self = shift;
    my @window_numbers_more_than_start;
    my @windows = @{$self->windows};

    for my $i (0 .. @windows - 1) {
        my ($num) = $windows[$i] =~ /^(\d+)/;
        if ($self->start_number < $num) {
            push @window_numbers_more_than_start,$num;
        }
    }
    \@window_numbers_more_than_start;
}

sub push {
    my $self = shift;
    $self->windows->[-1] =~ /^(\d+)/ or die 'last window number not found';

    my $pushed_number = $1 + 1;
    qx{ screen -X screen $pushed_number };
}

sub insert {
    my $self = shift;
    my $target_number = shift;
    my $start_number;

    if (defined $target_number) {
        $start_number = $target_number - 1;
        $self->start_number($start_number);
    }else{
        $target_number = ($self->start_number + 1);
    }

    for my $win_number (reverse @{$self->window_numbers_more_than_start} ) {
        qx{ screen -X eval 'select $win_number' 'number +1' };
    }

    qx{ screen -X screen $target_number };
}

sub compact {
    my $self = shift;
    my @windows = @{$self->windows};

    for my $i (0 .. @windows - 1) {
        my ($number) = $windows[$i] =~ /^(\d+)/;
        qx{ screen -X eval 'select $number' 'number $i' };
    }

    my $start_number = $self->start_number;
    qx{ screen -X select $start_number };
}



1;
__END__

=encoding utf-8

=head1 NAME

Term::GnuScreen::WindowArrayLike - window list is operated like Array

=head1 SYNOPSIS

    use Term::GnuScreen::WindowArrayLike;
    my $screen = Term::GnuScreen::WindowArrayLike->new;
    $screen->insert;
    $screen->insert(3);
    $screen->push;
    $screen->compact;

    # .screenrc
    # push is [C-t l p]
    escape ^Tt
    bind  l command -c window_array_like
    bind  -c window_array_like  p exec perl -e 'use Term::GnuScreen::WindowArrayLike; Term::GnuScreen::WindowArrayLike->new->push'

=head1 DESCRIPTION

Term::GnuScreen::WindowArrayLike operates screen window list using Array method.

=head1 METHODS

=head2 new(\%opts)

Constructor.

=head2 push

Add window to the end of a list. 

=head2 insert($window_number)

A window is inserted in the given number.
Before inserting window, as for window number not less than the given number, 1 is added.

The current window number becomes a default value when not giving a number. 

=head2 compact

Reassign sequential numbers.

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass@cpan.orgE<gt>

=cut

