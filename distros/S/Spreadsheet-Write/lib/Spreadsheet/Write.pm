=head1 NAME

Spreadsheet::Write - Writer for spreadsheet files (CSV, XLS, XLSX, ...)

=head1 SYNOPSIS

Basic usage:

    use Spreadsheet::Write;

    my $sp=Spreadsheet::Write->new(file => 'test.xlsx');

    $sp->addrow('hello','world');

    $sp->close();

More possibilities:

    use Spreadsheet::Write;

    my $sp=Spreadsheet::Write->new(
        file    => $ARGV[0],        # eg. test.xls, test.xlsx, or test.csv
        sheet   => 'Test Data',
        styles  => {
            money   => {
                format      => '$#,##0.00;-$#,##0.00',
            },
            bright  => {
                font_weight => 'bold',
                font_color  => 'blue',
                font_style  => 'italic',
            },
        },
    );

    $sp->addrow(
        'col1',
        { content => [ 'col2', 'col3', 'col4' ], style => 'bright' },
        { content => 'col5', bg_color => 'gray' },
        'col6',
    );

    $sp->freeze(1,0);

    $sp->addrow(
        { content => [ 1, 1.23, 123.45, -234.56 ], style => 'money' },
    );

    my @data=(
        [ qw(1 2 3 4) ],
        [ qw(a s d f) ],
        [ qw(z x c v b) ],
        # ...
    );

    foreach my $row (@data) {
        $sp->addrow({ style => 'ntext', content => $row });
    }

    $sp->close();

=head1 DESCRIPTION

C<Spreadsheet::Write> writes files in CSV, XLS (Microsoft Excel 97),
XLSX (Microsoft Excel 2007), and other formats if their drivers
exist. It is especially suitable for building various dumps and reports
where rows are built in sequence, one after another.

The same calling format and options can be used with any output file
format. Unsupported options are ignored where possible allowing for easy
run-time selection of the output format by file name.

=head1 METHODS

=cut

###############################################################################
package Spreadsheet::Write;

require 5.008_009;

use strict;
use IO::File;

our $VERSION='1.03';

sub version {
    return $VERSION;
}

###############################################################################

=head2 new ()

    $spreadsheet = Spreadsheet::Write->new(
        file            => 'table.xls',
        styles          => {
            mynumber        => '#,##0.00',
        }
    );

Creates a new spreadsheet object. It takes a list of options. The
following are valid:

    file        filename of the new spreadsheet or an IO handle (mandatory)
    encoding    encoding of output file (optional, csv format only)
    format      format of spreadsheet - 'csv', 'xls', 'xlsx', or 'auto' (default)
    sheet       Sheet name (optional, not supported by some formats)
    styles      Defines cell formatting shortcuts (optional)

If file format is 'auto' (or omitted), the format is guessed from the
filename extention. If impossible to guess the format defaults to 'csv'.

An IO-like handle can be given as 'file' argument (IO::File, IO::Scalar,
etc). In this case the format argument is mandatory.

Default styles are:
    header => {
        font_weight     => 'bold',
        type            => 'string',
    },
    ntext => {
        format          => '@',
        type            => 'string',
    },
    money => {
        format          => '$#,##0.00;-$#,##0.00',
    },

=cut

sub new(@) {
    my $proto = shift;
    my $args=ref($_[0]) eq 'HASH' ? $_[0] : {@_};

    my $filename=$args->{'file'} || $args->{'filename'} || die 'No file given';

    my $format=$args->{'format'} || 'auto';
    if($format eq 'auto') {
        die "Need a 'format' argument for IO-handle in 'file'" if ref $filename;
        $format=($filename=~/.*\.(.+?)$/) ? lc($1) : 'csv';
    }

    # Some commonly used styles
    #
    my %parm=%{$args};
    $parm{'styles'}->{'ntext'}||={
        format          => '@',
        type            => 'string',
    };
    $parm{'styles'}->{'header'}||={
        font_weight     => 'bold',
        type            => 'string',
    };
    $parm{'styles'}->{'money'}||={
        format          => '$#,##0.00;-$#,##0.00',
    };

    # CPAN ownership of Spreadsheet::Write::CSV and a number of other
    # simpler names belongs to Toby Inkman, with Spreadsheet::Wright
    # clone.
    #
    my $implementation={
        csv     => 'WriteCSV',
        xls     => 'WriteXLS',
        xlsx    => 'WriteXLSX',
    }->{lc $format};

    $implementation ||
        die "Format $format is not supported";

    $implementation=join('::',(__PACKAGE__,$implementation));

    eval "use $implementation;";
    die $@ if $@;

    return $implementation->new(%parm);
}

###############################################################################

sub DESTROY {
    my $self=shift;
    ### print STDERR "DESTROY: ".ref($self)."\n";
    $self->close();
}

###############################################################################

sub error {
    my $self=shift;
    return $self->{'_ERROR'};
}

###############################################################################

sub _open($) {
    my $self=shift;

    $self->{'_CLOSED'} && die "Can't reuse a closed spreadsheet";

    my $fh=$self->{'_FH'};

    if(!$fh) {
        my $filename=$self->{'_FILENAME'} || return undef;

        if(ref($filename)) {
            $fh=$filename;
            $self->{'_EXT_HANDLE'}=1;
        }
        else {
            $fh=new IO::File;
            $fh->open($filename,"w") || die "Can't open file $filename for writing: $!";
            $fh->binmode(':utf8');
        }
    }

    $self->{'_FH'}=$fh;

    return $self->_prepare;
}

