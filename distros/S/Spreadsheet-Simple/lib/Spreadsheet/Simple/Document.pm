package Spreadsheet::Simple::Document;
{
  $Spreadsheet::Simple::Document::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Document::AUTHORITY = 'cpan:DHARDISON';
}
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose 'ArrayRef';
use Spreadsheet::Simple::Sheet;

has 'sheets' => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef ['Spreadsheet::Simple::Sheet'],
    lazy_build => 1,
    auto_deref => 1,
    handles    => {
        add_sheet   => 'push',
        get_sheet   => 'get',
        sheet_count => 'count',
    },
);

sub _build_sheets { return [] }

sub new_sheet {
	my ($self, @args) = @_;
	my $sheet = Spreadsheet::Simple::Sheet->new(@args);

	$self->add_sheet( $sheet );

	return $sheet;
}

sub get_sheet_by_name {
	my ($self, $name) = @_;
	my $lname = lc $name;

	foreach my $sheet ($self->sheets) {
		return $sheet if lc $sheet->name eq $lname;
	}

	return;
}

1; # End of Spreadsheet::Simple

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Document

=head1 SYNOPSIS

    use Spreadsheet::Simple::Document;

    my $s = Spreadsheet::Simple::Document->new;

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
