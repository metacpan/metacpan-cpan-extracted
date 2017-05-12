package Spreadsheet::Simple;
{
  $Spreadsheet::Simple::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::AUTHORITY = 'cpan:DHARDISON';
}
# ABSTRACT: Simple interface to spreadsheet files

use Moose;
use namespace::autoclean;

use Spreadsheet::Simple::Types;



has 'format' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Excel',
);


has 'reader' => (
    is         => 'ro',
    does       => 'Spreadsheet::Simple::Role::Reader',
    lazy_build => 1,
    handles    => ['read_file'],
);


has 'writer' => (
    is         => 'ro',
    does       => 'Spreadsheet::Simple::Role::Writer',
    lazy_build => 1,
    handles    => ['write_file'],
);

sub _build_reader {
    my ($self) = @_;
    my $fmt = $self->format;

    Class::MOP::load_class("Spreadsheet::Simple::Reader::$fmt");

    return "Spreadsheet::Simple::Reader::$fmt"->new;
}

sub _build_writer {
    my ($self) = @_;
    my $fmt = $self->format;

    Class::MOP::load_class("Spreadsheet::Simple::Writer::$fmt");

    return "Spreadsheet::Simple::Writer::$fmt"->new;
}



sub new_document {
    my ($self, @args) = @_;

    Class::MOP::load_class("Spreadsheet::Simple::Document");

    Spreadsheet::Simple::Document->new( @args );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple - Simple interface to spreadsheet files

=head1 SYNOPSIS

    use Spreadsheet::Simple;

    my $s     = Spreadsheet::Simple->new(format => 'Excel');
    my $doc   = $s->read_file($file);
    my $sheet = $doc->get_sheet_by_name('sheet1');

    $sheet->get_cell(0, 0)->value eq 'name'; # A1
    $sheet->get_cell(1, 0)->value eq 'Fred'; # A2

    # $cell->color -- TODO

=head1 METHODS

=head2 read_file($file)

This method returns a new L<Spreadsheet::Simple::Document> object.

=head2 write_file($file, $doc)

TODO. Unimplemented.

=head2 new_document(sheets => ArrayRef[ Spreadsheet::Simple::Sheet ])

Convenience method to construct new L<Spreadsheet::Simple::Document> object.

=head1 BUGS

Please report any bugs or feature requests to C<bug-spreadsheet-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
