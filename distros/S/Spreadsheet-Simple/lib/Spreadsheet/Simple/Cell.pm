package Spreadsheet::Simple::Cell;
{
  $Spreadsheet::Simple::Cell::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Cell::AUTHORITY = 'cpan:DHARDISON';
}
# ABSTRACT: a spreadsheet cell with a text value and an optional color

use Moose;
use namespace::autoclean;

use MooseX::Types -declare => [qw( RGB )];
use MooseX::Types::Moose qw( Maybe Str Int );
use MooseX::Types::Structured 'Tuple';

subtype RGB, as Tuple[Int, Int, Int];

has 'value' => (
    is       => 'rw',
    isa      => Maybe[Str],
    required => 1,
);

has 'color' => (
    is  => 'ro',
    isa => Maybe [RGB],
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Cell - a spreadsheet cell with a text value and an optional color

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
