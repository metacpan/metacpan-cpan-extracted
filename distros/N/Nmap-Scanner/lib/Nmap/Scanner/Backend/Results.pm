package Nmap::Scanner::Backend::Results;

=pod

=head1 DESCRIPTION

This class holds the results from a 
scan.  Results include a host
list (Nmap::Scanner::HostList) instance
and an instance of Nmap::Scanner::NmapRun,
which contains information about the
scan.  There are several methods in this 
class used by the scanner to populate the 
result set; the only three that will be of
interest to most programmers are:

=head2 get_host_list()

Returns an instance of 
Nmap::Scanner::HostList that can 
be iterated through to get the host 
objects found by the search.

Example (Assumes scanner 
instance is named $scanner):

my $results = $scanner->scan();

my $host_list = $results->get_host_list();

while (my $host = $host_list->get_next()) {

    print "Found host named: " . $host->hostname() . "\n";
    .. etc ..

}

=head2 as_xml()

Returns the results as a well-formed 
XML document.

Example (Assumes scanner instance 
is named $scanner):

my $results = $scanner->scan();

print $results->as_xml();

=head2 nmap_run()

Returns the Nmap::Scanner::NmapRun
instance with information about the
scan itself.

See the examples/ directory in the
distribution for more examples.

=cut

use Nmap::Scanner::Host;
use Nmap::Scanner::HostList;
use Nmap::Scanner::Port;
use Nmap::Scanner::NmapRun;
use File::Spec;

use strict;

sub new {
    my $class = shift;
    my $you = {};
    return bless $you, $class;
}

sub debug {
    $_[0]->{'DEBUG'} = $_[1];
}

sub nmap_run {
    my $self = shift;
    @_ ? $self->{NMAP_RUN} = shift
       : return $self->{NMAP_RUN};
}

sub add_host {
    $_[0]->{ALLHOSTS}->{($_[1]->addresses())[0]} = $_[1];
}

sub get_host {
    return $_[0]->{ALLHOSTS}->{$_[1]};
}

sub get_all_hosts {
    return $_[0]->{ALLHOSTS};
}

sub get_host_list {
    return new Nmap::Scanner::HostList($_[0]->{ALLHOSTS});
}

sub as_xml {

    my $self = shift;

    my $tmp = $self->get_host_list()->as_xml();

    my $xml = "<?xml version=\"1.0\"?>\n";
    $xml   .= $self->nmap_run()->as_xml($tmp);

    return $xml;

}

1;
