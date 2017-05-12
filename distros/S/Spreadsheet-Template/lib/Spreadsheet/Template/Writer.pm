package Spreadsheet::Template::Writer;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Writer::VERSION = '0.05';
use Moose::Role;
# ABSTRACT: role for classes which write spreadsheet files from a template

requires 'write';



no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template::Writer - role for classes which write spreadsheet files from a template

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  package MyWriter;
  use Moose;

  with 'Spreadsheet::Template::Writer';

  sub write {
      # ...
  }

=head1 DESCRIPTION

This role should be consumed by any class which will be used as the
C<writer_class> in a L<Spreadsheet::Template> instance.

=head1 METHODS

=head2 write($data)

This method is required to be implemented by any classes which consume this
role. It should use the data in C<$data> (in the format described in
L<Spreadsheet::Template>) to create a new spreadsheet file containing that
data. It should return a string containing the binary contents of the
spreadsheet file.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
