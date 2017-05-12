package Spreadsheet::Template::Writer::XLSX;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Writer::XLSX::VERSION = '0.05';
use Moose;
# ABSTRACT: generate XLSX files from templates

with 'Spreadsheet::Template::Writer::Excel';

use Excel::Writer::XLSX;


sub excel_class { 'Excel::Writer::XLSX' }

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template::Writer::XLSX - generate XLSX files from templates

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  my $template = Spreadsheet::Template->new(
      writer_class => 'Spreadsheet::Template::Writer::XLSX',
  );

=head1 DESCRIPTION

This class implements L<Spreadsheet::Template::Writer>, allowing you to
generate XLSX files.

=for Pod::Coverage   excel_class

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
