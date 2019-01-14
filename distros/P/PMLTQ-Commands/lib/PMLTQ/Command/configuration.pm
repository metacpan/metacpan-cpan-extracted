package PMLTQ::Command::configuration;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::configuration::VERSION = '2.0.1';
# ABSTRACT: GET current configuration

use PMLTQ::Base 'PMLTQ::Command';
use JSON;
use YAML::Tiny;
use Hash::Merge 'merge';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my $config = $self->config;
  print YAML::Tiny->new( $config)->write_string;
}

=head1 SYNOPSIS

  pmltq configuration

=head1 DESCRIPTION

Returns current configuration in yaml format (a merge of defaults, config file and command line options)

=head1 OPTIONS

=cut

1;
