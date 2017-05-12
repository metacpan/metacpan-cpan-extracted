package Palm::Zetetic::Strip::System;

use strict;

use vars qw(@ISA $VERSION);

require Exporter;

@ISA = qw(Palm::Raw);
$VERSION = "1.02";

=head1 NAME

Palm::Zetetic::Strip::System - An immutable system object

=head1 SYNOPSIS

  use Palm::Zetetic::Strip;

  # Create and load a new Palm::Zetetic::Strip object

  @systems = $strip->get_systems()
  $id = $systems[0]->get_id();
  $name = $systems[0]->get_name();

=head1 DESCRIPTION

This is an immutable data object that represents a system.  A
Palm::Zetetic::Strip(3) object is a factory for system objects.

=head1 METHODS

=cut

sub new
{
    my $class = shift;
    my (%args) = @_;
    my $self = {};

    bless $self, $class;
    $self->{id}     = "";
    $self->{name}   = "";

    $self->{id}     = $args{id} if defined($args{id});
    $self->{name}   = $args{name} if defined($args{name});
    return $self;
}

=head2 get_id

  $id = $system->get_id();

Returns the ID of this system.

=cut

sub get_id
{
    my ($self) = @_;
    return $self->{id};
}

=head2 get_name

  $name = $system->get_name();

Returns the string name of this system;

=cut

sub get_name
{
    my ($self) = @_;
    return $self->{name};
}

1;

__END__

=head1 SEE ALSO

Palm::Zetetic::Strip(3)

=head1 AUTHOR

Dave Dribin
