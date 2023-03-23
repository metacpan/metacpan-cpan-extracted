package Power::Outlet::Config;
use strict;
use warnings;
use base qw{Package::New Package::Role::ini};
use Power::Outlet;

our $VERSION = '0.50';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Power::Outlet::Config - Control and query a Power::Outlet device from Configuration file

=head1 SYNOPSIS

  my $outlet = Power::Outlet::Config->new(section=>"My Section");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::Config is a package for controlling and querying Power::Outlet devices registered in an INI file.

=head1 USAGE

Configuration

  /etc/power-outliet.ini
  [My Tasmota]
  type=Tasmota
  host=light-hostname
  relay=POWER

  [My SonoffDiy]
  type=SonoffDiy
  host=switch=hostname

Script

  use Power::Outlet::Config;
  my $outlet = Power::Outlet::Config->new(section=>"My Section");
  print $outlet->on, "\n";

Command Line

  /usr/bin/power-outlet Config ON section "My Tasmota"
  /usr/bin/power-outlet Config ON section "My Section" ini_file ./my.ini

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"Config", section=>"My Section");
  my $outlet = Power::Outlet::Config->new(section=>"My Section");

=cut

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_); #isa Power::Outlet::Config
  die(sprintf(qq{Error: Package: $PACKAGE: Cannot Read Config File "%s".\n}, $self->ini_file)) unless -r $self->ini_file;
  my $hash  = $self->hash;            #isa HASH
  return Power::Outlet->new(%$hash);  #isa Power::Outlet::XXX
}

=head1 PROPERTIES

=head2 section

=cut

sub section {
  my $self           = shift;
  $self->{'section'} = shift if @_;
  die(qq{Error: Package: $PACKAGE: Object property "section" required.\n})
    unless $self->{'section'};
  die(sprintf(qq{Error: Package: $PACKAGE: Section "%s" does not exist in file "%s". Expected one of %s.\n}, $self->{'section'}, $self->ini_file, join(", ", map {qq{"$_"}} $self->ini->Sections)))
    unless $self->ini->SectionExists($self->{'section'});
  return $self->{'section'};
}

=head2 hash

=cut

sub hash {
  my $self       = shift;
  my %hash       = ();
  my $section    = $self->section;
  my @parameters = $self->ini->Parameters($section);
  foreach my $parameter (@parameters) {
    my $value         = $self->ini->val($section, $parameter, '');
    $hash{$parameter} = $value;
  }
  return \%hash;
}

=head1 OBJECT ACCESSORS

=head2 ini

Returns a L<Config::IniFiles> for the power-outlet.ini file.

=head2 ini_file

Default: /etc/power-outlet.ini or C:\Windows\power-outlet.ini

=cut

=head2 ini_file_default

Default: power-outlet.ini

=cut

sub ini_file_default {"power-outlet.ini"};

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
