
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::RunStats::Finished' => {
    qw(time    $
       timestr $),
    '&as_xml' => q!qq(<finished time="$self->{time}" ) .
                   qq(timestr="$self->{timestr}"/>)!
};

1;

=pod

=head1 DESCRIPTION

This class represents Nmap scan time finishing information

=head1 PROPERTIES

=head2 time() - when scan finished, in seconds since the epoch

=head2 timestr() - ctime representation of finish time

=cut
