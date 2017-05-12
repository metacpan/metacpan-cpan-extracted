package Term::FormatColumns;
# ABSTRACT: Format lists of data into columns across the terminal's width
$Term::FormatColumns::VERSION = '0.007';
use strict;
use warnings;

use Sub::Exporter -setup => [
    exports => (
        qw/format_columns format_columns_for_fh format_columns_for_width/,
    ),
];

use Term::ReadKey qw( GetTerminalSize );
use List::Util qw( max );
use List::MoreUtils qw( part each_arrayref );
use POSIX qw( ceil );
use Symbol qw(qualify_to_ref);

# Find the length of a string as displayed on the terminal, ignoring any ANSI
# escape sequences.
sub _term_length {
    my ( $str ) = @_;
    $str =~ s/\x1b\[[0-9;]+m//g;
    return length $str;
}


sub format_columns {
    return format_columns_for_fh( \*STDOUT, @_ );
}


sub format_columns_for_fh(*@) {
    my $fh = qualify_to_ref( shift, caller );
    my @data = @_;

    # If we're not attached to a terminal, one column, seperated by newlines
    if ( !-t $fh ) {
        return join "\n", @data, '';
    }

    # We're attached to a terminal, print column-wise alphabetically to fit the
    # terminal width
    my ( $term_width, undef, undef, undef ) = GetTerminalSize();
    return format_columns_for_width( $term_width, @data );
}


sub format_columns_for_width {
    my ( $term_width, @data ) = @_;
    my $max_width = max map { _term_length( $_ ) } @data;
    $max_width += 2; # make sure at least two spaces between data values
    my $columns = int( $term_width / $max_width );
    if ( $columns <= 1 ) {
        # Only one column, let the terminal handle things
        return join "\n", @data, ''; # Add a \n to the end
    }
    my $output = '';
    my $column_width = int( $term_width / $columns );
    my $rows = ceil( @data / $columns );
    push @data, ('') x ($rows * $columns - @data); # Pad data with empty strings
    my @index = part { int( $_ / $rows ) } 0..$#data;
    my $iter = each_arrayref @index;
    while ( my @row_vals = $iter->() ) {
        my @cells = map { $data[$_] } @row_vals;
        my $last_cell = pop @cells;
        for (@cells) {
            my $length = _term_length( $_ );
            $output .= $_;
            $output .= ' ' x ($column_width - $length);
        }
        $output .= $last_cell . "\n";
    }
    return $output;
}

1;

__END__

=pod

=head1 NAME

Term::FormatColumns - Format lists of data into columns across the terminal's width

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Term::FormatColumns qw( format_columns );
    my @list = 0..1000;
    print format_columns @list;

=head1 DESCRIPTION

This module will take a list and format it into columns that stretch across the
current terminal's width, much like the output of ls(1).

If the filehandle is not attached to a tty, will simply write one column of output
(again, like ls(1)).

=head1 SUBROUTINES

=head2 format_columns

    my $string = format_columns @array;

Format the list of data for STDOUT. Returns a single string formatted and ready for output.

=head2 format_columns_for_fh

    my $string = format_columns_for_fh $fh, @array;
    my $string = format_columns_for_fh STDOUT, @array;

Format the given data for the given filehandle. If the filehandle is attached to a tty,
will get the tty's width to determine how to format the data.

=head2 format_columns_for_width

    my $string = format_columns_for_width 78, @array;

Format the given data for the given width. This allows you to use this module without
being attached to a known/knowable terminal.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Marius Gavrilescu

Marius Gavrilescu <marius@ieval.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
