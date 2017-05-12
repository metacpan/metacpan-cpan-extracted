package Silki::Formatter::HTMLToWiki::Table;
{
  $Silki::Formatter::HTMLToWiki::Table::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use List::AllUtils qw( all max sum );
use Silki::Formatter::HTMLToWiki::Table::Cell;
use Silki::Types qw( Str ArrayRef Int Bool Maybe );

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

my $row = subtype as ArrayRef ['Silki::Formatter::HTMLToWiki::Table::Cell'];

has _thead_rows => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef [$row],
    default => sub { [] },
    handles => {
        _add_thead_row => 'push',
        _has_thead     => 'count',
    },
    init_arg => undef,
);

has _in_thead => (
    is       => 'rw',
    isa      => Bool,
    default  => 0,
    init_arg => undef,
);

has _tbodies => (
    traits => ['Array'],
    is     => 'ro',
    isa    => ArrayRef [ ArrayRef [$row] ],
    default => sub { [] },
    handles => {
        _add_tbody   => 'push',
        _has_tbodies => 'count',
    },
    init_arg => undef,
);

has _current_tbody => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef [$row],
    default => sub { [] },
    handles => {
        _add_tbody_row       => 'push',
        _reset_current_tbody => 'clear',
    },
    init_arg => undef,
);

has _current_row => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => $row,
    default => sub { [] },
    handles => {
        _add_cell      => 'push',
        _reset_row     => 'clear',
        _row_has_cells => 'count',
    },
    init_arg => undef,
);

has _current_cell => (
    is       => 'rw',
    isa      => 'Silki::Formatter::HTMLToWiki::Table::Cell',
    init_arg => undef,
);

has _max_cell_widths => (
    is       => 'ro',
    isa      => ArrayRef [Int],
    lazy     => 1,
    builder  => '_build_max_cell_widths',
    init_arg => undef,
);

sub _start_thead {
    my $self = shift;

    $self->_set_in_thead(1);
}

sub _end_thead {
    my $self = shift;

    $self->_set_in_thead(0);
}

sub _start_tbody {
    my $self = shift;

    $self->_reset_current_tbody();
}

sub _end_tbody {
    my $self = shift;

    $self->_add_tbody( [ @{ $self->_current_tbody() } ] );
}

sub _start_tr {
    my $self = shift;

    $self->_reset_row();
}

sub _end_tr {
    my $self = shift;

    if ( $self->_in_thead() ) {
        $self->_add_thead_row( [ @{ $self->_current_row() } ] );
    }
    else {
        $self->_add_tbody_row( [ @{ $self->_current_row() } ] );
    }

}

sub _start_th {
    my $self = shift;

    $self->_start_cell(@_);
}

sub _end_th {
    my $self = shift;

    $self->_end_cell(@_);
}

sub _start_td {
    my $self = shift;

    $self->_start_cell(@_);
}

sub _end_td {
    my $self = shift;

    $self->_end_cell(@_);
}

sub _start_cell {
    my $self = shift;
    my $node = shift;

    $self->_set_current_cell(
        Silki::Formatter::HTMLToWiki::Table::Cell->new(
            colspan   => $node->attr('colspan') || 1,
            alignment => $node->attr('align')   || 'left',
            is_header_cell => $node->tag() eq 'th' ? 1 : 0,
        )
    );
}

sub _end_cell {
    my $self = shift;

    $self->_add_cell( $self->_current_cell() );
}

sub finalize {
    my $self = shift;

    unless ( $self->_has_tbodies() ) {
        $self->_end_tbody();
    }

    unless ( $self->_has_thead() ) {
        my $tbody = $self->_tbodies()->[0];

        while ( my $row = shift @{$tbody} ) {

            # If all the cells in a row are <th> cells, _or_ all the content
            # in each cell is bold, it's a header row.
            if (   ( all { $_->is_header_cell() } @{$row} )
                || ( all { $_->content() =~ /^\s*\*\*.+\*\*\s*$/ } @{$row} ) )
            {
                for my $cell ( @{$row} ) {
                    my $content = $cell->content();
                    $content =~ s/^(\s*)\*\*(.+)\*\*(\s*)$/$1$2$3/;
                    $cell->set_content($content);
                }

                $self->_add_thead_row($row);
            }
            else {
                unshift @{$tbody}, $row;
                last;
            }
        }
    }
}

sub as_markdown {
    my $self = shift;

    my @dashes;
    for my $width ( @{ $self->_max_cell_widths() } ) {
        push @dashes, $width + 4;
    }

    my @rows;

    my $divider = q{+};
    $divider .= join q{+}, map { q{-} x $_ } @dashes;
    $divider .= q{+};

    if ( $self->_has_thead() ) {
        push @rows, $divider;

        push @rows,
            map { $self->_markdown_for_row($_) } @{ $self->_thead_rows() };

        push @rows, $divider;
    }

    my @tbodies = @{ $self->_tbodies() };
    for my $tbody (@tbodies) {
        push @rows, map { $self->_markdown_for_row($_) } @{$tbody};
        push @rows, q{}
            if $tbody ne $tbodies[-1];
    }

    push @rows, $divider
        if $self->_has_thead();

    return join q{}, map { $_ . "\n" } @rows;
}

sub _markdown_for_row {
    my $self = shift;
    my $row  = shift;

    my @widths = @{ $self->_max_cell_widths() };

    my $md = q{|};

    my @cells;
    for my $cell ( @{$row} ) {

        # A multi-column cell needs to be as wide as all the columns it spans
        my $width = sum( splice @widths, 0, $cell->colspan() );

        $md .= $cell->formatted_content($width);

        $md .= q{|} x $cell->colspan();
    }

    return $md;
}

sub _build_max_cell_widths {
    my $self = shift;

    my @widths;
    for my $row ( $self->_all_rows() ) {
        for my $x ( 0 .. $#{$row} ) {
            $widths[$x] ||= 0;
            $widths[$x] = max( $widths[$x], length $row->[$x]->content() );
        }
    }

    return \@widths;
}

sub _all_rows {
    my $self = shift;

    return @{ $self->_thead_rows() }, map { @{$_} } @{ $self->_tbodies() };
}

sub print {
    my $self = shift;

    $self->_current_cell()->append_content( $_[0] );
}

__PACKAGE__->meta()->make_immutable();

1;
