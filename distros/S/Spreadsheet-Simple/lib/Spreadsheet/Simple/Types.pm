package Spreadsheet::Simple::Types;
{
  $Spreadsheet::Simple::Types::VERSION = '1.0.0';
}
BEGIN {
  $Spreadsheet::Simple::Types::AUTHORITY = 'cpan:DHARDISON';
}
# ABSTRACT: Types and coercions for working with the Spreadsheet::Simple object model
use strict;
use warnings;

use MooseX::Types -declare => [qw( Cells Rows Sheets )];
use MooseX::Types::Moose 'HashRef', 'ArrayRef', 'Str', 'Maybe';

class_type 'Spreadsheet::Simple::Cell';
class_type 'Spreadsheet::Simple::Row';
class_type 'Spreadsheet::Simple::Sheet';

subtype Cells,  as ArrayRef[Maybe['Spreadsheet::Simple::Cell']];
subtype Rows,   as ArrayRef[Maybe['Spreadsheet::Simple::Row']];
subtype Sheets, as ArrayRef[Maybe['Spreadsheet::Simple::Sheet']];

coerce Cells,
	from ArrayRef[Str],
	via { 
		Class::MOP::load_class('Spreadsheet::Simple::Cell');
		return [ 
			map {
				Spreadsheet::Simple::Cell->new(value => $_) 
			} @$_ 
		] 
	};

coerce Rows,
	from ArrayRef[ArrayRef[Str]],
	via {
		Class::MOP::load_class('Spreadsheet::Simple::Row');
		return [
			map {
				Spreadsheet::Simple::Row->new( cells => to_Cells($_) )
			} @$_
		]
	};

coerce Sheets,
	from HashRef[ArrayRef[ArrayRef[Str]]],
	via {
		Class::MOP::load_class('Spreadsheet::Simple::Sheet');
		my @result;

		foreach my $k (keys %$_) {
			push @result, Spreadsheet::Simple::Sheet->new(
				name => $k,
				rows => to_Rows($_->{$k}),
			);
		}

		return \@result;
	};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Spreadsheet::Simple::Types - Types and coercions for working with the Spreadsheet::Simple object model

=head1 AUTHOR

Dylan William Hardison

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
