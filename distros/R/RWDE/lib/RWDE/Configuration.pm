package RWDE::Configuration;

use strict;

use YAML qw(LoadFile);

use RWDE::Configuration_content;

use base qw(RWDE::Singleton);

our $unique_instance;
our (@fieldnames, %fields, %static_fields, %modifiable_fields, @static_fieldnames, @modifiable_fieldnames);

use vars qw($AUTOLOAD);
use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::Configuration

=cut

=head2 get_instance()

Get an instance of the Configuration sans content. You will need an initialized Configuration
in order to read the values in your project.conf file.

#TODO Move this method to RWDE::Singleton

=cut

sub get_instance {
  my ($self, $params) = @_;

  if (ref $unique_instance ne $self) {
    $unique_instance = $self->new($params);
  }

  return $unique_instance;
}

=head2 initialize()

Load the content from within the project configuration file via Configuration_content

=cut

sub initialize {
  my ($self, $params) = @_;

  my $configuration_content = RWDE::Configuration_content->new($params);

  $self->{_configuration_content} = $configuration_content;

  return ();
}

=head2 get_SMTP()

Get an SMTP host - a random host is selected if the configuration specifies
a mail cluster

=cut

sub get_SMTP {
  my ($self, $params) = @_;

  my $array_ref = $self->SMTPhost;

  return $$array_ref[ rand @{$array_ref} ];
}

=head2 get_SMTP()

Get a string representing the absolute path of the project

=cut

sub get_root {
  my ($self, $params) = @_;

  return '/web/' . lc(RWDE::Configuration->ServiceName);
}

=head2 AUTOLOAD()

Catch configuration calls, so we can proxy them to the content provider

=cut

sub AUTOLOAD {
  my ($self, @args) = @_;

  return $self->FIELDNAME($AUTOLOAD, @args);
}

=head2 FIELDNAME()

This is a wrapper function for Configuration content so that the calls can look like they are static
due to this object being a singleton, there's no multiple configuration loaded

=cut

sub FIELDNAME {
  my $self = shift;
  my $fn   = shift;

  $fn =~ s/.*://;    # strip fully-qualified portion

  my $instance = ref $self ? $self : $self->get_instance();
  my $configuration_content = $instance->{_configuration_content};

  return $configuration_content->$fn;
}

1;
