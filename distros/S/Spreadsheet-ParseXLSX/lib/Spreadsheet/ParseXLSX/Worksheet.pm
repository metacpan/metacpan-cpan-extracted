package Spreadsheet::ParseXLSX::Worksheet;

use strict;
use warnings;
use Scalar::Util ();

our $VERSION = '0.35'; # VERSION

# ABSTRACT: wrapper class around L<Spreadsheet::ParseExcel::Worksheet>


use Spreadsheet::ParseXLSX ();
use base 'Spreadsheet::ParseExcel::Worksheet';

# The object registry allows Cell objects to refer to Worksheets without
# the overhead of a weakened reference, which can add up over millions
# of cells.
our %_registry;


sub new {
  my $self = shift->SUPER::new(@_);

  Scalar::Util::weaken($_registry{Scalar::Util::refaddr($self)} = $self);

  return $self;
}


sub DESTROY {
  delete $_registry{Scalar::Util::refaddr($_[0])};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::ParseXLSX::Worksheet - wrapper class around L<Spreadsheet::ParseExcel::Worksheet>

=head1 VERSION

version 0.35

=head1 DESCRIPTION

This is a simple subclass of L<Spreadsheet::ParseExcel::Worksheet> which does
not expose any new public behavior.  See the parent class for API details.

=head1 METHODS

=head2 new()

creates a new worksheet and adds it to the registry

=head2 DESTROY()

removes the object from the registry while destroying it

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
