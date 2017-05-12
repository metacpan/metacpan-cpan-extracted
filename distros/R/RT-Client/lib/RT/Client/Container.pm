package RT::Client::Container;

use strict;
use warnings;
use XML::Simple ();
use XML::Atom::Feed;
use Spiffy '-Base';

our @ISA = qw(RT::Client::Base XML::Atom::Feed);

const _rel_map => {
    'service.post'    => 'add',
    'service.feed'    => 'search',
};

sub add {
    my $uri = $self->_action('add');
    my $res = $self->client->_request($uri, @_, method => 'POST') or return undef;

    $uri = $res->header('Location');
    return $self->client->describe($res->header('Location')) if $uri;

    return 1 if $res->is_success;

    my $ref = $res->content_ref; chomp $$ref;
    $self->errstr($$ref);

    return undef;
}

sub _init_entries {
    foreach my $entry ($self->entries) {
	if ($entry->id) {
	    $self->_init_entry($entry);
	}
	else {
	    $self->_init_entry_prototype($entry);
	}
    }
}

stub '_init_entry';

sub _init_entry_prototype {
    my $entry = shift;
    foreach (split(/(?!^)(?=<body )/, $entry->content->body)) {
	my $body = XML::Simple::XMLin($_);
	my $action = delete($body->{action}) or die "No action specified";
	$self->prototypes->{$action} = $body;
    }
}

1;
