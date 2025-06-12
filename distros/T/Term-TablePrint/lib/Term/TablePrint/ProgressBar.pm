package Term::TablePrint::ProgressBar;

use strict;
use warnings;
use 5.16.0;

our $VERSION = '0.173';

use Term::Choose::Constants qw( EXTRA_W );
use Term::Choose::Screen    qw( clear_screen clear_to_end_of_line );
use Term::Choose::Util      qw( get_term_width );


sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    $self->{show_progress_bar} //= 1;
    return $self;
}

sub set_progress_bar {
    my ( $self ) = @_;
    my $term_w = get_term_width() + EXTRA_W;
    $self->{fmt} = "\rComputing: %3d%% [%s]";
    if ( $term_w < 25 ) {
        $self->{short_print} = 1;
        $self->{bar_w} = $term_w
    }
    else {
        $self->{short_print} = 0;
        $self->{bar_w} = $term_w - length( sprintf $self->{fmt}, 100, '' ) + 1; # +1: lenght("\r") == 1
    }
    $self->{step} = int( $self->{total} / $self->{bar_w} || 1 );
    $self->{count} //= 0;
    $self->{next_update} ||= $self->{step};
    if ( ! $self->{count} ) {
        print clear_screen;
        print "\rComputing: ";
    }
    return;
}


sub update_progress_bar {
    my ( $self ) = @_;
    my $multi = int( $self->{count} / ( $self->{total} / $self->{bar_w} ) );
    if ( $self->{short_print} ) {
        print "\r", clear_to_end_of_line;
        print( ( '=' x $multi ) . ( ' ' x ( $self->{bar_w} - $multi ) ) );
    }
    else {
        printf $self->{fmt}, ( $self->{count} / $self->{total} * 100 ), ( '=' x $multi ) . ( ' ' x ( $self->{bar_w} - $multi ) );
    }
    $self->{next_update} += $self->{step};
}





=pod

=encoding UTF-8

=head1 NAME

Term::TablePrint::ProgressBar - Show a progress bar.

=head1 VERSION

Version 0.173

=cut

=head1 DESCRIPTION

Provides the progress bar used in C<Term::TablePrint>.

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2025 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut



1;

__END__
