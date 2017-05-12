package Term::Vspark;

use strict;
use warnings;
use Carp qw{ croak };
use utf8;

use Exporter::Shiny qw/show_graph vspark/;

our $VERSION = 0.34;

sub _bar {
    my (%args) = @_;

    my $value   = $args{value};
    my $max     = $args{max};
    my $columns = $args{columns};
    my $char    = $args{char};

    my @char_list = $char
        ? ($char)
        : (qw{ ▏ ▎ ▍ ▌ ▋ ▊ ▉ █});

    # calculate the length of the bar
    my $length = $value * $columns / $max; # length of the bar
    $length = $columns if $length > $columns;

    # empty $bar
    my $bar = '';

    # build integer portion of the bar
    my $integer = int $length;
    $bar .= $char_list[-1] x $integer;

    # build decimal portion of the bar
    my $decimal = $length - $integer;
    if ($decimal > 0) {
        my $index = int scalar @char_list * $decimal;
        $bar .= $char_list[$index];
    }

    return $bar;
}

sub vspark {
    my %args = @_;

    croak 'values is not an ArrayRef'
        if ref $args{'values'} ne 'ARRAY';

    croak 'labels is not an ArrayRef'
        if $args{'labels'} && ref $args{'labels'} ne 'ARRAY';

    my $max     = $args{max};
    my $columns = _term_width($args{columns});
    my @labels  = @{ $args{labels} || [] };
    my @values  = @{ $args{values} };
    my $char    = $args{char};

    croak 'the number of labels and values must be equal'
        if $args{labels} && scalar @labels != scalar @values;

    $max          //= _max_value(@values);
    my $label_width = _max_label_width(@labels);
    my $bar_width   = $columns - $label_width;
    my $graph       = q{};

    for my $value (@values) {
        my $label = shift @labels;
        my $bar   = _bar(
            value   => $value, 
            max     => $max, 
            columns => $bar_width, 
            char    => $char,
        );

        $graph .= sprintf("%${label_width}s", " $label ") if defined $label;
        $graph .= $bar . "\n";
    }

    return $graph;
}

# for backwards compatibility
sub show_graph { vspark(@_) }

sub _term_width {
    my $columns = shift;
    return $columns if $columns && $columns ne 'max';

    require Term::ReadKey;
    my ($cols) = Term::ReadKey::GetTerminalSize(*STDOUT);
    return 80    if !$cols;
    return $cols if  $columns && $columns eq 'max';
    return 80    if $cols > 80;
    return $cols;
}

sub _max_value {
    my @values = @_;
    my @sorted = sort @values;
    return 0 unless @sorted;
    return $sorted[-1];
}

sub _max_label_width {
    my @labels = @_;

    return 0 if scalar @labels == 0;

    my @lengths = sort map { length $_ } @labels;
    return $lengths[-1] + 2; # + 2 because of 1 space before and after label
}

1;
__END__

=encoding utf-8

=head1 NAME

Term::Vspark - Displays a graph in the terminal

=head1 SYNOPSIS

    use Term::Vspark qw/vspark/;
    binmode STDOUT, ':encoding(UTF-8)';
    print vspark(
        values  => [0,1,2,3,4,5], # required
        labels  => [0,1,2,3,4,5],
        max     => 7,   # max value
        columns => 80,  # width of the graph including labels
    );

    # The output looks like this:
    # 0 
    # 1 ███████████
    # 2 ██████████████████████
    # 3 █████████████████████████████████
    # 4 ████████████████████████████████████████████
    # 5 ███████████████████████████████████████████████████████


=head1 DESCRIPTION

This module displays beautiful graphs in the terminal.  It is a companion to
Term::Spark but instead of displaying normal sparklines it displays "vertical"
sparklines.

=head1 METHODS

=head2 vspark(%params)

show_graph() returns a string.

The 'values' parameter should be an ArrayRef of numbers.   This is required.

The 'labels' parameter should be an ArrayRef of strings.  This is optional.
Each label will be used with the corresponding value.

The 'max' parameter is the maximum value of the graph.  Without this parameter
you cannot compare graphs because the scaling changes depending on the data.
This parameter is optional.

The 'columns' parameter is the maximum width of the graph.  This defaults to
your terminal width or 80 characters -- whichever is smaller.  Set 'columns' to
'max' if you want to use the full width of your terminal.

=head1 AUTHOR

Eric Johnson (kablamo)

Gil Gonçalves <lurst@cpan.org> (original author)

=head1 SEE ALSO

L<Term::Spark>

