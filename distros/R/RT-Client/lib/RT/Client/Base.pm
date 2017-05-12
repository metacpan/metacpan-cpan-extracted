package RT::Client::Base;

use strict;
use warnings;
use Spiffy '-Base';

field 'uri';
field 'doc';
field 'client';

field members => {};
field actions => {};
field prototypes => {};

*XXX = *Spiffy::XXX;

sub status { $self->client->status(@_) }
sub errstr { $self->client->errstr(@_) }

sub new {
    my %args = @_;

    no strict 'refs';
    my $method = "${$self.'::ISA'}[-1]::new";

    my $rv = $args{Stream} ? $self->$method(%args) : {};
    bless($rv, $self);

    $rv->uri($args{URI}) or die 'Missing URI';
    $rv->client($args{Client}) or die 'Missing Client';

    return $rv;
}

sub init {
    no strict 'refs';
    my $method = "${ref($self).'::ISA'}[-1]::init";

    $self->$method(@_);
    return if $self->{init}++;

    $self->_init_links;
    $self->_init_entries;
    return $self;
}

sub _init_links {
    foreach my $link ($self->link) {
	my $rel = $link->rel;
	my ($member, $action) = split(/!/, $link->title, 2);
	next if $member =~ /^_/;

	if ($member) {
	    next;
	    XXX("member link not handled");
	}

	$action ||= $self->_rel_map->{$rel} or die "rel not handled: $rel";
	$self->actions->{$action} = $link->href;
    }
}

sub _action {
    $self->actions->{$_[0]} or die "Cannot find '$_[0]' URI for $self";
}

1;
