package Spreadsheet::Template::Generator::Parser;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Generator::Parser::VERSION = '0.05';
use Moose::Role;
# ABSTRACT: role for classes which parse an existing spreadsheet

requires 'parse';



no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template::Generator::Parser - role for classes which parse an existing spreadsheet

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  package MyParser;
  use Moose;

  with 'Spreadsheet::Template::Generator::Parser';

  sub parse {
      # ...
  }

=head1 DESCRIPTION

This role should be consumed by any class which will be used as the
C<parser_class> in a L<Spreadsheet::Template::Generator> instance.

=head1 METHODS

=head2 parse($filename) (required)

This method should parse the spreadsheet specified by C<$filename> and return
the intermediate data structure containing all of the data in that spreadsheet.
The intermediate data format is documented in L<Spreadsheet::Template>.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
