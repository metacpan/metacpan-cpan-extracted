package Protocol::PostgreSQL::FieldDescription;
BEGIN {
  $Protocol::PostgreSQL::FieldDescription::VERSION = '0.008';
}
use strict;
use warnings;

=head1 NAME

Protocol::PostgreSQL::FieldDescription - field definitions

=head1 VERSION

version 0.008

=head1 SYNOPSIS

=head1 DESCRIPTION

Each field has the following definitions:

=over 4

=item * name

=item * table_id - object ID for the table

=item * field_id - attribute number of the column

=item * data_type - object ID for the data type

=item * data_size - length of the data type, can be negative for variable

=item * type_modifier

=item * format_code - text is zero, binary is one

=back

=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless { }, $class;
	$self->{$_} = $args{$_} for keys %args;
	return $self;
}

sub name { shift->{name} }

sub table_id { shift->{table_id} }

sub field_id { shift->{field_id} }

sub data_type { shift->{data_type} }

sub data_size { shift->{data_size} }

sub type_modifier { shift->{type_modifier} }

sub format_code { shift->{format_code} }

sub parse_data {
	my $self = shift;
	my ($data, $size) = @_;
	my ($content) = unpack("A$size", $data);
	return $content;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2011. Licensed under the same terms as Perl itself.
