package Spreadsheet::Simple::Role::Writer;
{
  $Spreadsheet::Simple::Role::Writer::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Role::Writer::AUTHORITY = 'cpan:DHARDISON';
}
use Moose::Role;
use namespace::autoclean;


requires 'write_file';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Role::Writer

=head1 METHODS

=head2 write_file($file, $document)

Writes out a L<Spreadsheet::Simple::Document> $document object to $file.

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
