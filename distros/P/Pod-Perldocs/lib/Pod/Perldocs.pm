package Pod::Perldocs;
use strict;
use warnings;
require Pod::Perldoc;
use LWP::UserAgent;
use base qw(Pod::Perldoc);
our ($VERSION);
$VERSION = '0.17';

################################################################
# Change the following to reflect your setup
my $soap_uri = 'http://theoryx5.uwinnipeg.ca/Apache/DocServer';
my $soap_proxy = 'http://theoryx5.uwinnipeg.ca/cgi-bin/docserver.cgi';
my $pod_server = q{http://cpan.uwinnipeg.ca/cgi-bin/podserver.cgi};
###############################################################

sub grand_search_init {
  my($self, $pages, @found) = @_;
  @found = $self->SUPER::grand_search_init($pages, @found);
  return @found if @found;
  print STDERR "Searching on remote pod server ...\n";
  my $filename;
  if ($filename = get_lwp($self, $pages->[0])) {
    push @found, $filename;
    return @found;
  }
  elsif ($filename = get_soap($self, $pages->[0])) {
    push @found, $filename;
    return @found;
  }
  else {
    return @found;
  }
}

sub get_lwp {
  my ($self, $mod) = @_;
  my $ua = LWP::UserAgent->new;
  $ua->agent("Pod/Perldocs 0.16 ");
  push @{ $ua->requests_redirectable }, 'POST';
  # Create a request
  my $req = HTTP::Request->new(POST => $pod_server);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content("mod=$mod");
  # Pass request to the user agent and get a response back
  my $res = $ua->request($req);
  # Check the outcome of the response
  if ($res->is_success) {
    my ($fh, $filename) = $self->new_tempfile();
    print $fh $res->content;
    return $filename;
  }
  else {
    print STDERR "Remote server returned status code: " . $res->status_line . "\n";
    return;
  }
}

sub get_soap {
  my ($self, $mod) = @_;
  my $soap = make_soap() or return; # no SOAP::Lite available
  my $result = $soap->get_doc($mod);
  defined $result && defined $result->result or do {
    print STDERR "No matches found there either.\n";
    return;
  };
  my $lines = $result->result();
  unless ($lines and ref($lines) eq 'ARRAY') {
    print STDERR "Documentation not found there either.\n";
    return;
  }
  my ($fh, $filename) = $self->new_tempfile();
  print $fh @$lines;
  return $filename;
}

sub make_soap {
  unless (eval { require SOAP::Lite }) {
    print STDERR "SOAP::Lite is unavailable to make remote call\n";
    return undef;
  }

  return SOAP::Lite
    ->uri($soap_uri)
      ->proxy($soap_proxy,
	      options => {compress_threshold => 10000})
	->on_fault(sub { my($soap, $res) = @_; 
			 print STDERR "SOAP Fault: ", 
                           (ref $res ? $res->faultstring 
                                     : $soap->transport->status),
                           "\n";
                         return undef;
		       });
}

1;

=head1 NAME

Pod::Perldocs - view remote pod via Pod::Perldoc

=head1 DESCRIPTION

This is a drop-in replacement for C<perldoc> based on
C<Pod::Perldoc>. Usage is the same, except in the case
when documentation for a module cannot be found on the
local machine, in which case a query (via LWP or SOAP::Lite) will
be made to a remote pod repository and, if the documentation is
found there, the results will be displayed as usual.

=head1 NOTE

The values of C<$pod_server>, C<$soap_uri> and
C<$soap_proxy> at the top of this script reflect
the location of the remote pod repository.

=head1 SERVER

See the I<CPAN-Search-Lite> project on SourceForge at
L<http://sourceforge.net/projects/cpan-search/>
for the software needed to set up a remote pod
repository used by C<perldocs>.

=head1 SEE ALSO

L<Pod::Perldoc>.

=head1 COPYRIGHT

This software is copyright 2004,2009 by Randy Kobes
E<lt>r.kobes@uwinnipeg.caE<gt>. Usage and redistribution
is under the same terms as Perl itself.

=head1 CURRENT MAINTAINER

Kenichi Ishigaki E<lt>ishigaki@cpan.orgE<gt>

=cut
