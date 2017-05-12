package NRD::Serialize;

use strict;
use warnings;

sub from_line {
  my ($self, $line) = @_;
  my $r = {};
  my @parts = split /\t/, $line;

  if (scalar(@parts) == 3){
    ($r->{'host_name'}, $r->{'return_code'}, $r->{'plugin_output'}) = @parts;
  } elsif(scalar(@parts) == 4) {
    ($r->{'host_name'}, $r->{'svc_description'}, $r->{'return_code'}, $r->{'plugin_output'}) = @parts;
  } else {
    die "Input in incorrect format. Format hostname<TAB>[svc_description<TAB>]return_code<TAB>plugin_output<NEWLINE>";
  }
  return $r;
}

sub instance_of {
  my (undef, $type, @args) = @_;
  my $class = 'NRD::Serialize::' . lc($type);
  {
   my $file = $class;
   $file =~ s/\:\:/\//g;
   require "$file.pm";
  }

  return $class->new(@args);
}

#################### main pod documentation begin ###################

=head1 NAME

NRD::Serialize - Serialize perl datastructures to get transmitted over the net

=head1 DESCRIPTION

Project Home Page: http://code.google.com/p/nrd/

=head1 METHODS

=head2 from_line($line)

Parses a line formatted in "hostname<TAB>[svc_description<TAB>]return_code<TAB>plugin_output<NEWLINE>" fasion
and returns a hashref

=head2 instance_of($type, @args)

Returns an instance of an NRD::Serialize::$type class. @args is passed to the constructor of the serializer

=cut

1;
