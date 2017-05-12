package Net::OperaLink::Datatype;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, $id) = @_;

	$class = ref $class || $class;

    if (not defined $id or not $id) {
	    Carp::croak "Missing '$_'. Can't instance $class\n";
	}

    my $self = {
        _id => $id,
        _loaded => 0,
    };

	bless $self, $class;
	return $self;
}

sub datatype_url_root {
    my ($self) = @_;
    my $class = ref $self || $self;

    my @namespace = split '::', $class;
    $class = lc pop @namespace;

    return $class;
}

sub api_url_for {
    my ($self, $type) = @_;

    my $dt_url = $self->datatype_url_root();
    my $url;

    if (not defined $type) {
        return;
    }

    if ($type eq 'children' or $type eq 'descendants') {
        $url = "$dt_url/$type";
    }
    else {
        my $id = $type;
        $url = "$dt_url/$id";
    }

    return $url;
}

sub get {
    my ($self, @args) = @_;
    my $api_url = $self->url_for(@args);

    if (not $api_url) {
        Carp::croak("Don't know where to get this resource (@args)");
    }

}

1;

