package PerlIO::via::csv;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use Spreadsheet::Read;   # I can't get this to `require' in OPEN
use Text::CSV;   # ::Encoded ?


BEGIN {
    # class methods
    my $sheet = 1;
    sub sheet {
        $sheet = $_[1] if defined $_[1];
        return $sheet;
    }
    my $debug = 0;
    sub debug {
        $debug = $_[1] if defined $_[1];
        return $debug;
    }

    sub import {
        my $pkg = shift;
        my %args = @_;

        # class methods passed to C<use>
        for (qw(sheet)) {
            $pkg->$_($args{$_}) if exists $args{$_};
        }

        # args to Spreadsheet::Read or ParseExcel?
    }

    # function
    sub damn (@) {
        require Carp;
        if (__PACKAGE__->debug) {
            Carp::confess(join("\n", @_));
        }
        else {
            Carp::croak(join("\n", @_));
        }
    }
}


### PerlIO::via interface

sub PUSHED {
    my ($pkg, $mode, $fh) = @_;

    bless {
        row  => 1,
        col  => 1,
        # meta => {},
        rows => [],
    }, $pkg;
}

sub OPEN {
    my ($self, $path, $mode, $fh) = @_;

    my $ref = Spreadsheet::Read::ReadData($path);
    __PACKAGE__->sheet(_lookup_sheet_number($ref, $path));
    $self->{rows} = [ Spreadsheet::Read::rows($ref->[__PACKAGE__->sheet]) ];

    return 1;
}
# need FDOPEN and SYSOPEN?

sub FILL {
    my ($self, $fh) = @_;

    my $buf = undef;
    while (my $row = $self->read_row()) {
        $buf .= $row . "\n";
        last if defined $/;
    }
    return $buf;
}

{
    my $csv = Text::CSV->new({binary => 1});

    sub read_row {
        my ($self) = @_;
        my $buf = undef;

        my $row_index = $self->{row} - 1;
        my $rows = $self->{rows};

        if ($row_index < @$rows) {
            my @cols = @{ $rows->[$row_index] };
            if ($csv->combine(@cols)) {
                $buf = $csv->string;
            }

            # on to the next row
            $self->{row}++;
            $self->{col} = 1;
        }

        return $buf;
    }
}

sub _lookup_sheet_number {
    my ($ref, $path) = @_;

    my $sheet = __PACKAGE__->sheet;

    if ($sheet =~ /^\d+$/) {
        my $max = $ref->[0]{sheets};
        if ($sheet < 1 or $sheet > $max) {
            damn "There's no worksheet '$sheet' in '$path' (numbers 1 .. $max)";
        }
    }
    else {
        # try to lookup sheet by name
        # (does it have to be UCS2 for Excel?)
        if (exists $ref->[0]{sheet}{$sheet}) {
            __PACKAGE__->sheet($ref->[0]{sheet}{$sheet});
        }
        else {
            damn "There's no worksheet '$sheet' in '$path'";
        }
    }

    return __PACKAGE__->sheet;
}

1;
__END__

=head1 NAME

PerlIO::via::csv - PerlIO layer to convert between Excel and CSV

=head1 SYNOPSIS

  use PerlIO::via::csv sheet => 2;
  open my $fh, '<:via(csv)', 'file.xls'
    or die "Can't open file.xls: $!";

=head1 DESCRIPTION

This module implements a PerlIO layer that converts a spreadsheet
(anything readable by Spreadsheet::Read, like an Excel file)
into comma-separated values (CSV) format. It is currently readonly.

The spreadsheet is emulated as a stream of bytes where each cell is a byte.
So C<$line = readline $fh> might put C<1,2.3,foo> into $line.
Only one of the sheets in a multi-sheet spreadsheet is read,
and sheet numbers start at 1. You can also use sheet names
(see L</"Class methods">).

Currently that's about it, so you're probably better off using one of the
xsl2csv utilities available elsewhere (see L</"SEE ALSO">).
I hope to support write and append modes (Spreadsheet::ParseExcel::SaveParser?)
and filehandle methods like seek and tell. Suggestions welcome.

=head1 INTERFACE

You can affect which worksheet to read with the C<sheet> class method,
which can also be set when you C<use> the module.

=head2 Class methods

=over 4

=item sheet

Specify which worksheet to read from. The sheet that is set when you open
the file will be the one read from. Use it like this:

  use PerlIO::via::csv sheet => 3;

or

  use PerlIO::via::csv;
  PerlIO::via::csv->sheet(3);

Tip: try using the name of the worksheet instead of its number
(which starts at 1).

If you want to read multiple sheets, set a new sheet before reopening
the file.

Note: I was thinking of reading all worksheets by default; not sure
if that makes sense, though.

=back

=head1 TODO

=over 4

=item Dates are broken. Not sure if that's my problem or Tux's.

=item There are probably problems with encoding.

=item Not sure I like how sheets are handled.

=item Other I/O operations like seek, tell, unread.

=item Writing files.

=back

=head1 SEE ALSO

L<Spreadsheet::Read|Spreadsheet::Read> (and xls2csv in the samples directory)

L<Spreadsheet::ParseExcel|Spreadsheet::ParseExcel> (and xls2csv.pl in the
samples directory)

L<http://search.cpan.org/~ken/xls2csv/script/xls2csv>

L<Text::CSV|Text::CSV>

=head1 AUTHORS

Scott Lanning E<lt>slanning@cpan.orgE<gt>.

=head1 LICENSE

Copyright 2009, Scott Lanning.
This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=for comment
42

=cut
