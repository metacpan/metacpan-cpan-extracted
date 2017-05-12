package RWDE::Configuration_content;

use strict;

use Error qw(:try);
use YAML qw(LoadFile);

use RWDE::Exceptions;

use base qw(RWDE::RObject);

our (@fieldnames, %fields, %static_fields, %modifiable_fields, @static_fieldnames, @modifiable_fieldnames);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 561 $ =~ /(\d+)/;

=pod

=head1 RWDE::Configuration_content

=cut

=head2 initialize()

Create a RWDE object and populate it with the project configuration content.

=cut

sub initialize {
  my ($self, $params) = @_;

  # where the config file lives.

  if (not defined $$params{config_file}){
    throw RWDE::DevelException({ info => "Config file not specified for loading" });
  }

  my %conf = %{ LoadFile($$params{config_file}) };

  $self->{_data} = $conf{Service};

  foreach my $field (keys %{ $conf{Service} }) {
    $static_fields{$field} = [ 'char', 'Configuration parameter' ];
  }

  %modifiable_fields = ();

  %fields = (%static_fields, %modifiable_fields);

  @static_fieldnames     = sort keys %static_fields;
  @modifiable_fieldnames = sort keys %modifiable_fields;
  @fieldnames            = sort keys %fields;

  return ();
}

1;
