package Table::Simple::Output::Theory;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp qw(carp);

extends 'Table::Simple::Output';

=head1 NAME

Table::Simple::Output::Theory - Use the "theory" table format to output table data.

=head1 DESCRIPTION

Theory is named after David "theory" Wheeler who provided a table format
for the "Markdown" wiki text format (which just happens to match the 
standard output for PostgreSQL queries.)

It also provides a nice example of how to subclass L<Table::Simple::Output> 
to control or change how data is output.

Most of the magic to make this work is embedded inside of L<Moose>.

=head2 ATTRIBUTES

The following attributes from L<Table::Simple::Output> have been overriden
in this subclass:

=over 4

=item column_marker

The default is "|"

=back

=cut

has '+column_marker' => (
	default => '|',
);

=over 4

=item horizontal_rule

The default is "-"

=back

=cut

has '+horizontal_rule' => (
	default => '-',
);

=over 4

=item padding

The default is 2.

=back

=cut

has '+padding' => (
	default => 2,
);

=head1 LICENSE

Copyright (C) 2010 Mark Allen

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>

=head1 SEE ALSO

L<Moose>, L<Markdent>, L<Table::Simple>, L<Table::Simple::Output>

=cut

__PACKAGE__->meta->make_immutable();
1;
