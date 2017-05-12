package Protocol::PostgreSQL::RowDescription;
BEGIN {
  $Protocol::PostgreSQL::RowDescription::VERSION = '0.008';
}
use strict;
use warnings;

=head1 NAME

Protocol::PostgreSQL::RowDescription - row definitions

=head1 VERSION

version 0.008

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Protocol::PostgreSQL::FieldDescription;

=head1 METHODS

=cut

sub new { bless {}, shift }

=head2 field_count

Returns the current field count.

=cut

sub field_count { shift->{field_count} }

=head2 add_field

Add a new field to the list.

=cut

sub add_field {
	my $self = shift;
	my $field = shift;
	++$self->{field_count};
	push @{$self->{field}}, $field;
	return $self;
}

sub field_index {
	my $self = shift;
	my $idx = shift;
	return $self->{field}->[$idx];
}

1;

__END__

=head1 SEE ALSO

L<DBD::Pg>, which uses the official library and has had far more testing.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2011. Licensed under the same terms as Perl itself.
