# $Id: References.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::References.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::References -- routines to follow references
# (any ideas for a better name?)

package Syndication::NewsML::References;
use Carp;

# find reference (based on NewsML Toolkit Java version)
# get referenced data from within this document or possibly an external URL.
# parameter useExternal, if true, means we can look outside this document if necessary.
sub findReference {
    my ($node, $reference, $useExternal) = @_;
    # if reference starts with # it's in the local document (or should be)
    if ($reference =~ /^#/) {
        return $node->getElementByDuid(substr($reference, 1));
    } elsif ($useExternal) {
        # use LWP module to get the external document
        use LWP::UserAgent;
        my $ua = new LWP::UserAgent;
        $ua->agent("Syndication::NewsML/0.09" . $ua->agent);
        my $req = new HTTP::Request GET => substr($reference, 1);
        my $response = $ua->request($req);
        if ($response->is_success) {
            return $response->content;
        }
    }
    # document is external but we're not allowed to go outside
    # or an error occured with the retrieval
    # maybe should flag error better than this??
    return undef;
}

1;
