package Spreadsheet::ParseExcel_XLHTML;

use strict;
use warnings;
use IO::File;
use Spreadsheet::ParseExcel;
use HTML::Entities;

our $VERSION = 0.04;
our @ISA     = 'Spreadsheet::ParseExcel';

=head1 NAME

Spreadsheet::ParseExcel_XLHTML - Parse Excel Spreadsheets using xlhtml

=head1 SYNOPSIS

    use Spreadsheet::ParseExcel_XLHTML;

    my $excel = Spreadsheet::ParseExcel_XLHTML->new;

    my $book = $excel->Parse('/some/excel/file.xls');

    # Cheesy CSV printer...
    for my $sheet (@{$book->{Worksheet}}) {
            print STDERR "Worksheet: ", $sheet->{Name}, "\n";
            for my $i ($sheet->{MinRow}..$sheet->{MaxRow}) {
                    print join ',', map { qq|"$_"| }
                                    map { defined $_ ? $_->Value : "" }
                                    @{$sheet->{Cells}[$i]};
                    print "\n";
            }
    }

    # or...

    use Spreadsheet::ParseExcel_XLHTML qw/-install/;

    # then use the Spreadsheet::ParseExcel API

    my $book  = Spreadsheet::ParseExcel::Workbook->parse('/some/file.xls');
    my $sheet = $book->{Worksheet}[0];

=head1 DESCRIPTION

This module follows the interface of the Spreadsheet::ParseExcel module, except
only the "Value" fields of cells are filled, there is no extra fancy stuff. The
reason I wrote it was to have a faster way to parse Excel spreadsheets in Perl.
This module parses around six times faster according to my own informal
benchmarks then the original Spreadsheet::ParseExcel at the time of writing.

To achieve this, it uses a program called "xlhtml" by Stev Grubb. You can find
it here:

L<http://chicago.sourceforge.net/xlhtml/>

It is also in Debian as the C<xlhtml> package.

Get the latest developer release. Once compiled, it needs to be in the PATH of
your Perl program for this module to work correctly.

You only need to use this module if you have a large volume of big Excel
spreadsheets that you are parsing, or perhaps need to speed up a CGI/mod_perl
handler. Otherwise stick to the Spreadsheet::ParseExcel module.

Now, someday we will have a nice C library with an XS interface, but this is
not someday :)

=head1 COMPATIBILITY

The workbook 'Author' attribute is supported, and the following worksheet
attributes are supported: 'Name', 'MinRow', 'MaxRow', 'MinCol', 'MaxCol'.

In terms of behaviour, there is one other difference which may or may not
affect you. Spreadsheet::ParseExcel will often create
Spreadsheet::ParseExcel::Cell objects with empty or whitespace-filled Value
fields, while this module will only create Cell objects if a value exists;
otherwise the Cells array will contain an C<undef> for that cell.

In other words, don't blindly call C<< $sheet->{Cells}[$i][$j]->Value >>, check
if the cell is defined first.

=head1 OPTIONS

When used with the C<-install> (dash optional) option, it will install its own
"new" and "Parse" methods into the Spreadsheet::ParseExcel namespace, useful if
you want to try using this module along with modules that depend on the
Spreadsheet::ParseExcel module, and/or minimize changes to your code for
compatibility.

=cut

sub import {
	my $pkg    = shift;
	return unless @_;
	my $option = shift;

	$option =~ s/^-//;

	if ($option eq 'install') {
		no strict 'refs';

# Perl will complain about mismatched prototypes and redefined subs, so turn
# off warnings.
		local $SIG{__WARN__} = sub {};

# Trick Spreadsheet::ParseExcel into calling our constructor and blessing the
# object into this package, also overwriteh the Parse method. Evil, I know :)
		*{'Spreadsheet::ParseExcel::new'}   = sub ($;%) {
			shift;
			new (__PACKAGE__, @_);
		};

		*{'Spreadsheet::ParseExcel::Parse'} = \&Parse;

		*{'Spreadsheet::ParseExcel::Workbook::Parse'} = sub {
                    shift;
                    __PACKAGE__->new->Parse(@_);
                };
	}
}

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub Parse {
	my ($self, $file) = @_;

	my $work_book = Spreadsheet::ParseExcel::Workbook->new;
        $file = $self->_getFileByObject($file);
        $work_book->{File} = $file;

	my $stream = new IO::File "xlhtml -xml $file |"
		or die "Could not run xlhtml -xml $file: $!";

# Start parsing the stream, by hand. An XML parsing method here would be either
# too slow or too complex.
	my @work_sheets;
	my ($sheet, $cells);

	while (<$stream>) {
		chomp;
# Some versions of xlhtml have a bug with the NotImplemented tag getting
# translated into entities...
		s/\&lt;NotImplemented\/\&gt;//;

		/<cell \s* row="(\d+)" \s* col="(\d+)">
		 (?:<[^<>]*>)* # Any <B>, <I> etc. tags
		 ( \s* (?:[^<\s]+\s*?)* )\s* # The value itself.
		 <
		/x && do {
			next if $3 =~ /^\s*$/;

			$cells->[$1][$2] = bless {
				_Value => decode_entities($3)
			}, 'Spreadsheet::ParseExcel::Cell';
			next;
		};
		/<page>(\d+)<\/page>/ && do {
			$work_sheets[$1] = $sheet =
				new Spreadsheet::ParseExcel::Worksheet;
			$sheet->{Cells} = $cells = [];
			next;
		};
		/<pagetitle> (?:<[^<>]*>)* ( \s* (?:[^<\s]+\s*?)* )\s*
		</x && do {
			$sheet->{Name} = decode_entities($1); next;
		};
		/<firstrow>(\d+)<\/firstrow>/ && do {
			$sheet->{MinRow} = $1; next;
		};
		/<lastrow>(\d+)<\/lastrow>/ && do {
			$sheet->{MaxRow} = $1; next;
		};
		/<firstcol>(\d+)<\/firstcol>/ && do {
			$sheet->{MinCol} = $1; next;
		};
		/<lastcol>(\d+)<\/lastcol>/ && do {
			$sheet->{MaxCol} = $1; next;
		};
		/<author>([^<]+)<author>/ && do {
			$work_book->{Author} = $1; next;
		}
	}

	$work_book->{SheetCount} = scalar @work_sheets;
	$work_book->{Worksheet} = \@work_sheets;

	return $work_book;
}

sub DESTROY {
	my $self = shift;

	if (exists $self->{DeleteFiles}) {
		unlink @{$self->{DeleteFiles}};
	}
}

sub _getFileByObject {
	my ($self, $file) = @_;

	if (ref $file eq 'SCALAR') {
		my $file_name = "/tmp/ParseExcel_XLHTML_$$.xls";

		push @{$self->{DeleteFiles}}, $file_name;

		my $writer = new IO::File "> $file_name"
			or die "Could not write to $file_name: $!";

		print $writer $$file;

		close $writer;

		return $file_name;
	} elsif (my $type = ref $file) {
		die "Don't know how to parse file objects of type $type";
	}

	return $file;
}

1;

__END__

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=head1 COPYRIGHT & LICENSE

This program is Copyright (c) 2001-2009 by Rafael Kitover. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 ACKNOWLEDGEMENTS

Thanks to the authors of Spreadsheet::ParseExcel and xlhtml for allowing us to
deal with Excel files in the UNIX world.

Thanks to my employer, Gradience, Inc., for allowing me to work on projects
as free software.

=head1 BUGS

are tasty!

=head1 TODO

I'll take suggestions.

=head1 SEE ALSO

L<Spreadsheet::ParseExcel>,
L<xlhtml>

=cut
