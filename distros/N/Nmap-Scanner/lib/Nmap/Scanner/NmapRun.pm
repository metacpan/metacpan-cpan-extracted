use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::NmapRun' => {
    qw(
        scan_info   @Nmap::Scanner::ScanInfo
        task        @Nmap::Scanner::Task
        run_stats   Nmap::Scanner::RunStats
        scanner     $
        args        $
        start       $
        startstr    $
        version     $
        xmloutputversion $
        debugging   $
        verbose     $
    ),
    '&as_xml' => q!

    #  Passed in by Nmap::Scanner::Backend::Results
    my $hostlist = shift;

    my $xml = qq(<nmaprun scanner="$self->{scanner}" args="$self->{args}" ) .
              qq(start="$self->{start}" startstr="$self->{startstr}" ) .
              qq(version="$self->{version}" ) .
              qq(xmloutputversion="$self->{xmloutputversion}">\n);

    for my $si ($self->scan_info()) {
        $xml .= $si->as_xml();
    }

    for my $t ($self->task()) {
        $xml .= $t->as_xml();
    }

    $xml .= qq(<verbose level="$self->{verbose}"/>
<debugging level="$self->{debugging}"/>
$hostlist);

    $xml .= $self->{'run_stats'}->as_xml();

    $xml .= "</nmaprun>\n";

    return $xml;

    !
};

=pod

=head1 DESCRIPTION

This class represents Nmap Summary/scan information.

=head1 PROPERTIES

=head2 scan_info()

    Array of Nmap::Scanner::ScanInfo instances.

=head2 tasks()

    Array of Nmap::Scanner::Task instances.

=head2 run_stats()

=head2 scanner()

=head2 args()

Command line arguments used for this scan.

=head2 start()

Starting time for scan.

=head2 startstr()

Starting time for scan, ctime format

=head2 version()

Version of scanner used.

=head2 xmloutputversion()

=head2 verbose()

=head2 debugging()

=cut

1;
