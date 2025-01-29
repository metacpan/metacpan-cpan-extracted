#
# $Id: Onyphe.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package Onyphe;
use strict;
use warnings;

our $VERSION = '4.17';

use experimental qw(signatures);

use base qw(Class::Gomor::Array);

our @AS = qw(verbose config silent);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildIndices;

use Data::Dumper;
use File::Slurp qw(read_file);
use Config::INI::Tiny;

sub version ($self) {
   return "ONYPHE Version: $VERSION";
}

sub init ($self, $file = undef) {
   $file ||= $ENV{HOME}.'/.onyphe.ini';
   if (! -f $file) {
      print STDERR "ERROR: init file not found: $file\n";
      return;
   }

   my $read = read_file($file);
   my $config = Config::INI::Tiny->new->to_hash($read);
   $self->config($config);

   # Default values:
   $config->{''}{api_size} ||= 10;
   $config->{''}{api_maxpage} ||= 1;
   $config->{''}{api_trackquery} ||= 0;
   $config->{''}{api_calculated} ||= 0;
   $config->{''}{api_keepalive} ||= 0;
   $config->{''}{api_endpoint} ||= 'https://www.onyphe.io/api/v2';
   $config->{''}{api_ondemand_endpoint} ||= $config->{''}{api_endpoint};
   $config->{''}{api_asd_endpoint} ||= $config->{''}{api_endpoint};

   if ($self->verbose) {
      for my $k (keys %{$config->{''}}) {
         print STDERR "VERBOSE: config: $k => ".$config->{''}{$k}."\n";
      }
   }

   unless (defined($config->{''}{api_key})) {
      print STDERR "ERROR: config: needs at least api_url setting:\n";
      print STDERR "       api_key = 'XXX'\n";
      return;
   }

   return $self;
}

1;

__END__

=head1 NAME

Onyphe - ONYPHE base class

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
