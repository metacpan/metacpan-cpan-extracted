
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::Hosts' => {
      'up'      => {qw(type $ default 0)},
      'down'    => {qw(type $ default 0)},
      'total'   => {qw(type $ default 0)},
      '&as_xml' => q!qq(<hosts up="$self->{up}" down="$self->{down}" ) .
                     qq(total="$self->{total}"/>);!
};

=pod

=head1 DESCRIPTION

This class represents a hosts summary object as represented by the scanning output from
nmap.

=head2 up()

number of hosts scanned that were reachable.

=head2 down()

number of hosts scanned that were not reachable.

=head2 total()

Total number of hosts scanned.

=cut

1;
