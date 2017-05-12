
use strict;
use Class::Generate qw(class);

class 'Nmap::Scanner::RunStats' => {
    qw(finished Nmap::Scanner::RunStats::Finished
       hosts    Nmap::Scanner::Hosts),
    '&as_xml' => q!

    my $xml = "<runstats>";
    $xml .= $self->{'finished'}->as_xml() if $self->{'finished'};
    $xml .= $self->{'hosts'}->as_xml() if $self->{'hosts'};
    $xml .= "</runstats>\n";

    return $xml;

    !
};

1;

=pod

=head1 DESCRIPTION

This class represents Nmap Summary/scan information.

=head1 PROPERTIES

=head2 finished() - Nmap::Scanner::RunStats::Finished

=head2 hosts()

=cut
