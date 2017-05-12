
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::Class' => {
    qw(vendor   $
       osgen    $
       type     $
       osfamily $
       accuracy $),
    '&as_xml' => q!

    return  qq(<osclass type="$self->{type}" vendor="$self->{vendor}" ) .
            qq(osfamily="$self->{osfamily}" osgen="$self->{osgen}" ) .
            qq(accuracy="$self->{accuracy}"/>);

    !
};

1;

=pod

=head1 NAME 

OS Class - Operating system class

This object encapsulates an nmap operating system
guess.

=head2 vendor()

Operating system vendor

=head2 osgen()

Operating system generation

=head2 type()

Operating system generation

=head2 osfamily()

Operating system family

=head2 accuracy()

How accurate does nmap think this match is?

=cut

