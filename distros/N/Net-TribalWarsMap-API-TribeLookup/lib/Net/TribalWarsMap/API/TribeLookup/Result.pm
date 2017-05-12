use strict;
use warnings;

package Net::TribalWarsMap::API::TribeLookup::Result;
BEGIN {
  $Net::TribalWarsMap::API::TribeLookup::Result::AUTHORITY = 'cpan:KENTNL';
}
{
  $Net::TribalWarsMap::API::TribeLookup::Result::VERSION = '0.1.0';
}

# ABSTRACT: A single tribe search result


use Moo;


has 'id' => ( is => ro =>, required => 1 );


has 'members' => ( is => ro =>, required => 1 );


has 'name' => ( is => ro =>, required => 1 );


has 'oda' => ( is => ro =>, required => 1 );


has 'oda_rank' => ( is => ro =>, required => 1 );


has 'odd' => ( is => ro =>, required => 1 );


has 'odd_rank' => ( is => ro =>, required => 1 );


has 'points' => ( is => ro =>, required => 1 );


has 'rank' => ( is => ro =>, required => 1 );


has 'tag' => ( is => ro =>, required => 1 );


has 'total_points' => ( is => ro =>, required => 1 );


sub _field_names {
  return qw( id  total_points members tag points rank oda odd oda_rank odd_rank name );
}


sub from_data_line {
  my ( $self, @fields ) = @_;
  my (@names) = $self->_field_names;
  my $hash = {};
  for my $idx ( 0 .. $#names ) {
    my $key   = $names[$idx];
    my $value = $fields[$idx];
    next if $key =~ /\A[?]/msx;
    $hash->{$key} = $value;
  }
  return $self->new($hash);
}


sub od_ratio {
  my ($self) = @_;
  return sprintf '%0.3f', $self->oda / $self->odd;
}


sub od_point_ratio {
  my ($self) = @_;
  return sprintf '%0.3f', ( $self->oda + $self->odd ) / $self->points;
}


sub avg_od {
  my ($self) = @_;
  return sprintf '%0.3f', ( $self->oda + $self->odd ) / $self->members;
}


sub avg_oda {
  my ( $self, ) = @_;
  return sprintf '%0.3f', $self->oda / $self->members;

}


sub avg_odd {
  my ( $self, ) = @_;
  return sprintf '%0.3f', $self->odd / $self->members;
}


sub avg_points {
  my ($self) = @_;
  return sprintf '%0.3f', $self->points / $self->members;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::TribalWarsMap::API::TribeLookup::Result - A single tribe search result

=head1 VERSION

version 0.1.0

=head1 METHODS

=head2 C<id>

=head2 C<members>

=head2 C<name>

=head2 C<oda>

=head2 C<oda_rank>

=head2 C<odd>

=head2 C<odd_rank>

=head2 C<points>

=head2 C<rank>

=head2 C<tag>

=head2 C<total_points>

=head2 C<from_data_line>

Inflates a C<::Result> from a decoded list.

    my $instance = $class->from_data_line( $id , $total_points, ... );

B<Note:> Upstream have their data in the following form:

    {
        "$id": [ $total_points , ... ],
        "$id": [ $total_points , ... ],
    }

While this function takes:

          "$id", $total_points , ...

=head2 C<od_ratio>

=head2 C<od_point_ratio>

=head2 C<avg_od>

=head2 C<avg_oda>

=head2 C<avg_odd>

=head2 C<avg_points>

=head1 ATTRIBUTES

=head2 C<id>

=head2 C<members>

=head2 C<name>

=head2 C<oda>

=head2 C<oda_rank>

=head2 C<odd>

=head2 C<odd_rank>

=head2 C<points>

=head2 C<rank>

=head2 C<tag>

=head2 C<total_points>

=head1 PRIVATE METHODS

=head2 C<_field_names>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::TribalWarsMap::API::TribeLookup::Result",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
