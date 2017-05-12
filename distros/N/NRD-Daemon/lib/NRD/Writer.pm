package NRD::Writer;

# Base class for components that write results to Nagios
#

use strict;
use warnings;

sub instance_of {
  my (undef, $type, @args) = @_;
  my $class = 'NRD::Writer::' . lc($type);
  {
   my $file = $class;
   $file =~ s/\:\:/\//g;
   require "$file.pm";
  }
  use Module::Load;
  load $class;
  #$class::import;

  return $class->new(@args);
}

#################### main pod documentation begin ###################

=head1 NAME

NRD::Writer - Write results into Nagios

=head1 DESCRIPTION

Project Home Page: http://code.google.com/p/nrd/

=head1 METHODS

=head2 instance_of($type, @args)

Returns an instance of an NRD::Writer::$type class. @args is passed to the constructor of the writer

=cut


1;
