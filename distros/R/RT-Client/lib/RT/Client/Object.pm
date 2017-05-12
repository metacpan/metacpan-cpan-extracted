package RT::Client::Object;

use strict;
use warnings;
use XML::Simple ();
use XML::Atom::Entry;
use Spiffy '-Base';

our @ISA = qw(RT::Client::Base XML::Atom::Entry);

const _rel_map => {
    'service.post'    => 'update',
};

sub update {
    my $uri = $self->_action('update');
    my $res = $self->client->_request($uri, @_, method => 'POST') or return undef;

    # XXX - parse the update result
    return $res->content;
}

1;
