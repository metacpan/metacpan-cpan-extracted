
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS::Match' => {
    qw(name     $
       accuracy $),
    '&as_xml' => q!my $osname = HTML::Entities::encode_entities($self->{name});
                   qq(<osmatch name="$osname" ) .
                   qq(accuracy="$self->{accuracy}"/>);!
},
'-use' => 'HTML::Entities';

1;

=pod

=head1 NAME 

OS Match - Operating system match

This object encapsulates an nmap operating system
guess.

=head2 name()

Operating system name

=head2 accuracy()

How accurate does nmap think this match is?

=cut
