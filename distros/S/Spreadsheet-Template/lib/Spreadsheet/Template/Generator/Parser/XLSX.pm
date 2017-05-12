package Spreadsheet::Template::Generator::Parser::XLSX;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Generator::Parser::XLSX::VERSION = '0.05';
use Moose;
# ABSTRACT: parser for XLSX files

use Spreadsheet::ParseXLSX;

with 'Spreadsheet::Template::Generator::Parser::Excel';


sub _create_workbook {
    my $self = shift;
    my ($filename) = @_;

    my $parser = Spreadsheet::ParseXLSX->new($filename);
    return $parser->parse($filename);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template::Generator::Parser::XLSX - parser for XLSX files

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  my $generator = Spreadsheet::Template::Generator->new(
      parser_class => 'Spreadsheet::Template::Generator::Parser',
  );

=head1 DESCRIPTION

This is an implementation of L<Spreadsheet::Template::Generator::Parser> for
XLSX files. It uses L<Spreadsheet::ParseXLSX> to do the parsing.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
