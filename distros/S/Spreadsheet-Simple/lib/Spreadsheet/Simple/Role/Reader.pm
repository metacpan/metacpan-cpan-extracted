package Spreadsheet::Simple::Role::Reader;
{
  $Spreadsheet::Simple::Role::Reader::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Role::Reader::AUTHORITY = 'cpan:DHARDISON';
}
# ABSTRACT: For classes that can read in spreadsheets and return documents.
use Moose::Role;
use namespace::autoclean;


requires 'read_file';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Role::Reader - For classes that can read in spreadsheets and return documents.

=nethod read_file($file)

Returns a L<Spreadsheet::Simple::Document> objevt.

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