###############################################################################

sub _prepare {
    # no-op by default
}

###############################################################################

=head2 addrow(arg1,arg2,...)

Adds a row into the spreadsheet. Takes arbitrary number of
arguments. Arguments represent cell values and may be strings or hash
references. If an argument is a hash reference, it takes the following
structure:

    content         value to put into the cell
    style           formatting style, as defined in new(), scalar or array-ref
    type            type of the content (defaults to 'auto')
    format          number format (see Spreadsheet::WriteExcel for details)
    font_weight     weight of font. Only valid value is 'bold'
    font_style      style of font. Only valid value is 'italic'
    font_decoration 'underline' or 'strikeout' (or both, space separated)
    font_face       font of column; default is 'Arial'
    font_color      color of font (see Spreadsheet::WriteExcel for color values)
    font_size       size of font
    bg_color        color of background (see Spreadsheet::WriteExcel for color values)
    align           alignment
    valign          vertical alignment
    width           column width, excel units (only makes sense once per column)
    height          row height, excel units (only makes sense once per row)
    comment         hidden comment for the cell, where supported

Styles can be used to assign default values for any of these formatting
parameters thus allowing easy global changes. Other parameters specified
override style definitions.

Example:

    my $sp=Spreadsheet::Write->new(
        file        => 'employees.xlsx',
        styles      => {
            header => { font_weight => 'bold' },
        },
    );
    $sp->addrow(
        { content => 'First Name', font_weight => 'bold' },
        { content => 'Last Name', font_weight => 'bold' },
        { content => 'Age', style => 'header' },
    );
    $sp->addrow("John","Doe",34);
    $sp->addrow("Susan","Smith",28);

Note that in this example all header cells will have identical
formatting even though some use direct formats and one uses
style.

If you want to store text that looks like a number you might want to use
{ type => 'string', format => '@' } arguments. By default the type detection is automatic,
as done by for instance L<Spreadsheet::WriteExcel> write() method.

It is also possible to supply an array reference in the 'content'
parameter of the extended format. It means to use the same formatting
for as many cells as there are elements in this array. Useful for
creating header rows. For instance, the above example can be rewritten
as:

    $sp->addrow(
        { style => 'header',
          content => [ 'First Name','Last Name','Age' ],
        }
    );

Not all styling options are supported in all formats. Where they are not
supported they are safely ignored.

=cut

sub addrow (@) {
    my $self = shift;
    $self->_open() || return undef;

    my @cells;

    foreach my $item (@_) {
        if (ref $item eq 'HASH') {
            if (ref $item->{'content'} eq 'ARRAY') {
                foreach my $i (@{ $item->{'content'} }) {
                    my %newitem = %$item;
                    $newitem{'content'} = $i;
                    push @cells, \%newitem;
                }
            }
            else {
                push @cells, $item;
            }
        }
        else {
            push @cells, { content => $item };
        }
    }

    return $self->_add_prepared_row(@cells);
}

###############################################################################

=head2 addrows([$cell1A,$cell1B,...],[$cell2A,$cell2B,...],...)

Shortcut for adding multiple rows.

Each argument is an arrayref representing a row.

Any argument that is not a reference (i.e. a scalar) is taken to be the
title of a new worksheet.

=cut

sub addrows (@) {
	my $self=shift;

	foreach my $row (@_) {
		if (ref $row eq 'ARRAY') {
			$self->addrow(@$row);
		}
		elsif (!ref $row) {
			$self->addsheet($row);
		}
		else {
			warn "Unsupported row format '".ref($row)."'";
		}
	}

	return $self;
}

###############################################################################

=head2 addsheet(name)

Adds a new sheet into the document and makes it active. Subsequent
addrow() calls will add rows to that new sheet.

For CSV format this call is NOT ignored, but produces a fatal error
currently.

=cut

sub addsheet ($$) {
    die (((caller(0))[3])." - pure virtual method called");
}

###############################################################################

=head2 freeze($row, $col, $top_row, $left_col))

Sets a freeze-pane at the given position, equivalent to Spreadsheet::WriteExcel->freeze_panes().
Ignored for CSV files.

=cut

sub freeze (@) {
    return shift;
}

###############################################################################

=head2 close ()

Finalizes the spreadsheet and closes the file. It is a good idea
to call this method explicitly instead of relying on perl's garbage
collector because for many formats the file may be in an unusable
state until this method is called.

Once a spreadsheet is closed, calls to addrow() will fail.

=cut

sub close {
    ### print STDERR "0: ".join("/",map { $_ || 'UNDEF' } caller(0))."\n";
    ### print STDERR "1: ".join("/",map { $_ || 'UNDEF' } caller(1))."\n";
    ### print STDERR "2: ".join("/",map { $_ || 'UNDEF' } caller(2))."\n";
    ### print STDERR "3: ".join("/",map { $_ || 'UNDEF' } caller(3))."\n";
    die (((caller(0))[3])." - pure virtual method called");
}

###############################################################################

1;
__END__

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Written by Nick Eremeev <nick.eremeev@gmail.com>; Andrew Maltsev <am@ejelta.com>;
L<https://ejelta.com/>

Multiple backends implementation and other patches by Toby Inkster
<tobyink@cpan.org> (see also a full fork at L<Spreadsheet::Wright>).
