package RPM::Query::Capability;
use strict;
use warnings;
use base qw{Package::New};

our $VERSION = '0.01';

=head1 NAME

RPM::Query - Perl object overlay of an RPM capability

=head1 SYNOPSIS

  use RPM::Query;
  my $rpm          = RPM::Query->new;
  my $capabilities = $rpm->requires('perl'); #isa ARRAY of RPM::Query::Capability
  foreach my $capability (@$capabilities) {
    printf "%s - %s\n", $capability->name, $capability->package->name;
  }

=head1 DESCRIPTION

=head1 METHODS

=head2 capability_name

Returns the capability name with optional version as returns by the rpm command.

  perl(Scalar::Util) >= 1.10
  perl(strict)

=cut

sub capability_name {
  my $self                   = shift;
  $self->{'capability_name'} = shift if @_;
  die("Error: capability_name property required") unless $self->{'capability_name'};
  return $self->{'capability_name'};
}

sub _capability_name {
  my $self = shift;
  unless (defined $self->{'_capability_name'}) {
    my $hash = {};
    if ($self->capability_name =~ m/\A(.*)\s+(>=|<=|=)\s+(.*)\Z/) {
      $hash->{'name'}    = $1;
      $hash->{'compare'} = $2;
      $hash->{'version'} = $3;
    } else {
      $hash->{'name'}    = $self->capability_name;
      $hash->{'version'} = '';
      $hash->{'compare'} = undef;
    }
    $self->{'_capability_name'} = $hash;
  }
  return $self->{'_capability_name'};
}

=head2 name

=cut

sub name {shift->_capability_name->{'name'}};

=head2 version

=cut

sub version {shift->_capability_name->{'version'}};

=head2 package

Returns the first package (alphabetically) that provides this capability

=cut

sub package {shift->whatprovides->[0]};

=head2 whatprovides

Returns a list of package objects that provides this capability.

=cut

sub whatprovides {
  my $self = shift;
  unless ($self->{'whatprovides'}) {
    $self->{'whatprovides'} = $self->parent->whatprovides($self->name) or die("Error: package not found");
  }
  return $self->{'whatprovides'};
}

=head1 ACCESSORS

=head2 parent

=cut

sub parent {
  my $self          = shift;
  $self->{'parent'} = shift if @_;
  $self->{'parent'} = RPM::Query->new unless $self->{'parent'};
  return $self->{'parent'};
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis

=cut

1;
