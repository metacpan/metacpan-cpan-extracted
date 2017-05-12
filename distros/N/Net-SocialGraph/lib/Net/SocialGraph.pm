package Net::SocialGraph;

use strict;
use JSON::Any;
use LWP::Simple qw();
use URI;

our $VERSION = '1.1';

my $url = 'http://socialgraph.apis.google.com/lookup';

=head1 NAME

Net::SocialGraph - interact with Google's Social Graph API

=head1 SYNOPIS

    my $sg  = Net::SocialGraph->new(%options); # see below
    my $res = $sg->get(@urls);

=head1 DESCRIPTION

This is a paper thin wrapper round Google's Social Graph API. 

    http://code.google.com/apis/socialgraph/

You should read the docs there for more information about options
and the format of the response.

=head1 METHODS

=cut

=head2 new [opt[s]]

Create a new Social Graph object. 

Can optionally take, err, some options.

=over 4

=item edo (boolean)

Return edges out from returned nodes.

=item edi (boolean)

Return edges in to returned nodes.

=item fme (boolean)

Follow me links, also returning reachable nodes.

=item pretty (boolean)

Pretty-print returned JSON.

=item callback (string matching /^[\w\.]+$/)

JSONP callback function. 

You shouldn't ever have to use this but I put it in for completeness.
 
=item sgn (boolean)

Return internal representation of nodes.

=back

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    return bless \%opts, $class;
}

=head2 get <uri[s]>

Fetch the information about the nodes specified in the uris.

Returns a nested data structure representing the results. This 
will be in the form of a hashref. 

The key C<canonical_mapping> contains another hashref which maps 
each uri given to its canonical form.

The key C<nodes> contains a hashref with keys for each uri given. 
The contents of those hashrefs (do keep up) depend on the options
given.

You can read more information about node uris here

    http://code.google.com/apis/socialgraph/docs/api.html#query


=cut

sub get {
    my $self = shift;
    my @urls = @_;
    my $json = $self->get_json(@urls) || return undef;
    return JSON::Any->jsonToObj($json);

}

=head2 get_json <uri[s]>

The same as above but returns raw JSON.

=cut

sub get_json {
    my $self = shift;
    my @urls = @_;
    return undef unless @urls;
    my %opts = %$self;
    $opts{q} = join(",", @urls);

    my $uri = URI->new($url);
    $uri->query_form(%opts);

    return LWP::Simple::get("$uri");

}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2008, Simon Wistow

Distributed under the same terms as Perl itself.

=cut

1;
