package Term::TablePrint::ProgressBar;

use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.165';

use Term::Choose::Constants qw( WIDTH_CURSOR );
use Term::Choose::Screen    qw( clear_screen );
use Term::Choose::Util      qw( get_term_width );


sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    $self->{show_progress_bar} //= 1;
    if ( $self->{show_progress_bar} ) {
        print clear_screen;
        print "\rComputing: ";
    }
    return $self;
}


sub set_progress_bar {
    my ( $self ) = @_;
    my $term_w = get_term_width();
    if ( $^O ne 'MSWin32' && $^O ne 'cygwin' ) {
        $term_w += WIDTH_CURSOR;
    }
    $self->{fmt} = "\rComputing: %3d%% [%s]";
    $self->{short_print} = $term_w < 25 ? 1 : 0;
    $self->{bar_w} = $term_w - length( sprintf $self->{fmt}, 100, '' ) + 1; # +1: lenght("\r") == 1
    $self->{step} = int( $self->{total} / $self->{bar_w} || 1 );
    $self->{count} //= 0;
    $self->{next_update} ||= $self->{step};
    return;
}


sub update_progress_bar {
    my ( $self ) = @_;
    my $multi = int( $self->{count} / ( $self->{total} / $self->{bar_w} ) ) || 1;
    if ( $self->{short_print} ) {
        print "\r" . ( '=' x $multi ) . ( ' ' x $self->{bar_w} - $multi );
    }
    else {
        printf $self->{fmt}, ( $self->{count} / $self->{total} * 100 ), ( '=' x $multi ) . ( ' ' x ( $self->{bar_w} - $multi ) );
    }
    $self->{next_update} = $self->{next_update} + $self->{step};
}





=pod

=encoding UTF-8

=head1 NAME

Term::TablePrint::ProgressBar - Show a progress bar.

=head1 VERSION

Version 0.165

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
