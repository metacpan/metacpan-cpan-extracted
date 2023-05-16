package RPM::Query::Package;
use strict;
use warnings;
use base qw{Package::New};

our $VERSION = '0.01';

=head1 NAME

RPM::Query - Perl object overlay of an RPM package

=head1 SYNOPSIS

  use RPM::Query::Package;
  my $package      = RPM::Query::Package->new(package_name=>'perl-5.16.3-299.el7_9.x86_64');
  my $name         = $rpm->name;         #is short name e.g. "perl"
  my $capabilities = $rpm->requires;     #isa list of RPM::Query::Capability
  foreach my $capability (@$capabilities) {
    printf "%s - %s\n", $capability->name, $capability->package->package_name;
  }

=head1 DESCRIPTION

=head1 METHODS

=head2 package_name

Returns the the long package name which is the unique package token that rpm uses for this package.

=cut

sub package_name {
  my $self                = shift;
  $self->{'package_name'} = shift if @_;
  die("Error: package_name property required") unless $self->{'package_name'};
  return $self->{'package_name'};
}

=head2 requires

Returns a list of L<RPM::Query::Capability> objects that the package requires

=cut

sub requires {
  my $self            = shift;
  $self->{'requires'} = $self->parent->requires($self->package_name) unless $self->{'requires'};
  return $self->{'requires'};
}

=head2 provides

Returns a list of L<RPM::Query::Capability> objects that the package provides

=cut

sub provides {
  my $self            = shift;
  $self->{'provides'} = $self->parent->provides($self->package_name) unless $self->{'provides'};
  return $self->{'provides'};
}

=head2 verify

Returns a Boolean value on whether or not the installed RPM passes the verify command. 

=cut

sub verify {
  my $self          = shift;
  $self->{'verify'} = $self->parent->verify($self->package_name) unless $self->{'verify'};
  return $self->{'verify'};
}

=head2 details

Returns select rpm tags as a hash reference where the key is a lower case tag. 

Note: Not all tags are supported.

=cut

sub details {
  my $self           = shift;
  $self->{'details'} = $self->parent->details($self->package_name) unless $self->{'details'};
  return $self->{'details'};
}

=head2 name

Returns the short package name

=cut

sub name {shift->details->{'name'}};

=head2 description

Returns the package description (multiline)

=cut

sub description {shift->details->{'description'}};

=head2 summary

=cut

sub summary {shift->details->{'summary'}};

=head2 url

=cut

sub url {shift->details->{'url'}};

=head2 version

=cut

sub version {shift->details->{'version'}};

=head2 sourcerpm

=cut

sub sourcerpm {shift->details->{'sourcerpm'}};

=head2 license

=cut

sub license {shift->details->{'license'}};

=head2 sigmd5

=cut

sub sigmd5 {shift->details->{'sigmd5'}};

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
