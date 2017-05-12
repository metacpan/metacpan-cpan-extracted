package Spreadsheet::Simple::Reader::Excel;
# ABSTRACT: Reader class for *.xls files

use Moose;
use namespace::autoclean;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:DHARDISON';

use Spreadsheet::ParseExcel;

use Spreadsheet::Simple::Document;
use Spreadsheet::Simple::Sheet;
use Spreadsheet::Simple::Row;
use Spreadsheet::Simple::Cell;


with 'Spreadsheet::Simple::Role::Reader';

has 'parser' => (
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        'parse'        => 'Parse',
        'color_to_rgb' => 'ColorIdxToRGB',
    },
);

sub _build_parser { Spreadsheet::ParseExcel->new }

sub read_file {
	my ($self, $file) = @_;

	(-e $file)
	    || confess "File ($file) does not exist";

	my $wb = $self->parse("$file");

	return unless defined $wb;

	return $self->map_document($wb);
}

sub map_document {
	my ($self, $wb) = @_;

	return Spreadsheet::Simple::Document->new(
		sheets => [
			map { $self->map_sheet($_) } @{ $wb->{Worksheet} }
		],
	);
}

sub map_sheet {
	my ($self, $ws) = @_;

	return Spreadsheet::Simple::Sheet->new(
		name => $ws->{Name},
		rows => [
			map { $self->map_row($_) } @{ $ws->{Cells} }
		],
	);

}

sub map_row {
	my ($self, $row) = @_;

	return Spreadsheet::Simple::Row->new(
		cells => [
			map { $self->map_cell($_) } @{ $row }
		],
	);
}

sub map_cell {
	my ($self, $cell) = @_;

	return Spreadsheet::Simple::Cell->new(
		value => eval { $cell->value } || undef,
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Reader::Excel - Reader class for *.xls files

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
